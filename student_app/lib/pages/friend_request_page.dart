import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firebase_wrapper.dart';

class UserNotificationPopup extends StatelessWidget {
  final String userId; // Current user ID

  const UserNotificationPopup({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getFriendRequests(userId), // Fetch friend requests
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text("No friend requests found."),
          );
        }

        List<Map<String, dynamic>> friendRequests = snapshot.data!;

        return Container(
          width: 300,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Prevent excessive height
            children: [
              Text(
                "Friend Requests",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: friendRequests.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> request = friendRequests[index];
                    String name = request["name"] ?? "Unknown";
                    String id = request["id"];
                    String initials = name.isNotEmpty
                        ? name.split(" ").map((e) => e[0]).take(2).join().toUpperCase()
                        : "?";

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blueGrey,
                        child: Text(
                          initials,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(id),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () async {
                              await addFriend(userId, id);
                              Navigator.pop(context); // Close popup after action
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel, color: Colors.red),
                            onPressed: () async {
                              await declineFriendRequest(id, userId);
                              Navigator.pop(context); // Close popup after action
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => Navigator.pop(context), // Close popup
                child: Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }
}