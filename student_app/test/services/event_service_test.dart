import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/services/event_service.dart';

void main() {
  group('EventService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late EventService eventService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      eventService = EventService(firestore: fakeFirestore);
    });

    test('getAllEvents returns all events', () async {
      await fakeFirestore.collection('events').add({
        'name': 'Event 1',
        'startDate': DateTime(2023, 10, 1),
        'location': 'Location 1',
      });
      await fakeFirestore.collection('events').add({
        'name': 'Event 2',
        'startDate': DateTime(2023, 10, 2),
        'location': 'Location 2',
      });

      final events = await eventService.getAllEvents();

      expect(events.length, 2);
      expect(events[0]['name'], 'Event 1');
      expect(events[1]['name'], 'Event 2');
    });

    test('getEventsByStartDate returns events with matching startDate',
        () async {
      final startDate = DateTime(2023, 10, 1);
      await fakeFirestore.collection('events').add({
        'name': 'Event 1',
        'startDate': startDate,
        'location': 'Location 1',
      });
      await fakeFirestore.collection('events').add({
        'name': 'Event 2',
        'startDate': DateTime(2023, 10, 2),
        'location': 'Location 2',
      });

      final events = await eventService.getEventsByStartDate(startDate);

      expect(events.length, 1);
      expect(events[0]['name'], 'Event 1');
    });

    test('getEventsByLocation returns events with matching location', () async {
      const location = 'Location 1';
      await fakeFirestore.collection('events').add({
        'name': 'Event 1',
        'startDate': DateTime(2023, 10, 1),
        'location': location,
      });
      await fakeFirestore.collection('events').add({
        'name': 'Event 2',
        'startDate': DateTime(2023, 10, 2),
        'location': 'Location 2',
      });

      final events = await eventService.getEventsByLocation(location);

      expect(events.length, 1);
      expect(events[0]['name'], 'Event 1');
    });

    test('editEvent updates the specified field of an event', () async {
      final docRef = await fakeFirestore.collection('events').add({
        'name': 'Event 1',
        'startDate': DateTime(2023, 10, 1),
        'location': 'Location 1',
      });

      await eventService.editEvent(docRef.id, 'name', 'Updated Event 1');

      final updatedDoc =
          await fakeFirestore.collection('events').doc(docRef.id).get();
      expect(updatedDoc.data()?['name'], 'Updated Event 1');
    });
  });
}
