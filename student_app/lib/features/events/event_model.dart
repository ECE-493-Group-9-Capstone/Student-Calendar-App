import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String startTime;
  final String endTime;
  final String location;
  final Map<String, dynamic>? coordinates;
  final String? imageUrl;
  final String? link;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.coordinates,
    this.imageUrl,
    this.link,
  });

  factory Event.fromMap(Map<String, dynamic> data, String id) => Event(
        id: id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        startDate: (data['startDate'] as Timestamp).toDate(),
        endDate: data['endDate'] != null
            ? (data['endDate'] as Timestamp).toDate()
            : null,
        startTime: data['start_time'] ?? '',
        endTime: data['end_time'] ?? '',
        location: data['location'] ?? '',
        coordinates: data['coordinates'] as Map<String, dynamic>?,
        imageUrl: data['imageUrl'] as String?,
        link: data['link'] as String?,
      );
}
