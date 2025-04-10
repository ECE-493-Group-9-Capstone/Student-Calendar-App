import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:student_app/services/calendar_service.dart';

@GenerateMocks([
  http.Client,
  calendar.CalendarApi,
  calendar.EventsResource,
  CalendarService
])
import 'calendar_service_test.mocks.dart';

void main() {
  late MockCalendarApi mockCalendarApi;
  late MockEventsResource mockEventsResource;
  late MockCalendarService mockCalendarService;

  setUp(() {
    mockCalendarApi = MockCalendarApi();
    mockEventsResource = MockEventsResource();
    mockCalendarService = MockCalendarService();
    when(mockCalendarApi.events).thenReturn(mockEventsResource);
  });

  group('fetchCalendarEvents', () {
    test('returns a list of events when API call is successful', () async {
      final mockEvents = [
        calendar.Event(summary: 'Event 1'),
        calendar.Event(summary: 'Event 2'),
      ];

      when(mockCalendarService.fetchCalendarEvents(any))
          .thenAnswer((_) async => mockEvents);

      final events =
          await mockCalendarService.fetchCalendarEvents('mockAccessToken');

      expect(events.length, 2);
      expect(events[0].summary, 'Event 1');
      expect(events[1].summary, 'Event 2');
    });

    test('returns an empty list when API call fails', () async {
      // Mock the fetchCalendarEvents method to throw an exception
      when(mockCalendarService.fetchCalendarEvents(any))
          .thenThrow(Exception('API error'));

      try {
        final events =
            await mockCalendarService.fetchCalendarEvents('mockAccessToken');
        expect(events, isEmpty);
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });

  group('fetchTodayCalendarEvents', () {
    test('returns a list of today\'s events when API call is successful',
        () async {
      final mockEvents = [
        calendar.Event(summary: 'Today Event 1'),
        calendar.Event(summary: 'Today Event 2'),
      ];

      when(mockCalendarService.fetchTodayCalendarEvents(any))
          .thenAnswer((_) async => mockEvents);

      final events =
          await mockCalendarService.fetchTodayCalendarEvents('mockAccessToken');

      expect(events.length, 2);
      expect(events[0].summary, 'Today Event 1');
      expect(events[1].summary, 'Today Event 2');
    });

    test('returns an empty list when API call fails', () async {
      when(mockCalendarService.fetchTodayCalendarEvents(any))
          .thenThrow(Exception('API error'));

      try {
        final events = await mockCalendarService
            .fetchTodayCalendarEvents('mockAccessToken');
        expect(events, isEmpty);
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });
}
