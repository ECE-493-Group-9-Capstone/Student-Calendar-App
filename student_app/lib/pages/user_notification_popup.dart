import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../user_singleton.dart';
import '../utils/user.dart';
import '../utils/social_graph.dart';
import '../utils/cache_helper.dart'; // Ensure this provides loadCachedImageBytes
// Adjust the path if needed

class UserNotificationPopup extends StatefulWidget {
  const UserNotificationPopup({super.key});

  @override
  _UserNotificationPopupState createState() => _UserNotificationPopupState();
}

class _UserNotificationPopupState extends State<UserNotificationPopup> {
  late Future<List<UserModel>> recommendedFriends;

  @override
  void initState() {
    super.initState();
    recommendedFriends = loadRecommendedFriends();
  }

  Future<List<UserModel>> loadRecommendedFriends() async {
    await AppUser.instance.refreshUserData();
    await SocialGraph().updateGraph();

    List<String> alreadyRequested = AppUser.instance.requestedFriends;
    List<String> alreadyFriends =
        AppUser.instance.friends.map((f) => f.ccid).toList();
    List<String> pendingRequestsToYou = AppUser.instance.friendRequests
        .map((req) => req["id"] as String)
        .toList();

    List<UserModel> raw =
        SocialGraph().getFriendRecommendations(AppUser.instance.ccid!);

    final seen = <String>{};
    List<UserModel> unique = [];

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

    return unique;
  }

  // Gradient used for both tile types.
  static const _tileGradient = LinearGradient(
    colors: [
      Color(0xFF396548),
      Color(0xFF6B803D),
      Color(0xFF909533),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Friend Request Tile with gradient border, inner white container, and horizontal padding.
  Widget buildFriendRequestTile(Map<String, dynamic> request) {
    String name = request["name"] ?? "Unknown";
    String id = request["id"];
    String initials = name.isNotEmpty
        ? name.split(" ").map((e) => e[0]).take(2).join().toUpperCase()
        : "?";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8)
          .add(const EdgeInsets.only(bottom: 20)),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          gradient: _tileGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              // Custom Profile Picture for Friend Request:
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.transparent,
                child: FutureBuilder<Uint8List?>(
                  future: (request["photoURL"]?.toString().isNotEmpty ?? false)
                      ? loadCachedImageBytes(
                          'circle_${request["photoURL"].hashCode}_80.0')
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
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.blueGrey,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
                    // Username text with ellipsis
                    Text(
                      name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      id,
                      style: TextStyle(
                          fontSize: 14, color: Colors.black.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              // Extra space between name and action buttons.
              const SizedBox(width: 16),
              // Accept Button: White check icon on gradient background.
              GestureDetector(
                onTap: () async {
                  await AppUser.instance.addFriend(id);
                  await AppUser.instance
                      .refreshUserData(); 
                  setState(() {
                    recommendedFriends =
                        loadRecommendedFriends();
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _tileGradient,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Decline Button: White circle with gradient border and gradient x icon.
              GestureDetector(
                onTap: () async {
                  await AppUser.instance.declineFriend(id);
                  setState(() {});
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _tileGradient, // Border color.
                  ),
                  padding: const EdgeInsets.all(2), // Border thickness.
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white, // White background.
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            _tileGradient.createShader(bounds),
                        child: const Icon(
                          Icons.close,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  // Friend Recommendation Tile remains unchanged.
  Widget buildRecommendedFriendTile(UserModel user) {
    String initials = user.username
        .split(" ")
        .map((e) => e.isNotEmpty ? e[0] : "")
        .take(2)
        .join()
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8)
          .add(const EdgeInsets.only(bottom: 20)),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          gradient: _tileGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              // Custom Profile Picture for Friend Recommendation:
              CircleAvatar(
                radius: 32,
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
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        initials,
                        style: const TextStyle(color: Colors.white),
                      ),
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
                    // Username text with ellipsis
                    Text(
                      user.username,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.ccid,
                      style: TextStyle(
                          fontSize: 14, color: Colors.black.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              // "Add" Icon Button (existing design)
              IconButton(
                onPressed: () async {
                  await AppUser.instance.sendFriendRequest(user.ccid);
                  setState(() {
                    recommendedFriends = loadRecommendedFriends();
                  });
                },
                icon: ShaderMask(
                  shaderCallback: (bounds) =>
                      _tileGradient.createShader(bounds),
                  child: const Icon(
                    Icons.add,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double sectionHeight = MediaQuery.of(context).size.height / 3;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder(
          future: AppUser.instance.refreshUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            List<Map<String, dynamic>> friendRequests =
                AppUser.instance.friendRequests;

            return Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row with Title
                  const Text(
                    "Friend Requests",
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54),
                  ),
                  const SizedBox(height: 13),
                  friendRequests.isEmpty
                      ? SizedBox(
                          height: sectionHeight,
                          child: Center(
                            child: Text(
                              "No friend requests found.",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: sectionHeight,
                          child: ListView.builder(
                            itemCount: friendRequests.length,
                            itemBuilder: (context, index) {
                              return buildFriendRequestTile(
                                  friendRequests[index]);
                            },
                          ),
                        ),
                  const SizedBox(height: 20),
                  // Friend Recommendations Section
                  const Text(
                    "Friend Recommendations",
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54),
                  ),
                  const SizedBox(height: 13),
                  FutureBuilder<List<UserModel>>(
                    future: recommendedFriends,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return SizedBox(
                          height: sectionHeight,
                          child: Center(
                            child: Text(
                              "No recommendations right now.",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        );
                      } else {
                        return SizedBox(
                          height: sectionHeight,
                          child: ListView(
                            children: snapshot.data!
                                .take(5)
                                .map(buildRecommendedFriendTile)
                                .toList(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
