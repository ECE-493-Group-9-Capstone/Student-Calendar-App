import 'package:flutter/material.dart';
import '../user_singleton.dart';

class UserNotificationPopup extends StatefulWidget {
  const UserNotificationPopup({super.key});

  @override
  _UserNotificationPopupState createState() => _UserNotificationPopupState();
}

class _UserNotificationPopupState extends State<UserNotificationPopup> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AppUser.instance
          .refreshUserData(), // Force refresh before showing popup
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
                  : Expanded(
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
                                    setState(() {}); // Refresh UI
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await AppUser.instance.declineFriend(id);
                                    setState(() {}); // Refresh UI
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
