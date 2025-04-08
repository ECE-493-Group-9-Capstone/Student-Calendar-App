import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_app/utils/study_spot_service.dart';
import 'package:student_app/widgets/rating_widget.dart';

class StudySpot {
  final String id;
  final String name;
  final String imageUrl;
  final double averageRating;

  StudySpot({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.averageRating,
  });

  factory StudySpot.fromMap(Map<String, dynamic> data, String id) {
    return StudySpot(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
    );
  }
}

class StudySpotsPage extends StatefulWidget {
  const StudySpotsPage({Key? key}) : super(key: key);

  @override
  _StudySpotsPageState createState() => _StudySpotsPageState();
}

class _StudySpotsPageState extends State<StudySpotsPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController searchController = TextEditingController();
  final StudySpotService studySpotService =
      StudySpotService(firestore: FirebaseFirestore.instance);

  List<StudySpot> allStudySpots = [];
  List<StudySpot> filteredStudySpots = [];
  bool isSearching = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudySpots();
  }

  Future<void> _fetchStudySpots() async {
    try {
      final spots = await studySpotService.getAllStudySpots();
      if (!mounted) return; // Ensure the widget is still in the tree
      setState(() {
        allStudySpots =
            spots.map((data) => StudySpot.fromMap(data, data['id'])).toList();
        filteredStudySpots = allStudySpots;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching study spots: $e");
      if (!mounted) return; // Ensure the widget is still in the tree
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    final lc = query.toLowerCase();
    setState(() {
      isSearching = query.isNotEmpty;
      filteredStudySpots = allStudySpots.where((spot) {
        return spot.name.toLowerCase().contains(lc);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super.build to ensure state preservation
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(backgroundColor: Colors.white, elevation: 0),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title
                  Text(
                    isSearching ? "Search Results" : "Study Spots",
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  _buildSearchBar(),
                  const SizedBox(height: 40),
                  _buildStudySpotsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar() => Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(colors: [
            Color(0xFF396548),
            Color(0xFF6B803D),
            Color(0xFF909533)
          ]),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(13)),
          child: Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                      hintText: "Search for study spots",
                      border: InputBorder.none),
                  onChanged: _onSearch,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildStudySpotsList() {
    if (filteredStudySpots.isEmpty) {
      return const Center(child: Text('No matches found'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredStudySpots.length,
      itemBuilder: (_, i) {
        final spot = filteredStudySpots[i];
        return _buildStudySpotTile(spot);
      },
    );
  }

  Widget _buildStudySpotTile(StudySpot spot) {
    return GestureDetector(
      onTap: () => _showRatingDialog(spot),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(colors: [
              Color(0xFF396548),
              Color(0xFF6B803D),
              Color(0xFF909533)
            ]),
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(13)),
            child: Row(
              children: [
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: spot.imageUrl.isNotEmpty
                      ? Image.network(
                          spot.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey,
                            child: const Icon(Icons.image, color: Colors.white),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.menu_book,
                              color: Colors.brown, size: 40),
                        ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            spot.averageRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRatingDialog(StudySpot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            "Rate this Study Spot!",
            textAlign: TextAlign.center, // Center the text
          ),
        ),
        content: SizedBox(
          height: 100,
          child: RatingWidget(
            spotId: spot.id,
            service: studySpotService,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Re-fetch the updated study spot data
              final updatedSpotData =
                  await studySpotService.getStudySpotByName(spot.name);
              if (updatedSpotData.isNotEmpty) {
                final updatedSpot =
                    StudySpot.fromMap(updatedSpotData.first, spot.id);
                if (mounted) {
                  // Ensure the widget is still in the tree
                  setState(() {
                    // Update the specific spot in the list
                    final index =
                        allStudySpots.indexWhere((s) => s.id == spot.id);
                    if (index != -1) {
                      allStudySpots[index] = updatedSpot;
                      filteredStudySpots = isSearching
                          ? allStudySpots
                              .where((s) => s.name.toLowerCase().contains(
                                  searchController.text.toLowerCase()))
                              .toList()
                          : allStudySpots;
                    }
                  });
                }
              }
              Navigator.of(context).pop();
            },
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
