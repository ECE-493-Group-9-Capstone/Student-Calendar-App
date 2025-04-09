import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_app/services/event_service.dart';
import 'package:student_app/features/events/event_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  EventsPageState createState() => EventsPageState();
}

class EventsPageState extends State<EventsPage>
    with AutomaticKeepAliveClientMixin {
  final EventService eventService =
      EventService(firestore: FirebaseFirestore.instance);
  final TextEditingController searchController = TextEditingController();

  // Define the gradient used for gradient text and borders.
  final LinearGradient _greenGradient = const LinearGradient(
    colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  List<Event> allEvents = [];
  List<Event> filteredEvents = [];
  bool isSearching = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final events = await eventService.getAllEvents();
      if (!mounted) {
        return;
      }
      setState(() {
        allEvents =
            events.map((data) => Event.fromMap(data, data['id'])).toList();
        filteredEvents = allEvents;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching events: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    final lc = query.toLowerCase();
    setState(() {
      isSearching = query.isNotEmpty;
      filteredEvents = allEvents
          .where((event) => event.title.toLowerCase().contains(lc))
          .toList();
    });
  }

  /// Returns a date string with English suffixes (e.g., "29th November, 2020").
  String _formatDateWithSuffix(DateTime date) {
    final day = date.day;
    String suffix;
    // Handle special cases for 11th, 12th, 13th.
    if (day % 100 >= 11 && day % 100 <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
          break;
        case 2:
          suffix = 'nd';
          break;
        case 3:
          suffix = 'rd';
          break;
        default:
          suffix = 'th';
      }
    }
    final monthName = DateFormat('MMMM').format(date);
    final year = date.year;
    return '$day$suffix $monthName, $year';
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      // Vertical layout as a Column (non-scrollable vertically).
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Extra top padding.
                const SizedBox(height: 0),
                // Header (green wave clipart + title).
                _buildHeader(size),
                // Extra padding between header and search bar.
                const SizedBox(height: 10),
                // Gradient search bar.
                _buildGradientSearchBar(),
                // Additional padding before events list.
                const SizedBox(height: 30),
                _buildEventsList(),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  /// Builds the header with the green wavy clipart and title.
  Widget _buildHeader(Size size) => Stack(
        children: [
          ClipPath(
            clipper: _TopWaveClipper(),
            child: Container(
              height: 150,
              width: size.width,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF396548),
                    Color(0xFF6B803D),
                    Color(0xFF909533),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 75, left: 20),
            child: Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );

  /// Builds the search bar with a gradient border.
  Widget _buildGradientSearchBar() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: _greenGradient,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Icon(Icons.search, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search for events',
                    border: InputBorder.none,
                  ),
                  onChanged: _onSearch,
                ),
              ),
            ],
          ),
        ),
      );

  /// Builds a horizontally scrolling list of event cards.
  Widget _buildEventsList() {
    if (filteredEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('No matches found')),
      );
    }
    return SizedBox(
      height: 325,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: filteredEvents.length,
        itemBuilder: (context, i) {
          final event = filteredEvents[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildEventTile(event),
          );
        },
      ),
    );
  }

  /// Builds an event card with the title first, then gradient "Date:" label, date,
  /// then location with "Location:" label and finally a "Learn More" link.
  Widget _buildEventTile(Event event) {
    final dateString = _formatDateWithSuffix(event.startDate);
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width * 0.7;
    const cardHeight = 150.0;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 70, bottom: 20),
            padding: const EdgeInsets.only(
              top: 70,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  spreadRadius: 2,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title at the top.
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                // Row with gradient "Date:" label and the date in grey.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateString,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Row with "Location:" label, icon, and location text.
                Row(
                  children: [
                    Text(
                      'Location:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // "Learn More" link with gradient text and gradient arrow.
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () async {
                      if (event.link != null && event.link!.isNotEmpty) {
                        final url = Uri.parse(event.link!);
                        if (!await launchUrl(url)) {
                          debugPrint('Could not launch URL: ${event.link}');
                        }
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GradientText(
                          text: 'Learn More',
                          gradient: _greenGradient,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              _greenGradient.createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Overlapping event image with shadow overlay.
          Positioned(
            top: 10,
            left: cardWidth * 0.1,
            right: cardWidth * 0.1,
            child: Container(
              height: cardHeight * 0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      event.imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.event,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Shadow overlay over the image.
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget to render text with a gradient color.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const GradientText({
    super.key,
    required this.text,
    required this.style,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (bounds) => gradient
            .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        child: Text(
          text,
          style: style.copyWith(color: Colors.white),
        ),
      );
}

/// Custom clipper to create the wavy header shape.
class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.8);
    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height * 0.9);
    final secondControlPoint = Offset(size.width * 0.75, size.height * 0.8);
    final secondEndPoint = Offset(size.width, size.height * 0.9);
    path.cubicTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
      secondControlPoint.dx,
      secondControlPoint.dy,
    );
    path.cubicTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_TopWaveClipper oldClipper) => false;
}
