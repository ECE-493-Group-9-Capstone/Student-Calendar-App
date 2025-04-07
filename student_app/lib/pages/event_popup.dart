// event_popup.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EventPopup extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback? onMoreInfo; // Callback for the arrow button

  const EventPopup({Key? key, required this.event, this.onMoreInfo})
      : super(key: key);

  /// Validate and prepare the image URL. If the URL is missing a scheme or host,
  /// prepend "https://". If no URL is provided, return null.
  String? _prepareImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    // If missing scheme or host, prepend "https://"
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return "https://$url";
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    // Parse the event date.
    final dynamic dateValue = event['date'];
    DateTime eventDate;
    try {
      eventDate = dateValue is Timestamp
          ? dateValue.toDate()
          : DateTime.parse(dateValue.toString());
    } catch (e) {
      debugPrint('Error parsing event date: $e');
      eventDate = DateTime.now();
    }
    final String formattedDate = DateFormat('MMMM dd, yyyy').format(eventDate);

    // Parse the start and end times.
    final startTimeStr = event['start_time'] ?? '00:00:00';
    final endTimeStr = event['end_time'] ?? '00:00:00';
    DateTime parsedStart;
    DateTime parsedEnd;
    try {
      parsedStart = DateFormat('HH:mm:ss').parse(startTimeStr);
      parsedEnd = DateFormat('HH:mm:ss').parse(endTimeStr);
    } catch (e) {
      debugPrint('Error parsing event times: $e');
      parsedStart = DateTime(0);
      parsedEnd = DateTime(0);
    }
    if (parsedEnd.isBefore(parsedStart)) {
      parsedEnd = parsedEnd.add(const Duration(days: 1));
    }
    final formattedStart = DateFormat('h:mma').format(parsedStart).toLowerCase();
    final formattedEnd = DateFormat('h:mma').format(parsedEnd).toLowerCase();

    // Prepare the image URL.
    final String? rawImageUrl = event['imageUrl'] as String?;
    final String? imageUrl = _prepareImageUrl(rawImageUrl);

    return Container(
      width: 380, // Slightly wider
      height: 420, // Slightly taller
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // Outer gradient border
        gradient: const LinearGradient(
          colors: [
            Color(0xFF396548),
            Color(0xFF6B803D),
            Color(0xFF909533),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        // Add some outer shadow for a subtle raised look
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        // Use Material to allow Card-like effect
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // If we have a valid image URL, display it — but hide on error.
                if (imageUrl != null) 
                  Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Hide the image if it fails to load
                      return const SizedBox.shrink();
                    },
                  ),
                const SizedBox(height: 10),
                // Content area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Title (always shown, even if no image)
                      Text(
                        event['title'] ?? 'Event Title',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: "Date:",
                        value: formattedDate,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: "Time:",
                        value: "$formattedStart - $formattedEnd",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Button row at the bottom
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onMoreInfo,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text("More Info"),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF396548),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small helper widget that displays a label and a value in a row.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
