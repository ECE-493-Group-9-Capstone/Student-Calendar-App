import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventService {
  final FirebaseFirestore firestore;

  // allow firestore injection
  EventService({required this.firestore});

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    try {
      QuerySnapshot querySnapshot = await firestore.collection('events').get();

      List<Map<String, dynamic>> allEvents = querySnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return allEvents;
    } catch (e) {
      debugPrint("Error fetching events: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEventsByDate(DateTime date) async {
    try {
      QuerySnapshot querySnapshot = await firestore
          .collection('events')
          .where('date', isEqualTo: date)
          .get();

      List<Map<String, dynamic>> events = querySnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return events;
    } catch (e) {
      debugPrint("Error fetching events by date: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEventsByLocation(
      String location) async {
    try {
      QuerySnapshot querySnapshot = await firestore
          .collection('events')
          .where('location', isEqualTo: location)
          .get();

      List<Map<String, dynamic>> events = querySnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return events;
    } catch (e) {
      debugPrint("Error fetching events by location: $e");
      return [];
    }
  }
}
