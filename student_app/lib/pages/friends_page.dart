import 'package:flutter/material.dart';
import 'package:student_app/pages/friend_request_page.dart';
import 'package:student_app/utils/user.dart';
import '../utils/firebase_wrapper.dart';
import './user_profile_page.dart';
import '../user_singleton.dart';
import '../utils/social_graph.dart';
import '../utils/user.dart';

AppUser appUser = AppUser();

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  FriendsPageState createState() => FriendsPageState();
}

class FriendsPageState extends State<FriendsPage> {
  TextEditingController searchController = TextEditingController();
  List<UserModel> allUsers = [];
  List<UserModel> filteredUsers = [];
  List<UserModel> usersFriends1 = [];
  late Future<List<UserModel>> recommendedFriends;

  @override
  void initState() {
    super.initState();
    fetchAndProcessUsers();
    setState(() {
      usersFriends1 = appUser.friends;
    });
    recommendedFriends = loadRecommendedFriends();
  }

  Future<void> fetchAndProcessUsers() async {
    List<UserModel> users = await getAllUsers();
    List<String> friendsCcidList =
        appUser.friends.map((friend) => friend.ccid).toList();

    users = users
        .where((user) => user.ccid != appUser.ccid)
        .where((user) => !friendsCcidList.contains(user.ccid))
        .toList();

    setState(() {
      allUsers = users;
    });
  }

  Future<List<UserModel>> loadRecommendedFriends() async {
    await SocialGraph().updateGraph();
    List<String> alreadyRequested = appUser.requestedFriends;
    List<String> alreadyFriends = appUser.friends.map((f) => f.ccid).toList();
    List<UserModel> raw = SocialGraph().getFriendRecommendations(appUser.ccid!);
    final seen = <String>{};
    List<UserModel> unique = [];

    for (var user in raw) {
      if (!seen.contains(user.ccid) &&
          !alreadyRequested.contains(user.ccid) &&
          !alreadyFriends.contains(user.ccid) &&
          user.ccid != appUser.ccid) {
        seen.add(user.ccid);
        unique.add(user);
      }
    }

    return unique;
  }

  void updateSearchResults(String query) {
    setState(() {
      filteredUsers = query.isEmpty
          ? []
          : allUsers
              .where((user) =>
                  user.ccid.toLowerCase().contains(query.toLowerCase()) ||
                  user.username.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  void navigateToProfile(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: UserProfilePopup(userId: userId),
        );
      },
    );
  }

  void navigateToNotifications(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: UserNotificationPopup(),
        );
      },
    );
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
          await appUser.sendFriendRequest(user.ccid);
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
    bool isSearching = searchController.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              navigateToNotifications("nasreddi");
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for new friends...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (query) {
                setState(() {
                  updateSearchResults(query);
                });
              },
            ),
          ),
          // Conditionally show search results or friends list
          if (isSearching)
            Expanded(
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  String friendName = filteredUsers[index].username;
                  String friendCcid = filteredUsers[index].ccid;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(friendName.isNotEmpty ? friendName[0] : "?"),
                    ),
                    title: Text(friendName),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await appUser.sendFriendRequest(friendCcid);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Friend Request Sent"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text("Add Friend"),
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  // Current Friends List
                  if (usersFriends1.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text("No Friends Yet"),
                      ),
                    )
                  else
                    ...usersFriends1.map((friend) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(friend.username[0]),
                          ),
                          title: Text(friend.username),
                          subtitle: Text("Tap to view profile"),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => navigateToProfile(friend.ccid),
                        )),

                  // Divider
                  Divider(thickness: 1, height: 32),

                  // Recommended Friends Section
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "Recommended Friends",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  FutureBuilder<List<UserModel>>(
                    future: recommendedFriends,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No recommendations at this time."),
                        );
                      } else {
                        return Column(
                          children: snapshot.data!
                              .take(5) // Show top 5 recommendations
                              .map(buildRecommendedFriendTile)
                              .toList(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
