import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  Future<List<calendar.Event>> fetchCalendarEvents(String accessToken) async {
    try {
      final client = http.Client();

      final authenticatedClient = auth.authenticatedClient(
        client,
        auth.AccessCredentials(
          auth.AccessToken('Bearer', accessToken,
              DateTime.now().add(Duration(hours: 1)).toUtc()),
          null,
          ['https://www.googleapis.com/auth/calendar'],
        ),
      );

      final calendarApi = calendar.CalendarApi(authenticatedClient);
      // Pull from only the user's primary calendar
      final calEvents = await calendarApi.events.list(
        "primary",
        singleEvents: true,
        orderBy: 'startTime',
      );

      return calEvents.items ?? [];
    } catch (e) {
      print("Error fetching calendar events: $e");
      return [];
    }
  }
}
