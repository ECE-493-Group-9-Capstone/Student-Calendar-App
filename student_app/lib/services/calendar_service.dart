import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
// FR6 - Calendar.Modify - The system shall allow users to add, edit, or delete events in their 
// schedules. 
// FR7 - Calendar.Display - The system shall display the user’s calendar with options for 
// interaction. 
// FR8 - Calendar.Navigation - The system shall support basic calendar navigation, such as 
// switching between daily, weekly, and monthly views. 
// FR9 - Calendar.Offline - The system shall provide offline access to the most recently 
// synchronized calendar.
class CalendarService {
  Future<List<calendar.Event>> fetchCalendarEvents(String accessToken) async {
    try {
      final client = http.Client();

      final authenticatedClient = auth.authenticatedClient(
        client,
        auth.AccessCredentials(
          auth.AccessToken(
            'Bearer',
            accessToken,
            DateTime.now().add(const Duration(hours: 1)).toUtc(),
          ),
          null,
          ['https://www.googleapis.com/auth/calendar'],
        ),
      );

      final calendarApi = calendar.CalendarApi(authenticatedClient);
      // Pull from only the user's primary calendar
      final calEvents = await calendarApi.events.list(
        'primary',
        singleEvents: true,
        orderBy: 'startTime',
      );

      return calEvents.items ?? [];
    } catch (e) {
      debugPrint('Error fetching calendar events: $e');
      return [];
    }
  }

  Future<List<calendar.Event>> fetchTodayCalendarEvents(
      String accessToken) async {
    try {
      final client = http.Client();

      final authenticatedClient = auth.authenticatedClient(
        client,
        auth.AccessCredentials(
          auth.AccessToken(
            'Bearer',
            accessToken,
            DateTime.now().add(const Duration(hours: 1)).toUtc(),
          ),
          null,
          ['https://www.googleapis.com/auth/calendar'],
        ),
      );

      final calendarApi = calendar.CalendarApi(authenticatedClient);

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));

      final calEvents = await calendarApi.events.list(
        'primary',
        timeMin: startOfToday.toUtc(),
        timeMax: endOfToday.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      return calEvents.items ?? [];
    } catch (e) {
      debugPrint("Error fetching today's calendar events: $e");
      return [];
    }
  }
}
