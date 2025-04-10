import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/features/map/event_popup.dart';

void main() {
  group('EventPopup', () {
    testWidgets('renders EventPopup', (tester) async {
      // Create a real event object with corrected time fields
      final mockEvent = {
        'id': '1',
        'title': 'Test Event',
        'description': 'This is a test event.',
        'startDate': DateTime.now().toIso8601String(),
        'endDate':
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'start_time': '10:00 AM',
        'end_time': '12:00 PM',
        'location': 'Test Location',
        'coordinates': {'latitude': 0.0, 'longitude': 0.0},
        'imageUrl': null,
        'link': null,
      };

      // Wrap the EventPopup in MaterialApp and Scaffold for proper rendering
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventPopup(event: mockEvent),
          ),
        ),
      );

      // Verify that the EventPopup widget is rendered
      expect(find.byType(EventPopup), findsOneWidget);
    });
  });
}
