import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firebase_wrapper.dart';

class UserProfilePopup extends StatelessWidget {
  final String userId;

  const UserProfilePopup({Key? key, required this.userId}) : super(key: key);

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
        String profilePic = userData["profilePic"] ??
            "https://via.placeholder.com/150"; // Default profile image

        return Container(
          width: 300,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensure the popup isn't too large
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
