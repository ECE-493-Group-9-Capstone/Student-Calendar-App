import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:student_app/services/auth_service.dart';
import 'package:student_app/services/calendar_service.dart';
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

  final LinearGradient _gradient = const LinearGradient(
    colors: [
      Color(0xFF396548),
      Color(0xFF6B803D),
      Color(0xFF909533),
    ],
  );

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

  String formatDateTime(DateTime dt) =>
      DateFormat('MMMM d, y – h:mm a').format(dt);

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
    if (accessToken == null) {
      return;
    }

    final calendarService = CalendarService();
    final googleEvents = await calendarService.fetchCalendarEvents(accessToken);

    final List<Appointment> freshAppointments = [];
    for (var event in googleEvents) {
      final start = (event.start?.dateTime ?? event.start?.date)?.toLocal();
      final end = (event.end?.dateTime ?? event.end?.date)?.toLocal();
      final title = event.summary ?? 'No Title';
      final location = event.location ?? 'No Location';
      if (start != null && end != null) {
        freshAppointments.add(
          Appointment(
            startTime: start,
            endTime: end,
            subject: '$title\n$location',
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    if (accessToken == null) {
      return;
    }

    final timeMin = preferredStart.toUtc();
    final timeMax = timeMin.add(const Duration(days: 7));
    final url = Uri.parse('https://www.googleapis.com/calendar/v3/freeBusy');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'timeMin': timeMin.toIso8601String(),
        'timeMax': timeMax.toIso8601String(),
        'timeZone': 'UTC',
        'items': attendees.map((email) => {'id': email}).toList(),
      }),
    );

    if (response.statusCode != 200) {
      _showSnack('Failed to fetch availability.');
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

    final bool isFree = busyBlocks.every((b) =>
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

    DateTime searchCursor = DateTime.now().add(const Duration(minutes: 30));
    final duration = preferredEnd.difference(preferredStart);
    final endLimit = DateTime.now().add(const Duration(days: 7));

    while (searchCursor.isBefore(endLimit)) {
      final proposedStart = searchCursor;
      final proposedEnd = proposedStart.add(duration);
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
      searchCursor = searchCursor.add(const Duration(minutes: 30));
    }

    _showSnack('No common free time found in the next 7 days.');
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
        title: const Text('Suggested Time'),
        content: Text(
          'No one is available at your selected time.\n\nHow about:\n'
          '${formatDateTime(suggestedStart)} → ${formatDateTime(suggestedEnd)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await _createEventOnCalendar(
                title: title,
                attendees: attendees,
                startTime: suggestedStart,
                endTime: suggestedEnd,
              );
            },
            child: const Text('Schedule at Suggested Time'),
          )
        ],
      ),
    );
  }

  Future<void> _createEventOnCalendar({
    required String title,
    required List<String> attendees,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final authService = AuthService();
    final accessToken = await authService.getAccessToken();
    if (accessToken == null) {
      return;
    }

    final url = Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events?sendUpdates=all',
    );

    final body = {
      'summary': title,
      'start': {
        'dateTime': startTime.toUtc().toIso8601String(),
        'timeZone': 'UTC'
      },
      'end': {'dateTime': endTime.toUtc().toIso8601String(), 'timeZone': 'UTC'},
      'attendees': attendees.map((email) => {'email': email}).toList(),
      'reminders': {'useDefault': true}
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _showSnack('Event created and invites sent!');
      await _refreshCalendarEvents();
    } else {
      debugPrint('Create event error: ${response.body}');
      _showSnack('Failed to create event.');
    }
  }

  Widget _buildPlainTextField(TextEditingController controller, String hint) =>
      Container(
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
      );

  Widget _wrapInGradientBox({required Widget child}) => Container(
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(23),
          ),
          child: child,
        ),
      );

  // A helper to open the Time Picker with a white, gray-bordered style.
  // We override the theme in the builder to achieve the custom look.
  Future<TimeOfDay?> _showWhiteTimePicker(
    BuildContext context,
    TimeOfDay initialTime,
  ) async =>
      showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) => Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: Colors.grey.shade700, // Title and selection color
              onPrimary: Colors.white, // Text on the selection color
              onSurface: Colors.black, // Text color on default surface
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400, width: 1.0),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400, width: 1.0),
              ),
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.grey.shade700;
                }
                return Colors.white;
              }),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.black;
              }),
            ),
          ),
          child: child!,
        ),
      );

  void _showCreateEventDialogWithTimeSelector(
      BuildContext context, DateTime date) {
    final titleController = TextEditingController();
    final emailsController = TextEditingController();
    TimeOfDay selectedStartTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay selectedEndTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create Event',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 98, 98, 98),
                        ),
                      ),
                      const SizedBox(height: 25),
                      _wrapInGradientBox(
                        child: _buildPlainTextField(
                          titleController,
                          'Event Title',
                        ),
                      ),
                      const SizedBox(height: 25),
                      _wrapInGradientBox(
                        child: _buildPlainTextField(
                          emailsController,
                          'Invitees (comma-separated emails)',
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        "Date: ${DateFormat('MMMM d, y').format(date)}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // START TIME BUTTON
                      Container(
                        decoration: BoxDecoration(
                          gradient: _gradient,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () async {
                            final picked = await _showWhiteTimePicker(
                              context,
                              selectedStartTime,
                            );
                            if (picked != null) {
                              setState(() {
                                selectedStartTime = picked;
                              });
                            }
                          },
                          child: Text(
                            'Start Time: ${selectedStartTime.format(context)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // END TIME BUTTON
                      Container(
                        decoration: BoxDecoration(
                          gradient: _gradient,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () async {
                            final picked = await _showWhiteTimePicker(
                              context,
                              selectedEndTime,
                            );
                            if (picked != null) {
                              setState(() {
                                selectedEndTime = picked;
                              });
                            }
                          },
                          child: Text(
                            'End Time: ${selectedEndTime.format(context)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // CREATE BUTTON
                      Container(
                        decoration: BoxDecoration(
                          gradient: _gradient,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final title = titleController.text;
                            final emails = emailsController.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            if (title.isEmpty || emails.isEmpty) {
                              return;
                            }
                            final startDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              selectedStartTime.hour,
                              selectedStartTime.minute,
                            );
                            final endDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              selectedEndTime.hour,
                              selectedEndTime.minute,
                            );
                            if (endDateTime.isAfter(startDateTime)) {
                              await _findBestTimeAndCreateEvent(
                                title,
                                emails,
                                startDateTime,
                                endDateTime,
                              );
                            } else {
                              _showSnack('End time must be after start time.');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Create',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context, DateTime defaultStart) {
    final titleController = TextEditingController();
    final emailsController = TextEditingController();
    TimeOfDay selectedStartTime =
        TimeOfDay(hour: defaultStart.hour, minute: defaultStart.minute);
    TimeOfDay selectedEndTime = TimeOfDay(
        hour: (defaultStart.hour + 1) % 24, minute: defaultStart.minute);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create Event',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 98, 98, 98),
                        ),
                      ),
                      const SizedBox(height: 25),
                      _wrapInGradientBox(
                        child: _buildPlainTextField(
                          titleController,
                          'Event Title',
                        ),
                      ),
                      const SizedBox(height: 25),
                      _wrapInGradientBox(
                        child: _buildPlainTextField(
                          emailsController,
                          'Invitees (comma-separated emails)',
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        "Date: ${DateFormat('MMMM d, y').format(defaultStart)}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // START TIME BUTTON
                      Container(
                        decoration: BoxDecoration(
                          gradient: _gradient,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () async {
                            final picked = await _showWhiteTimePicker(
                              context,
                              selectedStartTime,
                            );
                            if (picked != null) {
                              setState(() {
                                selectedStartTime = picked;
                              });
                            }
                          },
                          child: Text(
                            'Start Time: ${selectedStartTime.format(context)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // END TIME BUTTON
                      Container(
                        decoration: BoxDecoration(
                          gradient: _gradient,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () async {
                            final picked = await _showWhiteTimePicker(
                              context,
                              selectedEndTime,
                            );
                            if (picked != null) {
                              setState(() {
                                selectedEndTime = picked;
                              });
                            }
                          },
                          child: Text(
                            'End Time: ${selectedEndTime.format(context)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // CREATE BUTTON
                      Container(
                        decoration: BoxDecoration(
                          gradient: _gradient,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final title = titleController.text;
                            final emails = emailsController.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            if (title.isEmpty || emails.isEmpty) {
                              return;
                            }
                            final startDateTime = DateTime(
                              defaultStart.year,
                              defaultStart.month,
                              defaultStart.day,
                              selectedStartTime.hour,
                              selectedStartTime.minute,
                            );
                            final endDateTime = DateTime(
                              defaultStart.year,
                              defaultStart.month,
                              defaultStart.day,
                              selectedEndTime.hour,
                              selectedEndTime.minute,
                            );
                            if (endDateTime.isAfter(startDateTime)) {
                              await _findBestTimeAndCreateEvent(
                                title,
                                emails,
                                startDateTime,
                                endDateTime,
                              );
                            } else {
                              _showSnack('End time must be after start time.');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Create',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthCalendar({Key? key}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Container(
            color: Colors.white,
            child: SfCalendar(
              key: key,
              view: CalendarView.month,
              dataSource: EventDataSource(_appointments),
              backgroundColor: Colors.white,
              todayHighlightColor: Colors.transparent,
              showNavigationArrow: true,
              viewHeaderHeight: 30,
              headerHeight: 30,
              cellBorderColor: Colors.transparent,
              selectionDecoration: const BoxDecoration(),
              headerStyle: const CalendarHeaderStyle(
                textAlign: TextAlign.center,
                backgroundColor: Colors.transparent,
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
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
                  setState(() {
                    _selectedDate = details.date!.toLocal();
                  });
                }
              },
              monthCellBuilder:
                  (BuildContext context, MonthCellDetails details) {
                final today = DateTime.now();
                final isToday = today.year == details.date.year &&
                    today.month == details.date.month &&
                    today.day == details.date.day;
                final isSelected = _selectedDate != null &&
                    _selectedDate!.year == details.date.year &&
                    _selectedDate!.month == details.date.month &&
                    _selectedDate!.day == details.date.day;
                if (isToday) {
                  return Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _gradient,
                      ),
                      child: Center(
                        child: Text(
                          '${details.date.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                } else if (isSelected) {
                  return Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _gradient,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Text(
                              '${details.date.day}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          '${details.date.day}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      );

  Widget _buildWeekCalendar({Key? key}) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
            child: SfCalendar(
              key: key,
              view: CalendarView.workWeek,
              dataSource: EventDataSource(_appointments),
              backgroundColor: Colors.white,
              cellBorderColor: Colors.grey.shade300,
              todayHighlightColor: Colors.black87,
              showNavigationArrow: true,
              viewHeaderHeight: 55,
              headerHeight: 27,
              selectionDecoration: const BoxDecoration(),
              headerStyle: const CalendarHeaderStyle(
                textAlign: TextAlign.center,
                backgroundColor: Colors.transparent,
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              viewHeaderStyle: const ViewHeaderStyle(
                dayTextStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                dateTextStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 8,
                endHour: 20,
                timeIntervalHeight: 60,
                timeFormat: 'h:mm a',
                timeTextStyle: TextStyle(color: Colors.black87),
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
            ),
          ),
        ),
      );

  Widget _buildBottomEventsSection() {
    final filtered = _getFilteredAppointments();
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Upcoming Events',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No events found.',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : Stack(
                        children: [
                          Positioned(
                            left: 25,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: Colors.white,
                            ),
                          ),
                          ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final appt = filtered[index];
                              return _buildTimelineItem(appt);
                            },
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              final defaultStart = _selectedDate ?? DateTime.now();
              if (_calendarView == CalendarView.month) {
                _showCreateEventDialogWithTimeSelector(context, defaultStart);
              } else {
                _showCreateEventDialog(context, defaultStart);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Appointment appt) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 50,
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appt.subject.split('\n')[0],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDateTime(appt.startTime),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  void _showToggleCalendarViewDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Instructions for uploading the .ics file
                  const Text(
                    'Important',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To use the calendar functionality, please download your .ics file from Beartracks under the Schedule tab and upload it to your main Google Calendar.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Calendar view selection header and options
                  const Text(
                    'Select Calendar View',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 98, 98, 98),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogOption('Month View', CalendarView.month),
                  _buildDialogOption('Week View', CalendarView.week),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogOption(String label, CalendarView value) {
    final bool selected = _calendarView == value;
    return ListTile(
      onTap: () {
        setState(() {
          _calendarView = value;
        });
        Navigator.pop(context);
      },
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: selected ? _gradient : null,
          color: selected ? null : Colors.white,
          border: Border.all(color: Colors.grey, width: 2),
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 40,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.black),
              onPressed: _showToggleCalendarViewDialog,
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        height: 325,
                        width: 325,
                        child: _calendarView == CalendarView.week
                            ? _buildWeekCalendar(key: const ValueKey('week'))
                            : _buildMonthCalendar(key: const ValueKey('month')),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(child: _buildBottomEventsSection()),
                  ],
                ),
        ),
      );
}

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class SimpleTimeSelector extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;
  const SimpleTimeSelector({
    super.key,
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  SimpleTimeSelectorState createState() => SimpleTimeSelectorState();
}

class SimpleTimeSelectorState extends State<SimpleTimeSelector> {
  late int selectedHour;
  late int selectedMinute;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute;
  }

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 100,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 40,
                perspective: 0.005,
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedHour = index;
                  });
                  widget.onTimeSelected(
                      TimeOfDay(hour: selectedHour, minute: selectedMinute));
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    if (index < 0 || index > 23) {
                      return null;
                    }
                    return Center(
                        child: Text(index.toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 18)));
                  },
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(':', style: TextStyle(fontSize: 24)),
          ),
          Expanded(
            child: SizedBox(
              height: 100,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 40,
                perspective: 0.005,
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedMinute = index * 5;
                  });
                  widget.onTimeSelected(
                      TimeOfDay(hour: selectedHour, minute: selectedMinute));
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    if (index < 0 || index > 11) {
                      return null;
                    }
                    final int minute = index * 5;
                    return Center(
                        child: Text(minute.toString().padLeft(2, '0'),
                            style: const TextStyle(fontSize: 18)));
                  },
                ),
              ),
            ),
          ),
        ],
      );
}
