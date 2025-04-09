import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EventPopup extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback? onMoreInfo; // You can keep this if needed elsewhere

  const EventPopup({
    super.key,
    required this.event,
    this.onMoreInfo,
  });

  String? _prepareImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return 'https://$url';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.9;
    final dialogHeight = screenSize.height * 0.65;

    final dynamic dateValue = event['startDate'];
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
    final formattedStart =
        DateFormat('h:mma').format(parsedStart).toLowerCase();
    final formattedEnd = DateFormat('h:mma').format(parsedEnd).toLowerCase();

    final String? rawImageUrl = event['imageUrl'] as String?;
    final String? imageUrl = _prepareImageUrl(rawImageUrl);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF396548),
                Color(0xFF6B803D),
                Color(0xFF909533),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            elevation: 2,
            borderRadius: BorderRadius.circular(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (imageUrl != null)
                      SizedBox(
                        height: dialogHeight * 0.40,
                        width: double.infinity,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'] ?? 'Event Title',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: 'Date:',
                            value: formattedDate,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Time:',
                            value: '$formattedStart - $formattedEnd',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // More Info button has been removed.
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
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
