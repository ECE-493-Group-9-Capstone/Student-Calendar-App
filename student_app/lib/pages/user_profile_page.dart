import 'package:flutter/material.dart';
import 'package:student_app/user_singleton.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/firebase_wrapper.dart';

AppUser appUser = AppUser();

class UserProfilePopup extends StatefulWidget {
  final String userId;

  const UserProfilePopup({super.key, required this.userId});

  @override
  State<UserProfilePopup> createState() => _UserProfilePopupState();
}

class _UserProfilePopupState extends State<UserProfilePopup> {
  bool isHidden = false;
  Map<String, dynamic>? userData;
  bool isLoading = false;

  Future<void> _launchInstagram(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch Instagram URL');
    }
  }

  Future<void> _toggleLocationVisibility(String currentUserId) async {
    setState(() => isLoading = true);
    await toggleHideLocation(currentUserId, widget.userId, !isHidden);
    await _loadUserData(); // Re-fetch after change
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUserId = AppUser.instance.ccid!;
    final myData = await fetchUserData(currentUserId);
    final profileData = await fetchUserData(widget.userId);

    if (profileData != null && myData != null) {
      final hiddenList =
          List<String>.from(myData['location_hidden_from'] ?? []);
      setState(() {
        userData = profileData;
        isHidden = hiddenList.contains(widget.userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      );
    }

    final String name = userData!["name"] ?? "Unknown";
    final String bio = userData!["discipline"] ?? "No bio available";
    final String email = userData!["email"] ?? "Unknown";
    final String phoneNumber = userData!["phone_number"] ?? "No phone number";
    final String instagram = userData!["instagram"] ?? "";
    final String profilePic =
        userData!["profilePic"] ?? "https://via.placeholder.com/150";

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(profilePic),
              ),
              Positioned(
                top: -10,
                right: -10,
                child: IconButton(
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isHidden ? Icons.visibility_off : Icons.visibility,
                          color: isHidden ? Colors.red : Colors.green,
                          size: 20,
                        ),
                  tooltip: isHidden ? 'Unhide Location' : 'Hide Location',
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onPressed: () =>
                      _toggleLocationVisibility(AppUser.instance.ccid!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            ],
          ),
        ],
      ),
    );
  }
}
