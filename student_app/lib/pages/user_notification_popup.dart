import 'package:flutter/material.dart';
import '../user_singleton.dart';
import '../utils/user.dart';
import '../utils/social_graph.dart';

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
    await SocialGraph().updateGraph();

    List<String> alreadyRequested = AppUser.instance.requestedFriends;
    List<String> alreadyFriends =
        AppUser.instance.friends.map((f) => f.ccid).toList();

    List<UserModel> raw =
        SocialGraph().getFriendRecommendations(AppUser.instance.ccid!);

    final seen = <String>{};
    List<UserModel> unique = [];

    for (var user in raw) {
      if (!seen.contains(user.ccid) &&
          !alreadyRequested.contains(user.ccid) &&
          !alreadyFriends.contains(user.ccid) &&
          user.ccid != AppUser.instance.ccid) {
        seen.add(user.ccid);
        unique.add(user);
      }
    }

    return unique;
  }

  Widget buildRecommendedFriendTile(UserModel user) {
    String initials = user.username
        .split(" ")
        .map((e) => e.isNotEmpty ? e[0] : "")
        .take(2)
        .join()
        .toUpperCase();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.deepPurple,
        child: Text(initials, style: TextStyle(color: Colors.white)),
      ),
      title: Text(user.username),
      subtitle: Text(user.ccid),
      trailing: ElevatedButton(
        onPressed: () async {
          await AppUser.instance.sendFriendRequest(user.ccid);
          setState(() {
            recommendedFriends = loadRecommendedFriends();
          });
        },
        child: Text("Add"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AppUser.instance.refreshUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        List<Map<String, dynamic>> friendRequests =
            AppUser.instance.friendRequests;

        return Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Friend Requests",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              friendRequests.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No friend requests found."),
                    )
                  : SizedBox(
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: friendRequests.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> request = friendRequests[index];
                          String name = request["name"] ?? "Unknown";
                          String id = request["id"];
                          String initials = name.isNotEmpty
                              ? name
                                  .split(" ")
                                  .map((e) => e[0])
                                  .take(2)
                                  .join()
                                  .toUpperCase()
                              : "?";

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blueGrey,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(id),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle,
                                      color: Colors.green),
                                  onPressed: () async {
                                    await AppUser.instance.addFriend(id);
                                    setState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await AppUser.instance.declineFriend(id);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 20),
              const Divider(thickness: 1),
              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Text(
                  "Recommended Friends",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              FutureBuilder<List<UserModel>>(
                future: recommendedFriends,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("No recommendations right now."),
                    );
                  } else {
                    return SizedBox(
                      height: 200,
                      child: ListView(
                        shrinkWrap: true,
                        children: snapshot.data!
                            .take(5)
                            .map(buildRecommendedFriendTile)
                            .toList(),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }
}
