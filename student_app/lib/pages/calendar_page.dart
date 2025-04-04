import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:student_app/pages/google_signin.dart';
import 'package:student_app/utils/google_calendar_service.dart';
import 'package:student_app/main.dart';
import 'package:student_app/user_singleton.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static List<Appointment>? _cachedAppointments;
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  CalendarView _calendarView = CalendarView.month;
  Timer? _refreshTimer;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadCalendarEvents();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _refreshCalendarEvents();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String formatDateTime(DateTime dt) {
    return DateFormat('MMMM d, y – h:mm a').format(dt);
  }

  Future<void> _loadCalendarEvents() async {
    if (_cachedAppointments != null) {
      setState(() {
        _appointments = _cachedAppointments!;
        _isLoading = false;
      });
      return;
    }
    await _refreshCalendarEvents();
    setState(() => _isLoading = false);
  }

  Future<void> _refreshCalendarEvents() async {
    final authService = AuthService();
    final accessToken = await authService.getAccessToken();
    if (accessToken == null) return;
    final calendarService = GoogleCalendarService();
    final googleEvents = await calendarService.fetchCalendarEvents(accessToken);
    List<Appointment> freshAppointments = [];
    for (var event in googleEvents) {
      final start = (event.start?.dateTime ?? event.start?.date)?.toLocal();
      final end = (event.end?.dateTime ?? event.end?.date)?.toLocal();
      final title = event.summary ?? "No Title";
      final location = event.location ?? "No Location";
      if (start != null && end != null) {
        freshAppointments.add(
          Appointment(
            startTime: start,
            endTime: end,
            subject: "$title\n$location",
            color: const Color(0xFF6B803D),
          ),
        );
      }
    }
    setState(() {
      _appointments = freshAppointments;
      _cachedAppointments = freshAppointments;
    });
  }

  List<Appointment> _getFilteredAppointments() {
    final now = DateTime.now();
    return _appointments.where((appt) {
      final start = appt.startTime;
      if (_selectedDate != null) {
        return start.year == _selectedDate!.year &&
            start.month == _selectedDate!.month &&
            start.day == _selectedDate!.day;
      }
      return start.isAfter(now) || start.day == now.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _findBestTimeAndCreateEvent(String title, List<String> attendees,
      DateTime preferredStart, DateTime preferredEnd) async {
    final authService = AuthService();
    final accessToken = await authService.getAccessToken();
    final timeMin = preferredStart.toUtc();
    final timeMax = timeMin.add(const Duration(days: 7));
    final url = Uri.parse("https://www.googleapis.com/calendar/v3/freeBusy");
    final response = await http.post(url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "timeMin": timeMin.toIso8601String(),
          "timeMax": timeMax.toIso8601String(),
          "timeZone": "UTC",
          "items": attendees.map((email) => {"id": email}).toList(),
        }));
    if (response.statusCode != 200) {
      _showSnack("Failed to fetch availability.");
      return;
    }
    final data = jsonDecode(response.body);
    final busyBlocks = <Map<String, DateTime>>[];
    for (var calendar in data['calendars'].values) {
      for (var period in calendar['busy']) {
        busyBlocks.add({
          'start': DateTime.parse(period['start']).toLocal(),
          'end': DateTime.parse(period['end']).toLocal(),
        });
      }
    }
    busyBlocks.sort((a, b) => a['start']!.compareTo(b['start']!));
    bool isFree = busyBlocks.every((b) =>
        preferredEnd.isBefore(b['start']!) ||
        preferredStart.isAfter(b['end']!));
    if (isFree) {
      await _createEventOnCalendar(
          title: title,
          attendees: attendees,
          startTime: preferredStart,
          endTime: preferredEnd);
      return;
    }
    DateTime searchCursor = DateTime.now().add(const Duration(minutes: 30));
    final duration = preferredEnd.difference(preferredStart);
    final endLimit = DateTime.now().add(const Duration(days: 7));
    while (searchCursor.isBefore(endLimit)) {
      final proposedStart = searchCursor;
      final proposedEnd = proposedStart.add(duration);
      if (proposedStart.hour < 8 || proposedStart.hour > 19) {
        searchCursor = DateTime(
            proposedStart.year, proposedStart.month, proposedStart.day + 1, 8);
        continue;
      }
      final overlaps = busyBlocks.any((b) =>
          !(proposedEnd.isBefore(b['start']!) ||
              proposedStart.isAfter(b['end']!)));
      if (!overlaps) {
        _showSuggestedTimeDialog(
            title: title,
            attendees: attendees,
            suggestedStart: proposedStart,
            suggestedEnd: proposedEnd);
        return;
      }
      searchCursor = searchCursor.add(const Duration(minutes: 30));
    }
    _showSnack("No common free time found in the next 7 days.");
  }

  void _showSuggestedTimeDialog(
      {required String title,
      required List<String> attendees,
      required DateTime suggestedStart,
      required DateTime suggestedEnd}) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Suggested Time"),
              content: Text(
                  "No one is available at your selected time.\n\nHow about:\n${formatDateTime(suggestedStart)} → ${formatDateTime(suggestedEnd)}"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _createEventOnCalendar(
                          title: title,
                          attendees: attendees,
                          startTime: suggestedStart,
                          endTime: suggestedEnd);
                    },
                    child: const Text("Schedule at Suggested Time"))
              ],
            ));
  }

  Future<void> _createEventOnCalendar(
      {required String title,
      required List<String> attendees,
      required DateTime startTime,
      required DateTime endTime}) async {
    final authService = AuthService();
    final accessToken = await authService.getAccessToken();
    final url = Uri.parse(
        "https://www.googleapis.com/calendar/v3/calendars/primary/events?sendUpdates=all");
    final body = {
      "summary": title,
      "start": {
        "dateTime": startTime.toUtc().toIso8601String(),
        "timeZone": "UTC"
      },
      "end": {
        "dateTime": endTime.toUtc().toIso8601String(),
        "timeZone": "UTC"
      },
      "attendees": attendees.map((email) => {"email": email}).toList(),
      "reminders": {"useDefault": true}
    };
    final response = await http.post(url,
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json"
        },
        body: jsonEncode(body));
    if (response.statusCode == 200 || response.statusCode == 201) {
      _showSnack("Event created and invites sent!");
      await _refreshCalendarEvents();
    } else {
      debugPrint("Create event error: ${response.body}");
      _showSnack("Failed to create event.");
    }
  }

  Widget _buildGradientTextField(
      TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 16),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  void _showCreateEventDialogWithTimePicker(BuildContext context, DateTime date) {
    final titleController = TextEditingController();
    final emailsController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            content: StatefulBuilder(builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                      blendMode: BlendMode.srcIn,
                      child: const Text(
                        "Create Event",
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildGradientTextField(titleController, "Event Title"),
                    const SizedBox(height: 25),
                    _buildGradientTextField(emailsController, "Invitees (comma-separated emails)"),
                    const SizedBox(height: 25),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: Colors.white,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final pickedTime = await showTimePicker(context: context, initialTime: selectedTime);
                            if (pickedTime != null) {
                              setState(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          child: Text("Select Time: ${selectedTime.format(context)}", style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: Colors.white,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            final title = titleController.text;
                            final emails = emailsController.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            if (emails.isEmpty || title.isEmpty) return;
                            final startDateTime = DateTime(date.year, date.month, date.day, selectedTime.hour, selectedTime.minute);
                            final endDateTime = startDateTime.add(const Duration(hours: 1));
                            await _findBestTimeAndCreateEvent(title, emails, startDateTime, endDateTime);
                          },
                          child: const Text("Find Best Time", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        });
  }

  void _showCreateEventDialog(BuildContext context, DateTime defaultStart) {
    final titleController = TextEditingController();
    final emailsController = TextEditingController();
    DateTime selectedStart = defaultStart;
    DateTime selectedEnd = defaultStart.add(const Duration(hours: 1));
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                    blendMode: BlendMode.srcIn,
                    child: const Text(
                      "Create Event",
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildGradientTextField(titleController, "Event Title"),
                  const SizedBox(height: 25),
                  _buildGradientTextField(emailsController, "Invitees (comma-separated emails)"),
                  const SizedBox(height: 25),
                  Text("Start: ${DateFormat('MMMM d, y – h:mm a').format(selectedStart)}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text("End: ${DateFormat('MMMM d, y – h:mm a').format(selectedEnd)}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 25),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white,
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          final title = titleController.text;
                          final emails = emailsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          if (emails.isEmpty || title.isEmpty) return;
                          await _findBestTimeAndCreateEvent(title, emails, selectedStart, selectedEnd);
                        },
                        child: const Text("Find Best Time", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildCalendarContainer(Widget calendarChild) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
      padding: const EdgeInsets.all(3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Container(color: Colors.white, padding: const EdgeInsets.only(top: 16), child: calendarChild),
      ),
    );
  }
Widget _buildWeekCalendarContainer(Widget calendarChild) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    padding: const EdgeInsets.all(3),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(27),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(top: 16),
        child: calendarChild,
      ),
    ),
  );
}


  Widget _buildMonthCalendar({Key? key}) {
    return _buildCalendarContainer(
      SfCalendar(
        key: key,
        view: CalendarView.month,
        dataSource: EventDataSource(_appointments),
        backgroundColor: Colors.white,
        todayHighlightColor: const Color(0xFF909533),
        showNavigationArrow: true,
        viewHeaderHeight: 50,
        headerHeight: 50,
        cellBorderColor: Colors.transparent,
        selectionDecoration: const BoxDecoration(),
        headerStyle: const CalendarHeaderStyle(
            textAlign: TextAlign.center,
            backgroundColor: Colors.transparent,
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
            showAgenda: false,
            showTrailingAndLeadingDates: false,
            dayFormat: 'EEE',
            numberOfWeeksInView: 5),
        onTap: (CalendarTapDetails details) {
  if (details.date != null) {
    setState(() {
      _selectedDate = details.date!.toLocal();
    });
  }
},

        monthCellBuilder: (BuildContext context, MonthCellDetails details) {
          final today = DateTime.now();
          final isToday = today.year == details.date.year &&
              today.month == details.date.month &&
              today.day == details.date.day;
          final isSelected = _selectedDate != null &&
              _selectedDate!.year == details.date.year &&
              _selectedDate!.month == details.date.month &&
              _selectedDate!.day == details.date.day;
          return Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: (isSelected || isToday)
                    ? const LinearGradient(
                        colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter)
                    : null,
                border: isSelected ? Border.all(width: 3, color: Colors.transparent) : null,
              ),
              child: Center(
                child: Text(
                  '${details.date.day}',
                  style: TextStyle(color: (isSelected || isToday) ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekCalendar({Key? key}) {
    return _buildWeekCalendarContainer(
      SfCalendar(
        key: key,
        view: CalendarView.week,
        dataSource: EventDataSource(_appointments),
        backgroundColor: Colors.transparent,
        cellBorderColor: Colors.grey.shade300,
        todayHighlightColor: Colors.black87,
        showNavigationArrow: true,
        viewHeaderHeight: 50,
        headerHeight: 60,
        selectionDecoration: const BoxDecoration(),
        headerStyle: const CalendarHeaderStyle(
            textAlign: TextAlign.center,
            backgroundColor: Colors.transparent,
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        viewHeaderStyle: const ViewHeaderStyle(
            dayTextStyle: TextStyle(color: Colors.black87, fontSize: 12),
            dateTextStyle: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
        timeSlotViewSettings: const TimeSlotViewSettings(
            startHour: 8,
            endHour: 20,
            timeIntervalHeight: 60,
            timeFormat: 'h:mm a',
            timeTextStyle: TextStyle(color: Colors.black87)),
        onTap: (CalendarTapDetails details) {
          if (details.date != null) {
            final tappedDate = details.date!.toLocal();
            setState(() {
              _selectedDate = tappedDate;
            });
            _showCreateEventDialog(context, tappedDate);
          }
        },
      ),
    );
  }

  Widget _buildToggleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text("Upcoming Events", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(width: 8),
            IconButton(
                icon: const Icon(Icons.add, color: Color(0xFF396548)),
                onPressed: () {
                  final defaultStart = _selectedDate ?? DateTime.now();
                  if (_calendarView == CalendarView.month) {
                    _showCreateEventDialogWithTimePicker(context, defaultStart);
                  } else {
                    _showCreateEventDialog(context, defaultStart);
                  }
                })
          ],
        ),
        Row(
          children: [
            Switch(
                value: _calendarView == CalendarView.week,
                activeColor:  Colors.grey.shade300,
                activeTrackColor: Colors.grey,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.shade300,
                onChanged: (val) {
                  setState(() {
                    _calendarView = val ? CalendarView.week : CalendarView.month;
                  });
                }),
            const Text("Week", style: TextStyle(color: Colors.black87, fontSize: 16))
          ],
        )
      ],
    );
  }

  Widget _buildUpcomingEventsSection() {
    return Expanded(
      flex: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildToggleSection(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: ListView(
                children: [
                  if (_getFilteredAppointments().isEmpty)
                    const Text("No events found.", style: TextStyle(color: Colors.grey)),
                  ..._getFilteredAppointments().map((appt) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF909533), shape: BoxShape.circle)),
                            Container(width: 2, height: 60, color: Colors.grey.shade300),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appt.subject.split('\n')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text("${formatDateTime(appt.startTime)} → ${formatDateTime(appt.endTime)}", style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 7,
                  child: _calendarView == CalendarView.week
                      ? _buildWeekCalendar(key: const ValueKey('week'))
                      : _buildMonthCalendar(key: const ValueKey('month')),
                ),
                const SizedBox(height: 20),
                _buildUpcomingEventsSection(),
              ],
            ),
    );
  }
}

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Appointment> source) {
    appointments = source;
  }
}
