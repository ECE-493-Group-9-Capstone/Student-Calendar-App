import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:student_app/utils/user.dart';
import 'package:student_app/utils/profile_picture.dart';

class FriendProfilePopup extends StatelessWidget {
  final UserModel user;
  const FriendProfilePopup({Key? key, required this.user}) : super(key: key);

  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  // Helper to build a circular social icon.
  Widget _buildSocialIcon(IconData iconData, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            iconData,
            color: Colors.grey[800],
            size: 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prepare the URIs.
    final Uri? emailUri = (user.email != null && user.email!.isNotEmpty)
        ? Uri(scheme: 'mailto', path: user.email)
        : null;
    final Uri? phoneUri = (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
        ? Uri(scheme: 'tel', path: user.phoneNumber)
        : null;
    String? instagramHandle = user.instagram;
    if (instagramHandle != null && instagramHandle.isNotEmpty) {
      instagramHandle = instagramHandle.replaceAll('@', '');
    }
    final Uri? instagramUri = (instagramHandle != null && instagramHandle.isNotEmpty)
        ? Uri.parse('https://instagram.com/$instagramHandle')
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Container(
            height: 360,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF396548),
                  Color(0xFF6B803D),
                  Color(0xFF909533),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ),
          Positioned(
            top: 130,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Friend's name.
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  // Discipline (if available).
                  if (user.discipline != null && user.discipline!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        user.discipline!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Social icons row.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (emailUri != null)
                        _buildSocialIcon(FontAwesomeIcons.envelope, () => _launchUrl(emailUri)),
                      if (phoneUri != null)
                        _buildSocialIcon(FontAwesomeIcons.phone, () => _launchUrl(phoneUri)),
                      if (instagramUri != null)
                        _buildSocialIcon(FontAwesomeIcons.instagram, () => _launchUrl(instagramUri)),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Overlapping avatar positioned near the top.
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: CachedProfileImage(
                  photoURL: user.photoURL,
                  size: 72,
                  fallbackText: user.username.isNotEmpty
                      ? user.username.substring(0, 1).toUpperCase()
                      : "",
                  fallbackBackgroundColor: const Color(0xFF909533),
                ),
              ),
            ),
          ),
          // Small white 'X' button at the top right for dismissal.
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
