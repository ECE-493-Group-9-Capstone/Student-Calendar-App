import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:student_app/pages/friend_request_page.dart';
import 'package:student_app/pages/user_profile_page.dart';
import 'package:student_app/utils/user.dart';
import '../user_singleton.dart';
import 'dart:typed_data';
import 'package:student_app/utils/cache_helper.dart';
import '../utils/firebase_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController searchController = TextEditingController();
  List<UserModel> allUsers = [];
  List<UserModel> filteredUsers = [];
  bool isSearching = false;

  int _lastRequestCount = 0;
  // List to keep track of users to whom we've sent friend requests.
  List<String> _requestedFriends = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _requestIOSPermissions();
    AppUser.instance.friendRequestsNotifier.addListener(() {
      final currentCount = AppUser.instance.friendRequestsNotifier.value.length;
      if (currentCount > _lastRequestCount) {
        flutterLocalNotificationsPlugin.show(
          0,
          'New Friend Request',
          'You have $currentCount pending request(s)',
          NotificationDetails(
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

  void _initializeNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iOS = DarwinInitializationSettings();

    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: android,
        iOS: iOS,
      ),
    );
  }

  void _requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _loadUsers() async {
    await AppUser.instance.refreshUserData();
    final users = await getAllUsers();
    final friendsCcids = AppUser.instance.friends.map((f) => f.ccid).toSet();
    setState(() {
      // Only include users who are not the current user and not already friends.
      allUsers = users
          .where((u) =>
              u.ccid != AppUser.instance.ccid && !friendsCcids.contains(u.ccid))
          .toList();
    });
  }

  Future<void> _loadRequestedFriends() async {
    final requested = await getRequestedFriends(AppUser.instance.ccid!);

    // If your firebase utility returns a list of friend IDs, you can directly use it.
    // Otherwise, you might need to map the returned list to a list of IDs.
    setState(() {
      _requestedFriends = List<String>.from(requested);
    });
  }

  void _onSearch(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      filteredUsers = allUsers.where((u) {
        final lc = query.toLowerCase();
        return u.username.toLowerCase().contains(lc) ||
            u.ccid.toLowerCase().contains(lc);
      }).toList();
    });
  }

  void _openProfile(String ccid) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: UserProfilePopup(userId: ccid),
      ),
    );
  }

  Future<void> _removeFriend(String ccid) async {
    await AppUser.instance.removeFriend(ccid);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Friend removed')));
  }

  Future<void> _sendFriendRequest(String ccid) async {
    // Send friend request via your firebase utility
    await AppUser.instance.sendFriendRequest(ccid);
    setState(() {
      _requestedFriends.add(ccid);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Friend request sent')));
  }

  Future<void> _cancelFriendRequest(String ccid) async {
    try {
      // Remove from current user's requested_friends list
      DocumentReference senderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(AppUser.instance.ccid);
      // Remove current user from the other user's friend_requests list
      DocumentReference receiverRef =
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
      debugPrint("Error canceling friend request: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(backgroundColor: Colors.white, elevation: 0),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and notification icon.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isSearching ? "Add Friends" : "Your Friends",
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold)),
                ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: AppUser.instance.friendRequestsNotifier,
                  builder: (_, requests, __) {
                    final hasRequests = requests.isNotEmpty;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FriendRequestPage()),
                      ),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [
                                Color(0xFF396548),
                                Color(0xFF6B803D),
                                Color(0xFF909533),
                              ]),
                            ),
                            child: const Icon(Icons.notifications,
                                color: Colors.white),
                          ),
                          if (hasRequests)
                            const Positioned(
                              right: 4,
                              top: 4,
                              child: CircleAvatar(
                                  radius: 6, backgroundColor: Colors.red),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildSearchBar(),
            const SizedBox(height: 40),
            // Conditionally display search results or the friends list.
            isSearching ? _buildSearchResults() : _buildFriendsList(),
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
                      hintText: "Search for friends", border: InputBorder.none),
                  onChanged: _onSearch,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFriendsList() {
    return ValueListenableBuilder<List<UserModel>>(
      valueListenable: AppUser.instance.friendsNotifier,
      builder: (_, friends, __) {
        if (friends.isEmpty) {
          return const Center(child: Text('No friends yet'));
        }
        return SizedBox(
          height: MediaQuery.of(context).size.height - 250,
          child: ListView.builder(
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
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (filteredUsers.isEmpty) {
      return const Center(child: Text('No matches'));
    }
    return SizedBox(
      height: MediaQuery.of(context).size.height - 250,
      child: ListView.builder(
        itemCount: filteredUsers.length,
        itemBuilder: (_, i) {
          final user = filteredUsers[i];
          return _buildSearchResultTile(user);
        },
      ),
    );
  }

  Widget _buildFriendTile(UserModel user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          gradient: const LinearGradient(colors: [
            Color(0xFF396548),
            Color(0xFF6B803D),
            Color(0xFF909533)
          ]),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(30)),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => _openProfile(user.ccid),
            child: Row(
              children: [
                const SizedBox(width: 20),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.transparent,
                  child: FutureBuilder<Uint8List?>(
                    future: loadCachedImageBytes(
                        'circle_${user.photoURL.hashCode}_80.0'),
                    builder: (ctx, snap) {
                      if (snap.connectionState != ConnectionState.done)
                        return const CircularProgressIndicator(strokeWidth: 2);
                      final bytes = snap.data;
                      if (bytes != null && bytes.isNotEmpty) {
                        return ClipOval(
                          child: Image.memory(bytes,
                              width: 64, height: 64, fit: BoxFit.cover),
                        );
                      }
                      return const CircleAvatar(
                        radius: 32,
                        backgroundImage:
                            AssetImage('assets/default_avatar.png'),
                      );
                    },
                  ),
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
                      const Text("Tap to view profile",
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          gradient: const LinearGradient(colors: [
            Color(0xFF396548),
            Color(0xFF6B803D),
            Color(0xFF909533)
          ]),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(30)),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            // If a request has been sent already, tapping the icon will cancel it;
            // otherwise, it sends a friend request.
            onTap: () {
              if (_requestedFriends.contains(user.ccid)) {
                _cancelFriendRequest(user.ccid);
              } else {
                _sendFriendRequest(user.ccid);
              }
            },
            child: Row(
              children: [
                const SizedBox(width: 20),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.transparent,
                  child: FutureBuilder<Uint8List?>(
                    future: loadCachedImageBytes(
                        'circle_${user.photoURL.hashCode}_80.0'),
                    builder: (ctx, snap) {
                      if (snap.connectionState != ConnectionState.done)
                        return const CircularProgressIndicator(strokeWidth: 2);
                      final bytes = snap.data;
                      if (bytes != null && bytes.isNotEmpty) {
                        return ClipOval(
                          child: Image.memory(bytes,
                              width: 64, height: 64, fit: BoxFit.cover),
                        );
                      }
                      return const CircleAvatar(
                        radius: 32,
                        backgroundImage:
                            AssetImage('assets/default_avatar.png'),
                      );
                    },
                  ),
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
                        _requestedFriends.contains(user.ccid)
                            ? "Request Pending..."
                            : "Tap to add friend",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                // Icon changes based on friend request status.
                (_requestedFriends.contains(user.ccid))
                    ? IconButton(
                        icon: const Icon(Icons.hourglass_empty),
                        onPressed: () => _cancelFriendRequest(user.ccid),
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
  }
}
