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
}
