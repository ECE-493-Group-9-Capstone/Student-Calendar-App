import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/utils/event_service.dart';

void main() {
  group('Event Collection Tests', () {
    late EventService eventService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      eventService = EventService(firestore: fakeFirestore);

      fakeFirestore.collection('events').add({
        'name': 'Test Event 1',
        'startDate': DateTime(2025, 3, 15),
        'location': 'Edmonton',
      });

      fakeFirestore.collection('events').add({
        'name': 'Test Event 2',
        'startDate': DateTime(2025, 3, 16),
        'location': 'Calgary',
      });
    });

    test('gets all events', () async {
      final events = await eventService.getAllEvents();
      expect(events.length, 2);
    });

    test('gets events for a specific date', () async {
      final date = DateTime(2025, 3, 15);
      final events = await eventService.getEventsByStartDate(date);
      expect(events.length, 1);
      expect(events.first['name'], 'Test Event 1');
    });

    test('gets events for a specific location', () async {
      final events = await eventService.getEventsByLocation('Calgary');
      expect(events.length, 1);
      expect(events.first['location'], 'Calgary');
    });

    test('edit event shows update', () async {
      final date = DateTime(2025, 3, 15);
      final events = await eventService.getEventsByStartDate(date);
      expect(events.length, 1);
      expect(events.first['name'], 'Test Event 1');

      final eventId = events.first['id'];
      await fakeFirestore.collection('events').doc(eventId).update({
        'name': 'Updated Event',
      });

      final updatedEvents = await eventService.getEventsByStartDate(date);
      expect(updatedEvents.length, 1);
      expect(updatedEvents.first['name'], 'Updated Event');
    });
  });
}
