import 'package:flutter/material.dart';
import 'package:student_app/user_singleton.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/firebase_wrapper.dart';

AppUser appUser = AppUser();

class UserProfilePopup extends StatelessWidget {
  final String userId;

  const UserProfilePopup({super.key, required this.userId});

  Future<void> _launchInstagram(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch Instagram URL');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchUserData(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("User not found"),
          );
        }

        Map<String, dynamic> userData = snapshot.data!;
        String name = userData["name"] ?? "Unknown";
        String bio = userData["discipline"] ?? "No bio available";
        String email = userData["email"] ?? "Unknown";
        String phoneNumber = userData["phone_number"] ?? "No phone number";
        String instagram = userData["instagram"] ?? "";
        String ccid = userId;
        String profilePic =
            userData["profilePic"] ?? "https://via.placeholder.com/150";

        return Container(
          width: 300,
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 10),
              Text(
                name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                bio,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 5),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 5),
              Text(
                phoneNumber,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              if (instagram.isNotEmpty) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _launchInstagram(instagram),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.link, color: Colors.deepPurple),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "View Instagram",
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                  ElevatedButton(
                    onPressed: () => removeFriendFromUsers(ccid, appUser.ccid!),
                    child: const Text("Remove Friend"),
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
