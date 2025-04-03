import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:student_app/pages/google_signin.dart';
import 'package:student_app/utils/google_calendar_service.dart';
import 'package:student_app/main.dart';
import 'package:student_app/user_singleton.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static List<Appointment>? _cachedAppointments;
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  CalendarView _calendarView = CalendarView.week;
  DateTime? _selectedDate;


  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); 

    _loadCalendarEvents();
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

    final authService = AuthService();
    final accessToken = await authService.getAccessToken();

    if (accessToken == null) {
      setState(() => _isLoading = false);
      return;
    }

    final calendarService = GoogleCalendarService();
    final googleEvents = await calendarService.fetchCalendarEvents(accessToken);

    List<Appointment> appointments = [];

    for (var event in googleEvents) {
      final start = (event.start?.dateTime ?? event.start?.date)?.toLocal();
      final end = (event.end?.dateTime ?? event.end?.date)?.toLocal();
      final title = event.summary ?? "No Title";
      final location = event.location ?? "No Location";

      if (start != null && end != null) {
        appointments.add(
          Appointment(
            startTime: start,
            endTime: end,
            subject: "$title\n$location",
            color: Colors.blueAccent.withOpacity(0.7),
          ),
        );
      }
    }

    setState(() {
      _appointments = appointments;
      _cachedAppointments = appointments;
      _isLoading = false;
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


  void _changeView(CalendarView newView) {
    setState(() {
      _calendarView = newView;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuggestedTimeDialog({
    required String title,
    required List<String> attendees,
    required DateTime suggestedStart,
    required DateTime suggestedEnd,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Suggested Time"),
        content: Text(
          "No one is available at your selected time.\n\n"
          "How about:\n"
          "${formatDateTime(suggestedStart)} → ${formatDateTime(suggestedEnd)}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _createEventOnCalendar(
                title: title,
                attendees: attendees,
                startTime: suggestedStart,
                endTime: suggestedEnd,
              );
            },
            child: const Text("Schedule at Suggested Time"),
          ),
        ],
      ),
    );
  }

  Future<void> _findBestTimeAndCreateEvent(
    String title,
    List<String> attendees,
    DateTime preferredStart,
    DateTime preferredEnd,
  ) async {
    final authService = AuthService();
    final accessToken = await authService.getAccessToken();

    final timeMin = preferredStart.toUtc();
    final timeMax = timeMin.add(Duration(days: 7)); // Search within next 7 days

    final url = Uri.parse("https://www.googleapis.com/calendar/v3/freeBusy");
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "timeMin": timeMin.toIso8601String(),
        "timeMax": timeMax.toIso8601String(),
        "timeZone": "UTC",
        "items": attendees.map((email) => {"id": email}).toList(),
      }),
    );

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

    // Check if preferred time is clear
    bool isFree = busyBlocks.every((b) =>
        preferredEnd.isBefore(b['start']!) ||
        preferredStart.isAfter(b['end']!));

    if (isFree) {
      await _createEventOnCalendar(
        title: title,
        attendees: attendees,
        startTime: preferredStart,
        endTime: preferredEnd,
      );
      return;
    }

    // Search next free 1-hour slot (8am–8pm)
    DateTime searchCursor = DateTime.now().add(Duration(minutes: 30));
    final duration = preferredEnd.difference(preferredStart);
    final endLimit = DateTime.now().add(Duration(days: 7));

    while (searchCursor.isBefore(endLimit)) {
      final proposedStart = searchCursor;
      final proposedEnd = proposedStart.add(duration);

      // Skip overnight hours (10pm–6am)
      if (proposedStart.hour < 8 || proposedStart.hour > 19) {
        searchCursor = DateTime(
          proposedStart.year,
          proposedStart.month,
          proposedStart.day + 1,
          8,
        );
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
          suggestedEnd: proposedEnd,
        );
        return;
      }

      searchCursor = searchCursor.add(Duration(minutes: 30));
    }

    _showSnack("No common free time found in the next 7 days.");
  }

  Future<void> _createEventOnCalendar({
    required String title,
    required List<String> attendees,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
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
      "end": {"dateTime": endTime.toUtc().toIso8601String(), "timeZone": "UTC"},
      "attendees": attendees.map((email) => {"email": email}).toList(),
      "reminders": {"useDefault": true}
    };

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _showSnack("Event created and invites sent!");
    } else {
      debugPrint("Create event error: ${response.body}");
      _showSnack("Failed to create event.");
    }
  }

  void _showCreateEventDialog(BuildContext context, DateTime defaultStart) {
  final titleController = TextEditingController();
  final emailsController = TextEditingController();
  DateTime selectedStart = defaultStart;
  DateTime selectedEnd = defaultStart.add(Duration(hours: 1));

  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                _buildTextField("Event Title", titleController),
                const SizedBox(height: 20),
                _buildTextField("Invitees (comma-separated emails)", emailsController),

                const SizedBox(height: 20),
                Text("Start: ${formatDateTime(selectedStart)}"),
                Text("End: ${formatDateTime(selectedEnd)}"),

                const SizedBox(height: 24),

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

                      await _findBestTimeAndCreateEvent(
                        title,
                        emails,
                        selectedStart,
                        selectedEnd,
                      );
                    },
                    child: const Text("Find Best Time", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
Widget _buildTextField(String hint, TextEditingController controller) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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



@override
Widget build(BuildContext context) {
  return Scaffold(
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Gradient-bordered calendar inside an Expanded
              Expanded(
                flex: 7,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF396548),
                          Color(0xFF6B803D),
                          Color(0xFF909533),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(27),
                      child: Container(
                          padding: const EdgeInsets.only(top: 16), 

                        child: SfCalendar(
                          view: CalendarView.month,
                          dataSource: EventDataSource(_appointments),
                          backgroundColor: Colors.white,
                          todayHighlightColor: const Color(0xFF909533),
                          showNavigationArrow: true,
                          viewHeaderHeight: 40,
                          headerHeight: 50,
                          cellBorderColor: Colors.transparent,
                          selectionDecoration: BoxDecoration(),
                          headerStyle: CalendarHeaderStyle(
                            textAlign: TextAlign.center,
                            backgroundColor: Colors.transparent,
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          monthViewSettings: const MonthViewSettings(
                            appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                            showAgenda: false,
                            showTrailingAndLeadingDates: false,
                            dayFormat: 'EEE',
                            numberOfWeeksInView: 5,
                          ),
                          onTap: (CalendarTapDetails details) {
  if (details.date != null) {
    final tappedDate = details.date!.toLocal();
    setState(() {
      _selectedDate = tappedDate;
    });

    _showCreateEventDialog(context, tappedDate);
  }
},

                          monthCellBuilder: (BuildContext context, MonthCellDetails details) {
                            final isToday = DateTime.now().year == details.date.year &&
                                DateTime.now().month == details.date.month &&
                                DateTime.now().day == details.date.day;
                        
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
                                  border: isSelected
                                      ? Border.all(width: 3, color: Colors.transparent)
                                      : isToday
                                          ? Border.all(width: 2, color: Color(0xFF909533))
                                          : null,
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF396548),
                                            Color(0xFF6B803D),
                                            Color(0xFF909533),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '${details.date.day}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Upcoming Events",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Upcoming events list
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF909533),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 60,
                                  color: Colors.grey.shade300,
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appt.subject.split('\n')[0],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${formatDateTime(appt.startTime)} → ${formatDateTime(appt.endTime)}",
                                      style: const TextStyle(fontSize: 13),
                                    ),
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

}

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Appointment> source) {
    appointments = source;
  }
}