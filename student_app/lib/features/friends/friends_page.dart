import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_app/utils/user_model.dart';
import '../../user_singleton.dart';
import 'friends_request_page.dart';
import 'package:student_app/services/firebase_service.dart';
import 'package:student_app/features/friends/friends_profile_popup.dart';
import 'package:student_app/utils/profile_picture_utils.dart';

// FR10 - Friends.Display - The system shall display a list of friends and friend groups.
// FR11 - Friends.Modify - The system shall allow users to add or remove friends.
// FR12 - Friends.Requests - The system shall display pending friend requests.
// FR14 - Friends.Filter - The system shall filter the friend's list based on filter text input.
// FR15 - Friends.Search - The system shall search the University of Alberta database for students matching the search input.

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});
  @override
  FriendsPageState createState() => FriendsPageState();
}

class FriendsPageState extends State<FriendsPage> {
  final TextEditingController searchController = TextEditingController();
  List<UserModel> allUsers = [];
  List<UserModel> filteredUsers = [];
  final FocusNode _focusNode = FocusNode();
  bool isSearching = false;
  int _lastRequestCount = 0;
  List<String> _requestedFriends = [];
  bool _hasLoaded = false;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Define the green gradient to reuse (same as in EventsPage)
  final LinearGradient _greenGradient = const LinearGradient(
    colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _loadUsers();
      _loadRequestedFriends();
      _hasLoaded = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _initializeNotifications();
    _requestIOSPermissions();
    AppUser.instance.friendRequestsNotifier.addListener(() {
      final currentCount = AppUser.instance.friendRequestsNotifier.value.length;
      if (currentCount > _lastRequestCount) {
        flutterLocalNotificationsPlugin.show(
          0,
          'New Friend Request',
          'You have $currentCount pending request(s)',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'friend_requests',
              'Friend Requests',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
      _lastRequestCount = currentCount;
    });
    _loadUsers();
    _loadRequestedFriends();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _loadUsers();
      _loadRequestedFriends();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('app_icon');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  void _requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _loadUsers() async {
    await AppUser.instance.refreshUserData();
    final users = await firebaseService.getAllUsers();
    final friendsCcids = AppUser.instance.friends.map((f) => f.ccid).toSet();
    setState(() {
      allUsers = users
          .where((u) =>
              u.ccid != AppUser.instance.ccid && !friendsCcids.contains(u.ccid))
          .toList();
      _requestedFriends.removeWhere((ccid) => friendsCcids.contains(ccid));
    });
  }

  Future<void> _loadRequestedFriends() async {
    try {
      final requested = await firebaseService
          .getRequestedFriends(AppUser.instance.ccid ?? '');
      setState(() {
        _requestedFriends = List<String>.from(requested);
      });
    } catch (e) {
      debugPrint('Error loading requested friends: $e');
    }
  }

  void _onSearch(String query) {
    final lc = query.toLowerCase();
    final friendCcids =
        AppUser.instance.friends.map((friend) => friend.ccid).toSet();
    setState(() {
      isSearching = query.isNotEmpty;
      filteredUsers = allUsers
          .where((u) =>
              !friendCcids.contains(u.ccid) &&
              (u.username.toLowerCase().contains(lc) ||
                  u.ccid.toLowerCase().contains(lc)))
          .toList();
    });
  }

  void _openProfile(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => FriendsProfilePopup(user: user),
    );
  }

  Future<void> _removeFriend(String ccid) async {
    await AppUser.instance.removeFriend(ccid);
    await AppUser.instance.refreshUserData();
    await _loadUsers();
    await _loadRequestedFriends();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Friend removed')));
  }

  Future<void> _sendFriendRequest(String ccid) async {
    await AppUser.instance.sendFriendRequest(ccid);
    setState(() {
      _requestedFriends.add(ccid);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Friend request sent')));
  }

  Future<void> _cancelFriendRequest(String ccid) async {
    try {
      final DocumentReference senderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(AppUser.instance.ccid);
      final DocumentReference receiverRef =
          FirebaseFirestore.instance.collection('users').doc(ccid);
      await senderRef.update({
        'requested_friends': FieldValue.arrayRemove([ccid])
      });
      await receiverRef.update({
        'friend_requests': FieldValue.arrayRemove([AppUser.instance.ccid])
      });
      setState(() {
        _requestedFriends.remove(ccid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request canceled')));
    } catch (e) {
      debugPrint('Error canceling friend request: $e');
    }
  }

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
          Padding(
            padding: const EdgeInsets.only(top: 75, left: 20),
            child: Text(
              isSearching ? 'Add Friends' : 'Your Friends',
              style: const TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: AppUser.instance.friendRequestsNotifier,
              builder: (_, requests, __) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FriendsRequestPage(),
                  ),
                ),
                child: const Icon(
                  Icons.notifications,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );

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
                    hintText: 'Search for friends',
                    border: InputBorder.none,
                  ),
                  onChanged: _onSearch,
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
   
    return Focus(
      focusNode: _focusNode,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(size),
            const SizedBox(height: 10),
            _buildGradientSearchBar(),
            const SizedBox(height: 0),
            Expanded(
              child: isSearching ? _buildSearchResults() : _buildFriendsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() => ValueListenableBuilder<List<UserModel>>(
        valueListenable: AppUser.instance.friendsNotifier,
        builder: (_, friends, __) {
          if (friends.isEmpty) {
            return const Center(child: Text('No friends yet'));
          }
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (_, i) {
              final user = friends[i];
              return Dismissible(
                key: ValueKey(user.ccid),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(33)),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _removeFriend(user.ccid),
                child: _buildFriendTile(user),
              );
            },
          );
        },
      );

  Widget _buildSearchResults() {
    if (filteredUsers.isEmpty) {
      return const Center(child: Text('No matches'));
    }
    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (_, i) {
        final user = filteredUsers[i];
        return _buildSearchResultTile(user);
      },
    );
  }

  Widget _buildFriendTile(UserModel user) {
    final fallbackInitials = (user.photoURL == null || user.photoURL!.isEmpty)
        ? user.username
            .split(' ')
            .where((p) => p.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          gradient: _greenGradient,
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(30)),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => _openProfile(user),
            child: Row(
              children: [
                const SizedBox(width: 20),
                CachedProfileImage(
                  photoURL: user.photoURL,
                  size: 64,
                  fallbackText: fallbackInitials,
                  fallbackBackgroundColor: const Color(0xFF909533),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      const Text('Tap to view profile',
                          style:
                              TextStyle(fontSize: 14, color: Colors.black54)),
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

  Widget _buildSearchResultTile(UserModel user) {
    final isFriend =
        AppUser.instance.friends.any((friend) => friend.ccid == user.ccid);
    final isLocallyRequested = _requestedFriends.contains(user.ccid);
    final fallbackInitials = (user.photoURL == null || user.photoURL!.isEmpty)
        ? user.username
            .split(' ')
            .where((p) => p.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : null;

    return FutureBuilder<DocumentSnapshot>(
      future: isLocallyRequested
          ? null
          : FirebaseFirestore.instance
              .collection('users')
              .doc(AppUser.instance.ccid)
              .get(),
      builder: (context, snapshot) {
        bool isRequested = isLocallyRequested;
        if (!isLocallyRequested &&
            snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final firebaseRequested =
              List<String>.from(data['requested_friends'] ?? []);
          isRequested = firebaseRequested.contains(user.ccid);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(33),
              gradient: _greenGradient,
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  if (isFriend) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Already a friend')),
                    );
                    return;
                  }
                  if (isRequested) {
                    _cancelFriendRequest(user.ccid);
                  } else {
                    _sendFriendRequest(user.ccid);
                  }
                },
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    CachedProfileImage(
                      photoURL: user.photoURL,
                      size: 64,
                      fallbackText: fallbackInitials,
                      fallbackBackgroundColor: const Color(0xFF909533),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.username,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(
                            isFriend
                                ? 'Already a friend'
                                : (isRequested
                                    ? 'Request Pending...'
                                    : 'Tap to add friend'),
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    isFriend
                        ? const Icon(Icons.check, color: Colors.green)
                        : isRequested
                            ? IconButton(
                                icon: const Icon(Icons.hourglass_empty),
                                onPressed: () =>
                                    _cancelFriendRequest(user.ccid),
                              )
                            : IconButton(
                                icon: const Icon(Icons.person_add),
                                onPressed: () => _sendFriendRequest(user.ccid),
                              ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom clipper to create the wavy header shape (same as used in EventsPage)
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
