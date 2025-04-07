import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudySpotService {
  final FirebaseFirestore firestore;

  // allow firestore injection
  StudySpotService({required this.firestore});

  Future<List<Map<String, dynamic>>> getAllStudySpots() async {
    try {
      QuerySnapshot querySnapshot =
          await firestore.collection('studySpots').get();

      List<Map<String, dynamic>> allStudySpots = querySnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return allStudySpots;
    } catch (e) {
      debugPrint("Error fetching Study Spots: $e");
      return [];
    }
  }

  // get studySpot by name
  Future<List<Map<String, dynamic>>> getStudySpotByName(String name) async {
    try {
      QuerySnapshot querySnapshot = await firestore
          .collection('studySpots')
          .where('name', isEqualTo: name)
          .get();

      List<Map<String, dynamic>> studySpots = querySnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return studySpots;
    } catch (e) {
      debugPrint("Error fetching Study Spots by name: $e");
      return [];
    }
  }

  // edit studySpot field
  Future<void> editStudySpot(String id, String field, dynamic value) async {
    try {
      await firestore.collection('studySpots').doc(id).update({field: value});
    } catch (e) {
      debugPrint("Error editing Study Spots: $e");
    }
  }

  // rate studySpot
  Future<void> rateStudySpot(String spotId, String userId, int rating) async {
    final ratingRef = firestore
        .collection('studySpots')
        .doc(spotId)
        .collection('ratings')
        .doc(userId);
    try {
      await ratingRef.set({
        'userId': userId,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await updateAverageRating(spotId);
    } catch (e) {
      debugPrint("Error rating Study Spot: $e");
    }
  }

  // update average rating
  Future<void> updateAverageRating(String spotId) async {
    try {
      final ratingsSnapshot = await firestore
          .collection('studySpots')
          .doc(spotId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in ratingsSnapshot.docs) {
          totalRating += doc['rating'];
        }
        double averageRating = totalRating / ratingsSnapshot.docs.length;

        await firestore.collection('studySpots').doc(spotId).update({
          'averageRating': averageRating,
        });
      }
    } catch (e) {
      debugPrint("Error updating average rating: $e");
    }
  }

  // get studySpot average rating
  Future<double> getStudySpotAverageRating(String spotId) async {
    try {
      final doc = await firestore.collection('studySpots').doc(spotId).get();
      if (doc.exists) {
        return doc.data()?['averageRating'] ?? 0.0;
      }
    } catch (e) {
      debugPrint("Error fetching Study Spot rating: $e");
    }
    return 0.0;
  }

  // get all ratings for a studySpot
  Future<List<Map<String, dynamic>>> getAllRatingsForSpot(String spotId) async {
    try {
      QuerySnapshot querySnapshot = await firestore
          .collection('studySpots')
          .doc(spotId)
          .collection('ratings')
          .get();

      List<Map<String, dynamic>> ratings = querySnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return ratings;
    } catch (e) {
      debugPrint("Error fetching Study Spot ratings: $e");
      return [];
    }
  }
}
