import 'package:flutter/material.dart';
import 'package:student_app/utils/study_spot_service.dart';
import 'package:student_app/user_singleton.dart';

class RatingWidget extends StatefulWidget {
  final String spotId;
  final StudySpotService service;

  const RatingWidget({
    super.key,
    required this.spotId,
    required this.service,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  double averageRating = 0.0;
  int? userRating;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    final userId = AppUser.instance.ccid;
    if (userId == null) return;

    final ratings = await widget.service.getAllRatingsForSpot(widget.spotId);
    final userEntry =
        ratings.firstWhere((r) => r['userId'] == userId, orElse: () => {});

    setState(() {
      userRating = userEntry['rating'] as int?;
    });

    final avg = await widget.service.getStudySpotAverageRating(widget.spotId);
    setState(() {
      averageRating = avg;
    });
  }

  Future<void> _submitRating(int rating) async {
    final userId = AppUser.instance.ccid;
    if (userId == null) return;

    await widget.service.rateStudySpot(widget.spotId, userId, rating);
    await _loadRatings();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Center the column content
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min, // Center the row content
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 5),
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 18), // Increased font size
              ),
            ],
          ),
          const SizedBox(height: 8), // Adjusted spacing
          Row(
            mainAxisSize: MainAxisSize.min, // Center the row content
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return IconButton(
                icon: Icon(
                  starIndex <= (userRating ?? 0)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => _submitRating(starIndex),
                tooltip: "Rate $starIndex",
              );
            }),
          ),
        ],
      ),
    );
  }
}
