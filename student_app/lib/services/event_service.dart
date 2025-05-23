import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// FR18 - Events.Pull - The system will pull event data from the University of Alberta database and 
// store it in the Firebase database. 
class EventService {
  final FirebaseFirestore firestore;

  // allow firestore injection
  EventService({required this.firestore});

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    try {
      final QuerySnapshot querySnapshot =
          await firestore.collection('events').get();

      final List<Map<String, dynamic>> allEvents = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return allEvents;
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  // get events by start date
  Future<List<Map<String, dynamic>>> getEventsByStartDate(
      DateTime startDate) async {
    try {
      final QuerySnapshot querySnapshot = await firestore
          .collection('events')
          .where('startDate', isEqualTo: startDate)
          .get();

      final List<Map<String, dynamic>> events = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return events;
    } catch (e) {
      debugPrint('Error fetching events by start date: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEventsByLocation(
      String location) async {
    try {
      final QuerySnapshot querySnapshot = await firestore
          .collection('events')
          .where('location', isEqualTo: location)
          .get();

      final List<Map<String, dynamic>> events = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return events;
    } catch (e) {
      debugPrint('Error fetching events by location: $e');
      return [];
    }
  }

  // edit event field
  Future<void> editEvent(String id, String field, dynamic value) async {
    try {
      await firestore.collection('events').doc(id).update({field: value});
    } catch (e) {
      debugPrint('Error editing event: $e');
    }
  }
}
