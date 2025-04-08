import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:ui';

import 'package:student_app/utils/study_spot_service.dart';
import 'package:student_app/user_singleton.dart';

class StudySpotPopup extends StatefulWidget {
  final Map<String, dynamic> studySpot;
  final VoidCallback? onMoreInfo; // Optional callback for additional actions

  const StudySpotPopup({
    Key? key,
    required this.studySpot,
    this.onMoreInfo,
  }) : super(key: key);

  @override
  _StudySpotPopupState createState() => _StudySpotPopupState();
}

class _StudySpotPopupState extends State<StudySpotPopup> {
  // We'll store the average rating and the user's existing rating.
  double _averageRating = 0.0;
  int? _userRating;
  bool _isSubmitting = false;
  String? _errorMessage;

  final StudySpotService _studySpotService =
      StudySpotService(firestore: FirebaseFirestore.instance);

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  /// Loads the overall average rating and the current user’s rating from Firestore.
  Future<void> _loadRatings() async {
    final userId = AppUser.instance.ccid;
    if (userId == null) return;

    try {
      final ratings = await _studySpotService.getAllRatingsForSpot(widget.studySpot['id']);
      final userEntry = ratings.firstWhere((r) => r['userId'] == userId, orElse: () => {});
      setState(() {
        _userRating = userEntry['rating'] as int?;
      });

      final avg = await _studySpotService.getStudySpotAverageRating(widget.studySpot['id']);
      setState(() {
        _averageRating = avg;
      });
      debugPrint("Loaded ratings: userRating=$_userRating, averageRating=$_averageRating");
    } catch (e, stackTrace) {
      debugPrint("Error loading ratings: $e");
      debugPrint("StackTrace: $stackTrace");
      setState(() {
        _errorMessage = "Error loading ratings.";
      });
    }
  }

  /// Submits a rating for the study spot using the service.
  Future<void> _submitRating(int rating) async {
    final userId = AppUser.instance.ccid;
    if (userId == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      debugPrint("Submitting rating: $rating for studySpot ID: ${widget.studySpot['id']}");
      await _studySpotService.rateStudySpot(widget.studySpot['id'], userId, rating);
      debugPrint("Rating submitted successfully.");
      await _loadRatings(); // Reload ratings to update the UI.
    } catch (e, stackTrace) {
      debugPrint("Error submitting rating: $e");
      debugPrint("StackTrace: $stackTrace");
      setState(() {
        _errorMessage = "Error submitting rating. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Builds the rating display and star selection row.
  Widget _buildRatingSection() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Center the content vertically
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Display the overall average rating.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 5),
              Text(
                _averageRating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Display the row of clickable stars.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return IconButton(
                icon: Icon(
                  starIndex <= (_userRating ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: _isSubmitting
                    ? null
                    : () {
                        debugPrint("Star pressed. Submitting rating: $starIndex");
                        _submitRating(starIndex);
                      },
                tooltip: "Rate $starIndex",
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Increase popup dimensions by adjusting the multipliers.
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = 400.0;  // fixed width for the popup
    final dialogHeight = screenSize.height * 0.75;  // slightly taller than before

    // Extract study spot details.
    final String name = widget.studySpot['name'] ?? 'Study Spot';
    final String? description = widget.studySpot['description'];
    // We'll not rely on the passed averageRating; instead we'll use _averageRating from _loadRatings.
    final String formattedAverageRating = _averageRating.toStringAsFixed(1);

    // Prepare the image URL, ensuring it is fully qualified.
    final String? rawImageUrl = widget.studySpot['imageUrl'] as String?;
    String? imageUrl;
    if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
      final uri = Uri.tryParse(rawImageUrl);
      if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
        imageUrl = "https://$rawImageUrl";
      } else {
        imageUrl = rawImageUrl;
      }
      debugPrint("Parsed imageUrl: $imageUrl");
    }

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
                color: Colors.black.withOpacity(0.3),
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
                    // Display the study spot image (if available).
                    if (imageUrl != null)
                      SizedBox(
                        height: dialogHeight * 0.40,
                        width: double.infinity,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) {
                            debugPrint("Error loading image: $err");
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Study Spot Name
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          // Display the average rating alongside the label (optional)
                          _InfoRow(
                            label: "Average Rating:",
                            value: formattedAverageRating,
                          ),
                          const SizedBox(height: 10),
                          // Optional Description.
                          if (description != null && description.isNotEmpty) ...[
                            _InfoRow(
                              label: "Description:",
                              value: description,
                            ),
                            const SizedBox(height: 10),
                          ],
                          const Divider(),
                          const SizedBox(height: 10),
                          // Rating Section (shows current average and allows star selection).
                          _buildRatingSection(),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          // (No checkmark icon is shown here.)
                        ],
                      ),
                    ),
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

/// A reusable widget for displaying a label and its associated value.
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
