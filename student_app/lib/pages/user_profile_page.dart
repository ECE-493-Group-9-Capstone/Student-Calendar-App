import 'package:flutter/material.dart';
import 'package:student_app/user_singleton.dart';
import '../utils/firebase_wrapper.dart';

AppUser appUser = AppUser();

class UserProfilePopup extends StatelessWidget {
  final String userId;

  const UserProfilePopup({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchUserData(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text("User not found"),
          );
        }

        Map<String, dynamic> userData = snapshot.data!;
        String name = userData["name"] ?? "Unknown";
        String bio = userData["discipline"] ?? "No bio available";
        String email = userData["email"] ?? "Unknown";
        String phoneNumber = userData["phone_number"] ?? "No phone number";
        String ccid = userId;
        String profilePic =
            userData["profilePic"] ?? "https://via.placeholder.com/150";

        return Container(
          width: 300,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(profilePic),
              ),
              SizedBox(height: 10),
              Text(
                name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                bio,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 5),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 5),
              Text(
                phoneNumber,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await removeFriendFromUsers(ccid, appUser.ccid!);
                      await AppUser.instance.refreshUserData();
                      Navigator.pop(context);
                    },
                    child: Text("Remove Friend"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
