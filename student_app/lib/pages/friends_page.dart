import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:student_app/pages/friend_request_page.dart';
import '../utils/firebase_wrapper.dart';
import './user_profile_page.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  TextEditingController searchController = TextEditingController();
  List<String> allUsers = [];
  List<String> filteredUsers = [];
  List<Map<String, String>> usersFriends = []; // Store friend names + IDs

  @override
  void initState() {
    super.initState();
    fetchAndProcessUsers();
    fetchAndProcessFriends("nasreddi");
  }

  Future<void> fetchAndProcessFriends(String userId) async {
    List<String> friendNames = await getUserFriends(userId);

    // Fetch user documents to get IDs
    List<Map<String, String>> friendData = [];

    for (String friendName in friendNames) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: friendName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String friendId =
            querySnapshot.docs.first.id; // Get first matching document's ID
        friendData.add({"id": friendId, "name": friendName});
      }
    }

    setState(() {
      usersFriends = friendData; // Store as List<Map<String, String>>
    });
  }

  Future<void> fetchAndProcessUsers() async {
    List<QueryDocumentSnapshot> usernames = await getAllUsers();

    List<String> userNames = usernames
        .map((user) => (user.data() as Map<String, dynamic>)['name'] as String)
        .toList();

    allUsers = userNames;
  }

  void updateSearchResults(String query) {
    setState(() {
      filteredUsers = query.isEmpty
          ? []
          : allUsers
              .where((user) => user.toLowerCase().contains(query.toLowerCase()))
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
          child: UserNotificationPopup(userId: userId,),
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
              print("Button clicked!");
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
                  String friendName = filteredUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(friendName[0]), // First letter
                    ),
                    title: Text(friendName),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await addFriend("nasreddi", friendName);
                      },
                      child: Text("Add Friend"),
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: usersFriends.isEmpty
                  ? Center(child: Text("No Friends Yet"))
                  : ListView.builder(
                      itemCount: usersFriends.length,
                      itemBuilder: (context, index) {
                        Map<String, String> friend = usersFriends[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(friend["name"]![0]),
                          ),
                          title: Text(friend["name"]!),
                          subtitle: Text("Tap to view profile"),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => navigateToProfile(friend["id"]!),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
