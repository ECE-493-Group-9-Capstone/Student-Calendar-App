import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:student_app/user_singleton.dart';
import 'package:student_app/utils/google_calendar_service.dart';
import 'package:student_app/pages/google_signin.dart';
import 'package:student_app/pages/calendar_page.dart';
import 'package:student_app/utils/social_graph.dart';
import 'package:student_app/utils/user.dart';
import 'package:student_app/utils/cache_helper.dart';
import 'package:student_app/utils/event_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LinearGradient _greenGradient = const LinearGradient(
    colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  bool _isLoadingEvents = true;
  List<gcal.Event> _todayEvents = [];
  late Future<List<UserModel>> _recommendedFriendsFuture;
  bool _isLoadingFriends = false;
  late EventService _eventService;
  late Future<List<Map<String, dynamic>>> _upcomingEventsFuture;

  @override
  void initState() {
    super.initState();
    _eventService = EventService(firestore: FirebaseFirestore.instance);
    _fetchTodayEvents();
    _recommendedFriendsFuture = _loadRecommendedFriends();
    _upcomingEventsFuture = _loadUpcomingEvents();
  }

  Future<void> _fetchTodayEvents() async {
    setState(() => _isLoadingEvents = true);
    final authService = AuthService();
    final accessToken = await authService.getAccessToken();
    if (accessToken == null) {
      setState(() => _isLoadingEvents = false);
      return;
    }
    final calendarService = GoogleCalendarService();
    final allEvents = await calendarService.fetchCalendarEvents(accessToken);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    final eventsToday = <gcal.Event>[];

    for (var event in allEvents) {
      final start = (event.start?.dateTime ?? event.start?.date)?.toLocal();
      final end = (event.end?.dateTime ?? event.end?.date)?.toLocal();
      if (start == null || end == null) continue;
      final isToday = end.isAfter(startOfToday) && start.isBefore(endOfToday);
      if (isToday) {
        eventsToday.add(event);
      }
    }

    setState(() {
      _todayEvents = eventsToday;
      _isLoadingEvents = false;
    });
  }

  String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  Widget _buildTodayEventItem(gcal.Event event) {
    final title = event.summary ?? "No Title";
    final start = (event.start?.dateTime ?? event.start?.date)?.toLocal();
    final end = (event.end?.dateTime ?? event.end?.date)?.toLocal();
    if (start == null || end == null) return const SizedBox();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: _greenGradient,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 60,
                color: const Color.fromARGB(255, 190, 190, 190),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 190, 190, 190),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${_formatTime(start)} → ${_formatTime(end)}",
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<UserModel>> _loadRecommendedFriends() async {
    setState(() => _isLoadingFriends = true);

    await AppUser.instance.refreshUserData(); // Refresh friend data
    await SocialGraph().updateGraph();

    final alreadyRequested = AppUser.instance.requestedFriends;
    final alreadyFriends = AppUser.instance.friends.map((f) => f.ccid).toList();
    final pendingRequestsToYou = AppUser.instance.friendRequests
        .map((req) => req["id"] as String)
        .toList();

    final raw = SocialGraph().getFriendRecommendations(AppUser.instance.ccid!);
    final seen = <String>{};
    final List<UserModel> unique = [];

    for (var user in raw) {
      if (!seen.contains(user.ccid) &&
          !alreadyRequested.contains(user.ccid) &&
          !alreadyFriends.contains(user.ccid) &&
          !pendingRequestsToYou.contains(user.ccid) &&
          user.ccid != AppUser.instance.ccid) {
        seen.add(user.ccid);
        unique.add(user);
      }
    }

    setState(() => _isLoadingFriends = false);
    return unique;
  }

  Widget _buildRecommendedFriendTile(UserModel user) {
    String initials = user.username
        .split(" ")
        .where((p) => p.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();
    return Container(
      width: 115,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 190, 190, 190),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.transparent,
            child: FutureBuilder<Uint8List?>(
              future: (user.photoURL?.isNotEmpty ?? false)
                  ? loadCachedImageBytes(
                      'circle_${user.photoURL!.hashCode}_80.0')
                  : Future.value(null),
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const CircularProgressIndicator(strokeWidth: 2);
                }
                final bytes = snap.data;
                if (bytes != null && bytes.isNotEmpty) {
                  return ClipOval(
                    child: Image.memory(
                      bytes,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF909533),
                  child: Text(
                    initials,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            user.ccid,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5)),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              await AppUser.instance.sendFriendRequest(user.ccid);
              setState(() {
                _recommendedFriendsFuture = _loadRecommendedFriends();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: _greenGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Add",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRecommendedFriendsHorizontal() {
    return FutureBuilder<List<UserModel>>(
      future: _recommendedFriendsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting ||
            _isLoadingFriends) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return const Text("No recommendations right now.");
        }
        final recs = snap.data!;
        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recs.length,
            itemBuilder: (context, index) {
              return _buildRecommendedFriendTile(recs[index]);
            },
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadUpcomingEvents() async {
    final now = DateTime.now();
    final in30Days = now.add(const Duration(days: 30));
    final allEvents = await _eventService.getAllEvents();
    final upcoming = <Map<String, dynamic>>[];

    for (var evt in allEvents) {
      final dateVal = evt['date'];
      if (dateVal == null) continue;
      try {
        late DateTime dt;
        if (dateVal is Timestamp) {
          dt = dateVal.toDate();
        } else {
          dt = DateTime.parse(dateVal.toString());
        }
        if (dt.isAfter(now) && dt.isBefore(in30Days)) {
          final imageUrl = evt['imageUrl'] as String? ?? '';
          if (imageUrl.isNotEmpty && imageUrl != 'No image available.') {
            upcoming.add(evt);
          }
        }
      } catch (e) {
        // If parsing fails, just skip this event
      }
    }
    return upcoming;
  }

  /// THIS METHOD NOW HANDLES TIMESTAMP/STRING DATES AND DISPLAYS ONLY THE DATE
  Widget _buildUpcomingEventCard(Map<String, dynamic> event) {
    final imageUrl = event['imageUrl'] as String? ?? '';
    final title = event['title'] as String? ?? 'Untitled Event';
    final location = event['location'] as String? ?? '';

    // Safely parse the 'date' field to a DateTime, then format
    String formattedDate = '';
    final dateVal = event['date'];
    if (dateVal != null) {
      try {
        DateTime dt;
        if (dateVal is Timestamp) {
          dt = dateVal.toDate();
        } else {
          dt = DateTime.parse(dateVal.toString());
        }
        // Format as "MMM d, yyyy" (e.g., "Apr 3, 2025")
        formattedDate = DateFormat('MMM d, yyyy').format(dt);
      } catch (_) {
        // Fallback if there's some parsing error
        formattedDate = dateVal.toString();
      }
    }

    // You can keep times as they are if they're already strings (e.g., "14:00")
    final startTime = event['start_time']?.toString() ?? '';
    final endTime = event['end_time']?.toString() ?? '';

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 190, 190, 190),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              imageUrl,
              height: 90,
              width: 180,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) {
                return Container(
                  height: 100,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "$formattedDate\n$startTime - $endTime\n$location",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsHorizontal() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _upcomingEventsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return const Text(
              "No upcoming events in the next 30 days with images.");
        }
        final events = snap.data!;
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 4),
            itemCount: events.length,
            itemBuilder: (ctx, index) {
              return _buildUpcomingEventCard(events[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildWavyHeader(Size size) {
    return ClipPath(
      clipper: _TopWaveClipper(),
      child: Container(
        height: 150,
        width: size.width,
        decoration: BoxDecoration(
          gradient: _greenGradient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = AppUser.instance.name?.split(' ').first ?? '';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF396548),
                    Color(0xFF6B803D),
                    Color(0xFF909533)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Calendar'),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _buildWavyHeader(size),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40, left: 20),
                    child: Text(
                      'Hello $firstName,',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 36, 16, 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 190, 190, 190),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GradientText(
                          "Today's Events",
                          gradient: _greenGradient,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingEvents)
                          const Center(child: CircularProgressIndicator())
                        else if (_todayEvents.isEmpty)
                          const Text(
                            "No events for today.",
                            style: TextStyle(fontSize: 16),
                          )
                        else
                          Column(
                            children:
                                _todayEvents.map(_buildTodayEventItem).toList(),
                          ),
                        const SizedBox(height: 12),
                        Center(
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CalendarPage()),
                              );
                              _fetchTodayEvents();
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "View Full Calendar",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      _greenGradient.createShader(
                                    Rect.fromLTWH(
                                        0, 0, bounds.width, bounds.height),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    size: 20,
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
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 190, 190, 190),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GradientText(
                          "Recommended Friends",
                          gradient: _greenGradient,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRecommendedFriendsHorizontal(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 190, 190, 190),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GradientText(
                          "Upcoming Events",
                          gradient: _greenGradient,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildUpcomingEventsHorizontal(),
                      ],
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

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
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
