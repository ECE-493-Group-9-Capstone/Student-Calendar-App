import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/services/study_spot_service.dart';

void main() {
  group('StudySpotService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late StudySpotService studySpotService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      studySpotService = StudySpotService(firestore: fakeFirestore);
    });

    test('getAllStudySpots returns all study spots', () async {
      await fakeFirestore.collection('studySpots').add({'name': 'Library'});
      await fakeFirestore.collection('studySpots').add({'name': 'Cafe'});

      final spots = await studySpotService.getAllStudySpots();

      expect(spots.length, 2);
      expect(spots[0]['name'], 'Library');
      expect(spots[1]['name'], 'Cafe');
    });

    test('getStudySpotByName returns study spots with matching name', () async {
      await fakeFirestore.collection('studySpots').add({'name': 'Library'});
      await fakeFirestore.collection('studySpots').add({'name': 'Cafe'});

      final spots = await studySpotService.getStudySpotByName('Library');

      expect(spots.length, 1);
      expect(spots[0]['name'], 'Library');
    });

    test('editStudySpot updates the specified field', () async {
      final docRef =
          await fakeFirestore.collection('studySpots').add({'name': 'Library'});

      await studySpotService.editStudySpot(
          docRef.id, 'name', 'Updated Library');

      final updatedDoc =
          await fakeFirestore.collection('studySpots').doc(docRef.id).get();
      expect(updatedDoc.data()?['name'], 'Updated Library');
    });

    test('rateStudySpot adds a rating and updates average rating', () async {
      final docRef =
          await fakeFirestore.collection('studySpots').add({'name': 'Library'});

      await studySpotService.rateStudySpot(docRef.id, 'user1', 5);
      await studySpotService.rateStudySpot(docRef.id, 'user2', 3);

      final updatedDoc =
          await fakeFirestore.collection('studySpots').doc(docRef.id).get();
      expect(updatedDoc.data()?['averageRating'], 4.0);
    });

    test('getStudySpotAverageRating returns the average rating', () async {
      final docRef = await fakeFirestore
          .collection('studySpots')
          .add({'name': 'Library', 'averageRating': 4.5});

      final averageRating =
          await studySpotService.getStudySpotAverageRating(docRef.id);

      expect(averageRating, 4.5);
    });

    test('getAllRatingsForSpot returns all ratings for a study spot', () async {
      final docRef =
          await fakeFirestore.collection('studySpots').add({'name': 'Library'});
      await fakeFirestore
          .collection('studySpots')
          .doc(docRef.id)
          .collection('ratings')
          .add({'userId': 'user1', 'rating': 5});
      await fakeFirestore
          .collection('studySpots')
          .doc(docRef.id)
          .collection('ratings')
          .add({'userId': 'user2', 'rating': 3});

      final ratings = await studySpotService.getAllRatingsForSpot(docRef.id);

      expect(ratings.length, 2);
      expect(ratings[0]['rating'], 5);
      expect(ratings[1]['rating'], 3);
    });
  });
}
