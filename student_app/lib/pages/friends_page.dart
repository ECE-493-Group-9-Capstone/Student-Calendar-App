import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:student_app/utils/user.dart';
import '../user_singleton.dart';
import 'package:student_app/utils/cache_helper.dart';
import 'friend_request_page.dart';
import 'package:student_app/utils/firebase_wrapper.dart';
import 'package:student_app/pages/user_profile_page.dart';

Future<Uint8List?> downloadImageBytes(String photoURL) async {
  try {
    final response = await http.get(Uri.parse(photoURL));
    if (response.statusCode == 200) return response.bodyBytes;
  } catch (e) {
    debugPrint("Error downloading image: $e");
  }
  return null;
}

class CachedProfileImage extends StatefulWidget {
  final String? photoURL;
  final double size;
  final String? fallbackText;
  final Color? fallbackBackgroundColor;
  const CachedProfileImage({
    Key? key,
    required this.photoURL,
    this.size = 64,
    this.fallbackText,
    this.fallbackBackgroundColor,
  }) : super(key: key);

  @override
  _CachedProfileImageState createState() => _CachedProfileImageState();
}

class _CachedProfileImageState extends State<CachedProfileImage> {
  Future<Uint8List?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    if (widget.photoURL != null && widget.photoURL!.isNotEmpty) {
      _imageFuture = _getProfileImage(widget.photoURL!);
    }
  }

  Future<Uint8List?> _getProfileImage(String photoURL) async {
    final key = 'circle_${photoURL.hashCode}_${widget.size}';
    Uint8List? bytes = await loadCachedImageBytes(key);
    if (bytes != null) return bytes;
    bytes = await downloadImageBytes(photoURL);
    if (bytes != null) await cacheImageBytes(key, bytes);
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photoURL == null || widget.photoURL!.isEmpty) {
      return CircleAvatar(
        radius: widget.size / 2,
        backgroundColor: widget.fallbackBackgroundColor ?? Colors.grey,
        child: widget.fallbackText != null
            ? Text(
                widget.fallbackText!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.size / 2.5,
                ),
              )
            : null,
      );
    }
    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return ClipOval(
            child: Image.memory(
              snapshot.data!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            ),
          );
        }
        return CircleAvatar(
          radius: widget.size / 2,
          backgroundColor: widget.fallbackBackgroundColor ?? Colors.grey,
          child: widget.fallbackText != null
              ? Text(
                  widget.fallbackText!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size / 2.5,
                  ),
                )
              : null,
        );
      },
    );
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController searchController = TextEditingController();
  List<UserModel> allUsers = [];
  List<UserModel> filteredUsers = [];
  final FocusNode _focusNode = FocusNode();
  bool isSearching = false;
  int _lastRequestCount = 0;
  List<String> _requestedFriends = [];
  bool _hasLoaded = false;

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

  void _initializeNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: android, iOS: iOS),
    );
  }

  void _requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _loadUsers() async {
    await AppUser.instance.refreshUserData();
    final users = await getAllUsers();
    final friendsCcids = AppUser.instance.friends.map((f) => f.ccid).toSet();

    setState(() {
      allUsers = users
          .where((u) =>
              u.ccid != AppUser.instance.ccid && !friendsCcids.contains(u.ccid))
          .toList();

      // Remove anyone from _requestedFriends if they are now friends
      _requestedFriends.removeWhere((ccid) => friendsCcids.contains(ccid));
    });
  }

  Future<void> _loadRequestedFriends() async {
    final requested = await getRequestedFriends(AppUser.instance.ccid!);
    setState(() {
      _requestedFriends = List<String>.from(requested);
    });
  }

  void _onSearch(String query) {
    final lc = query.toLowerCase();
    final friendCcids =
        AppUser.instance.friends.map((friend) => friend.ccid).toSet();

    setState(() {
      isSearching = query.isNotEmpty;
      filteredUsers = allUsers.where((u) {
        return !friendCcids.contains(u.ccid) &&
            (u.username.toLowerCase().contains(lc) ||
                u.ccid.toLowerCase().contains(lc));
      }).toList();
    });
  }

  void _openProfile(String ccid) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: UserProfilePopup(userId: ccid), // ✅ Uses correct version now
      ),
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
      DocumentReference senderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(AppUser.instance.ccid);
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
    return Focus(
      focusNode: _focusNode,
      child: Scaffold(
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
              isSearching ? _buildSearchResults() : _buildFriendsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() => Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
              colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)]),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(13)),
          child: Row(
            children: [
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.search)),
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                      hintText: "Search for friends",
                      border: InputBorder.none),
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
    final fallbackInitials = (user.photoURL == null || user.photoURL!.isEmpty)
        ? user.username
            .split(" ")
            .where((p) => p.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          gradient: const LinearGradient(
              colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)]),
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
  final isFriend = AppUser.instance.friends
      .any((friend) => friend.ccid == user.ccid);
  final isLocallyRequested = _requestedFriends.contains(user.ccid);

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
            gradient: const LinearGradient(colors: [
              Color(0xFF396548),
              Color(0xFF6B803D),
              Color(0xFF909533)
            ]),
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
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.transparent,
                    child: FutureBuilder<Uint8List?>(
                      future: loadCachedImageBytes(
                          'circle_${user.photoURL.hashCode}_80.0'),
                      builder: (ctx, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const CircularProgressIndicator(strokeWidth: 2);
                        }
                        final bytes = snap.data;
                        if (bytes != null && bytes.isNotEmpty) {
                          return ClipOval(
                            child: Image.memory(
                              bytes,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
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
                          isFriend
                              ? "Already a friend"
                              : (isRequested
                                  ? "Request Pending..."
                                  : "Tap to add friend"),
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
    },
  );
}

}
