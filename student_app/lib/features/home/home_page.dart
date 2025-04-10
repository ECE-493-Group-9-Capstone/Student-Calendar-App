import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:student_app/main.dart'; // For AuthWrapper
import 'package:student_app/user_singleton.dart';
import 'package:student_app/services/calendar_service.dart';
import 'package:student_app/services/auth_service.dart';
import 'package:student_app/features/calendar/calendar_page.dart';
import 'package:student_app/utils/social_graph.dart';
import 'package:student_app/utils/user_model.dart';
import 'package:student_app/utils/profile_picture_utils.dart';
import 'package:student_app/services/event_service.dart';
import 'package:student_app/features/events/event_model.dart';

// FR5 - Calendar.Sync - The system shall synchronize any modifications in the schedule with the version in the database.
// FR6 - Calendar.Modify - The system shall allow users to add, edit, or delete events in their schedules.
// FR7 - Calendar.Display - The system shall display the user’s calendar with options for interaction.
// FR16 - FriendConnect.Display - The system shall display a list of available time slots amongst friends on the calendar screen.
// FR18 - Events.Pull - The system will pull event data from the University of Alberta database and store it in the Firebase database.
// FR30 - Social.Match - The system shall list matching peers, including their contact methods and visibility status.
// FR31 - Social.Request - The system shall allow users to send connection requests via selected contact methods.
// FR37 - SocialGraph.Generate - The system shall create a social graph with users as nodes and friendships with other users as edges.
// FR38 - SocialGraph.Sync - The system shall keep the graph up to date by adding or removing nodes and edges.
// FR39 - SocialGraph.Recommend - The system shall recommend potential friends based on the user's mutual friends and/or schedules.

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
  late Future<List<Event>> _upcomingEventsFuture;
  late Timer _refreshTimer;
  final ScrollController _todayEventsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _eventService = EventService(firestore: FirebaseFirestore.instance);
    _fetchTodayEvents();
    _recommendedFriendsFuture = _loadRecommendedFriends();
    _upcomingEventsFuture = _loadUpcomingEvents();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchTodayEvents();
    });
  }

  Future<void> _fetchTodayEvents() async {
    try {
      final authService = AuthService();
      final accessToken = await authService.getAccessToken();

      if (accessToken == null) {
        setState(() => _isLoadingEvents = false);
        return;
      }

      final calendarService = CalendarService();
      final eventsToday =
          await calendarService.fetchTodayCalendarEvents(accessToken);

      if (!mounted) {
        return;
      }

      double? oldOffset;

      if (_todayEventsScrollController.hasClients) {
        oldOffset = _todayEventsScrollController.offset;
      }

      setState(() {
        _todayEvents = eventsToday;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (oldOffset != null &&
            _todayEventsScrollController.hasClients &&
            _todayEventsScrollController.position.maxScrollExtent >=
                oldOffset) {
          _todayEventsScrollController.jumpTo(oldOffset);
        }
      });
    } catch (e) {
      debugPrint("Error fetching today's events: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
    }
  }

  String _formatTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  Widget _buildTodayEventItem(gcal.Event event) {
    final title = event.summary ?? 'No Title';
    final start = (event.start?.dateTime ?? event.start?.date)?.toLocal();
    final end = (event.end?.dateTime ?? event.end?.date)?.toLocal();
    if (start == null || end == null) {
      return const SizedBox();
    }
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
                  const BoxShadow(
                    color: Color.fromARGB(255, 190, 190, 190),
                    blurRadius: 10,
                    offset: Offset(0, 4),
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
                    '${_formatTime(start)} → ${_formatTime(end)}',
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
        .map((req) => req['id'] as String)
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
    final String initials = user.username
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(8.0), // Adds padding around the entire tile
      child: Container(
        width: 115,
        margin: const EdgeInsets.only(
            right: 6), // Keeps the right margin for spacing between tiles
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            const BoxShadow(
              color: Color.fromARGB(255, 190, 190, 190),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            CachedProfileImage(
              photoURL: user.photoURL,
              size: 60,
              fallbackText: initials,
              fallbackBackgroundColor: const Color(0xFF909533),
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
              style: TextStyle(
                  fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: _greenGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Add',
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
      ),
    );
  }

  // The recommendations area always reserves a fixed height
  Widget _buildRecommendedFriendsHorizontal() => FutureBuilder<List<UserModel>>(
        future: _recommendedFriendsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting ||
              _isLoadingFriends) {
            return const SizedBox(
              height: 172,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const SizedBox(
              height: 172,
              child: Center(child: Text('No recommendations right now.')),
            );
          }
          final recs = snap.data!;
          return SizedBox(
            height: 172,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recs.length,
              itemBuilder: (context, index) =>
                  _buildRecommendedFriendTile(recs[index]),
            ),
          );
        },
      );

  Future<List<Event>> _loadUpcomingEvents() async {
    final now = DateTime.now();
    final in30Days = now.add(const Duration(days: 30));
    final allEvents = await _eventService.getAllEvents();
    final upcoming = <Event>[];

    for (var evt in allEvents) {
      final event = Event.fromMap(evt, evt['id']);
      if (event.startDate.isAfter(now) && event.startDate.isBefore(in30Days)) {
        if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
          upcoming.add(event);
        }
      }
    }
    return upcoming;
  }

  Widget _buildUpcomingEventCard(Event event) {
    final DateFormat dateFormatter = DateFormat('MMM d, yyyy');
    final DateFormat timeFormatter = DateFormat('h:mm a');
    String dateString;
    if (event.endDate != null) {
      dateString =
          '${dateFormatter.format(event.startDate)} - ${dateFormatter.format(event.endDate!)}';
    } else {
      dateString = dateFormatter.format(event.startDate);
    }

    return Padding(
      padding:
          const EdgeInsets.all(8.0), // Added padding around the entire card
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            const BoxShadow(
              color: Color.fromARGB(255, 190, 190, 190),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                event.imageUrl ?? '',
                height: 90,
                width: 180,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 90,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                event.title,
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
                "$dateString\n${timeFormatter.format(DateFormat('HH:mm').parse(event.startTime))} - ${timeFormatter.format(DateFormat('HH:mm').parse(event.endTime))}\n${event.location}",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEventsHorizontal() => FutureBuilder<List<Event>>(
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
                'No upcoming events in the next 30 days with images.');
          }
          final events = snap.data!;
          return SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 4),
              itemCount: events.length,
              itemBuilder: (ctx, index) =>
                  _buildUpcomingEventCard(events[index]),
            ),
          );
        },
      );

  Widget _buildWavyHeader(Size size) => ClipPath(
        clipper: _TopWaveClipper(),
        child: Container(
          height: 150,
          width: size.width,
          decoration: BoxDecoration(
            gradient: _greenGradient,
          ),
        ),
      );

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = AppUser.instance.name?.split(' ').first ?? '';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildWavyHeader(size),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logout Button in Top-right corner
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, right: 20),
                      child: InkWell(
                        onTap: () async {
                          await AuthService().logout();
                          AppUser.instance.logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AuthWrapper()),
                            (route) => false,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              const BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout,
                                  size: 18, color: Colors.black87),
                              SizedBox(width: 6),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Greeting
                  Padding(
                    padding: const EdgeInsets.only(top: 7, left: 20),
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
                  // "Today's Events" and other sections
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 36, 10, 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            const BoxShadow(
                              color: Color.fromARGB(255, 190, 190, 190),
                              blurRadius: 10,
                              offset: Offset(0, 4),
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
                            _isLoadingEvents
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _todayEvents.isEmpty
                                    ? const Text(
                                        'No events for today.',
                                        style: TextStyle(fontSize: 16),
                                      )
                                    : SizedBox(
                                        height: 185,
                                        child: SingleChildScrollView(
                                          controller:
                                              _todayEventsScrollController,
                                          child: Column(
                                            children: _todayEvents
                                                .map(_buildTodayEventItem)
                                                .toList(),
                                          ),
                                        ),
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
                                      'View Full Calendar',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
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
                      Positioned(
                        top: -50,
                        right: -52,
                        child: IgnorePointer(
                          child: Image.asset('assets/peaking.png', width: 400),
                        ),
                      ),
                    ],
                  ),

                  // Recommended Friends
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        const BoxShadow(
                          color: Color.fromARGB(255, 190, 190, 190),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GradientText(
                          'Recommended Friends',
                          gradient: _greenGradient,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildRecommendedFriendsHorizontal(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Upcoming Events
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        const BoxShadow(
                          color: Color.fromARGB(255, 190, 190, 190),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GradientText(
                          'Upcoming Events',
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

//----- GradientText -----//
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
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (bounds) => gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        ),
        child: Text(
          text,
          style: style?.copyWith(color: Colors.white),
        ),
      );
}

//----- Custom Clipper -----//
class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
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
