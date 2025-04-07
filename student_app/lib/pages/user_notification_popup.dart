import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../user_singleton.dart';
import '../utils/user.dart';
import '../utils/social_graph.dart';
import 'package:student_app/utils/firebase_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:student_app/utils/profile_picture.dart';

/// Widget that shows a user's profile popup including their profile image.
class UserProfilePopup extends StatelessWidget {
  final String userId;
  const UserProfilePopup({Key? key, required this.userId}) : super(key: key);

  /// Retrieves a user's profile data.
  Future<UserModel> getUserProfile(String userId) async {
    final users = await getAllUsers();
    return users.firstWhere((u) => u.ccid == userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
      future: getUserProfile(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CachedProfileImage(
                photoURL: user.photoURL,
                size: 80,
                fallbackText: user.username
                    .split(" ")
                    .where((p) => p.isNotEmpty)
                    .map((e) => e[0])
                    .take(2)
                    .join()
                    .toUpperCase(),
                fallbackBackgroundColor: const Color(0xFF909533),
              ),
              const SizedBox(height: 16),
              Text(
                user.username,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Gradient constant for tile decorations.
const _tileGradient = LinearGradient(
  colors: [
    Color(0xFF396548),
    Color(0xFF6B803D),
    Color(0xFF909533),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// UserNotificationPopup widget that displays friend requests and friend recommendations.
class UserNotificationPopup extends StatefulWidget {
  const UserNotificationPopup({Key? key}) : super(key: key);

  @override
  _UserNotificationPopupState createState() => _UserNotificationPopupState();
}

class _UserNotificationPopupState extends State<UserNotificationPopup> {
  late Future<List<UserModel>> recommendedFriends;

  /// Initializes the recommended friends future.
  @override
  void initState() {
    super.initState();
    recommendedFriends = loadRecommendedFriends();
  }

  /// Loads recommended friends filtering out already requested or existing friends.
  Future<List<UserModel>> loadRecommendedFriends() async {
    await AppUser.instance.refreshUserData();
    await SocialGraph().updateGraph();
    List<String> alreadyRequested = AppUser.instance.requestedFriends;
    List<String> alreadyFriends = AppUser.instance.friends.map((f) => f.ccid).toList();
    List<String> pendingRequestsToYou = AppUser.instance.friendRequests
        .map((req) => req["id"] as String)
        .toList();

    List<UserModel> raw = SocialGraph().getFriendRecommendations(AppUser.instance.ccid!);
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

  /// Builds a friend request tile with profile image and action buttons.
  Widget buildFriendRequestTile(Map<String, dynamic> request) {
    String name = request["name"] ?? "Unknown";
    String id = request["id"];
    String initials = name.isNotEmpty
        ? name.split(" ").map((e) => e[0]).take(2).join().toUpperCase()
        : "?";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8).add(const EdgeInsets.only(bottom: 20)),
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
              CachedProfileImage(
                photoURL: request["photoURL"],
                size: 64,
                fallbackText: initials,
                fallbackBackgroundColor: const Color(0xFF909533),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      id,
                      style: TextStyle(
                        fontSize: 14, 
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  await AppUser.instance.addFriend(id);
                  await AppUser.instance.refreshUserData(); 
                  setState(() {
                    recommendedFriends = loadRecommendedFriends();
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
                    child: Icon(Icons.check, color: Colors.white, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                    gradient: _tileGradient,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => _tileGradient.createShader(bounds),
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

  Widget buildRecommendedFriendTile(UserModel user) {
    String initials = user.username
        .split(" ")
        .map((e) => e.isNotEmpty ? e[0] : "")
        .take(2)
        .join()
        .toUpperCase();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8).add(const EdgeInsets.only(bottom: 20)),
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
              // Use CachedProfileImage for consistent fallback behavior.
              CachedProfileImage(
                photoURL: user.photoURL,
                size: 64,
                fallbackText: initials,
                fallbackBackgroundColor: const Color(0xFF909533),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.ccid,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  await AppUser.instance.sendFriendRequest(user.ccid);
                  setState(() {
                    recommendedFriends = loadRecommendedFriends();
                  });
                },
                icon: ShaderMask(
                  shaderCallback: (bounds) => _tileGradient.createShader(bounds),
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

  /// Main build method for the notification popup showing friend requests and recommendations.
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
            List<Map<String, dynamic>> friendRequests = AppUser.instance.friendRequests;
            return Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Friend Requests",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black54),
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
                              return buildFriendRequestTile(friendRequests[index]);
                            },
                          ),
                        ),
                  const SizedBox(height: 20),
                  const Text(
                    "Friend Recommendations",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 13),
                  FutureBuilder<List<UserModel>>(
                    future: recommendedFriends,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (!snap.hasData || snap.data!.isEmpty) {
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
                            children: snap.data!.take(5).map(buildRecommendedFriendTile).toList(),
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
