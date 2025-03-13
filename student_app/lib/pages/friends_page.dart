import 'package:flutter/material.dart';
import 'package:student_app/pages/friend_request_page.dart';
import 'package:student_app/utils/user.dart';
import '../utils/firebase_wrapper.dart';
import './user_profile_page.dart';
import '../user_singleton.dart';

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
  List<Map<String, String>> usersFriends = []; // Store friend names + IDs
  List<UserModel> usersFriends1 = [];

  @override
  void initState() {
    super.initState();
    fetchAndProcessUsers();
    setState(() {
      usersFriends1 = appUser.friends;
    });
  }

  Future<void> fetchAndProcessUsers() async {
    List<UserModel> users = await getAllUsers();
    List<String> friendsCcidList = [];

    for (int i = 0; i < appUser.friends.length; i++) {
      friendsCcidList.add(appUser.friends[i].ccid);
    }
    users = users
        .where((user) => user.ccid != appUser.ccid)
        .toList(); // Filter out self
    users = users
        .where((user) => !friendsCcidList.contains(user.ccid))
        .toList(); // Filter out friend

    setState(() {
      allUsers = users;
    });
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

  @override
  Widget build(BuildContext context) {
    bool isSearching = searchController.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications), // Add icon or any other icon
            onPressed: () {
              // Action when the button is clicked
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
                        if (!mounted)
                          return; // Guard against using BuildContext if not mounted.
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
              child: (usersFriends1.isEmpty)
                  ? Center(child: Text("No Friends Yet"))
                  : ListView.builder(
                      itemCount: usersFriends1.length,
                      itemBuilder: (context, index) {
                        UserModel friend = usersFriends1[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(friend.username[0]),
                          ),
                          title: Text(friend.username),
                          subtitle: Text("Tap to view profile"),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => navigateToProfile(friend.ccid),
                        );
                      },
                    ),
            )
        ],
      ),
    );
  }
}
