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

  @override
  void initState() {
    super.initState();
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
        return AlertDialog(
          title: const Text("Create Event"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Event Title"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailsController,
                  decoration: const InputDecoration(
                    labelText: "Invitees (comma-separated emails)",
                  ),
                ),
                const SizedBox(height: 10),
                Text("Start: ${formatDateTime(selectedStart)}"),
                Text("End: ${formatDateTime(selectedEnd)}"),
                const SizedBox(height: 10),
                ElevatedButton(
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
                  child: const Text("Find Best Time"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Calendar"),
        actions: [
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.view_week),
            onSelected: _changeView,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: CalendarView.day,
                child: Text("Day View"),
              ),
              PopupMenuItem(
                value: CalendarView.week,
                child: Text("Week View"),
              ),
              PopupMenuItem(
                value: CalendarView.month,
                child: Text("Month View"),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              AppUser.instance.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthWrapper()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SfCalendar(
              key: ValueKey(_calendarView),
              view: _calendarView,
              dataSource: EventDataSource(_appointments),
              monthViewSettings: const MonthViewSettings(
                appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
              ),
              appointmentTextStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              todayHighlightColor: Colors.green,
              onTap: (CalendarTapDetails details) {
                if (details.appointments == null ||
                    details.appointments!.isEmpty) {
                  _showCreateEventDialog(context, details.date!);
                } else {
                  final appointment = details.appointments!.first;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(appointment.subject),
                      content: Text(
                        'Start: ${appointment.startTime}\n'
                        'End: ${appointment.endTime}\n'
                        'Location: ${appointment.location ?? "Unknown"}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
    );
  }
}

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Appointment> source) {
    appointments = source;
  }
}
