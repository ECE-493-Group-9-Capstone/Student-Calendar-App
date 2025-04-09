import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:student_app/utils/user.dart';
import 'package:student_app/utils/profile_picture.dart';
import 'package:student_app/utils/firebase_wrapper.dart';
import 'package:student_app/user_singleton.dart';

class FriendsProfilePopup extends StatefulWidget {
  final UserModel user;
  const FriendsProfilePopup({super.key, required this.user});

  @override
  State<FriendsProfilePopup> createState() => _FriendsProfilePopupState();
}

class _FriendsProfilePopupState extends State<FriendsProfilePopup> {
  bool isHidden = false;
  bool isLoading = false;

  // Loads the current hidden state from the current user's data.
  Future<void> _loadHiddenState() async {
    final currentUserId = AppUser.instance.ccid!;
    final myData = await fetchUserData(currentUserId);
    if (myData != null) {
      final hiddenList =
          List<String>.from(myData['location_hidden_from'] ?? []);
      setState(() {
        isHidden = hiddenList.contains(widget.user.ccid);
      });
    }
  }

  // Toggle location visibility for this friend.
  Future<void> _toggleLocationVisibility() async {
    final currentUserId = AppUser.instance.ccid!;
    setState(() => isLoading = true);
    // toggleHideLocation is assumed to update the hidden status in Firestore.
    await toggleHideLocation(currentUserId, widget.user.ccid, !isHidden);
    await _loadHiddenState(); // Refresh hidden state.
    setState(() => isLoading = false);
  }

  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  // Helper to build a circular social icon.
  Widget _buildSocialIcon(IconData iconData, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          height: 50,
          width: 50,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
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

  @override
  void initState() {
    super.initState();
    _loadHiddenState();
  }

  @override
  Widget build(BuildContext context) {
    // Prepare the URIs.
    final Uri? emailUri = (widget.user.email.isNotEmpty)
        ? Uri(scheme: 'mailto', path: widget.user.email)
        : null;
    final Uri? phoneUri =
        (widget.user.phoneNumber != null && widget.user.phoneNumber!.isNotEmpty)
            ? Uri(scheme: 'tel', path: widget.user.phoneNumber)
            : null;
    String? instagramHandle = widget.user.instagram;
    if (instagramHandle != null && instagramHandle.isNotEmpty) {
      instagramHandle = instagramHandle.replaceAll('@', '');
    }
    final Uri? instagramUri =
        (instagramHandle != null && instagramHandle.isNotEmpty)
            ? Uri.parse('https://instagram.com/$instagramHandle')
            : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Green gradient background.
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
          // White overlay container with rounded edges.
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
                    widget.user.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  // Discipline (if available).
                  if (widget.user.discipline.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.user.discipline,
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
                        _buildSocialIcon(FontAwesomeIcons.envelope,
                            () => _launchUrl(emailUri)),
                      if (phoneUri != null)
                        _buildSocialIcon(
                            FontAwesomeIcons.phone, () => _launchUrl(phoneUri)),
                      if (instagramUri != null)
                        _buildSocialIcon(FontAwesomeIcons.instagram,
                            () => _launchUrl(instagramUri)),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Overlapping avatar with eye icon overlay.
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: CachedProfileImage(
                      photoURL: widget.user.photoURL,
                      size: 72,
                      fallbackText: widget.user.username.isNotEmpty
                          ? widget.user.username.substring(0, 1).toUpperCase()
                          : '',
                      fallbackBackgroundColor: const Color(0xFF909533),
                    ),
                  ),
                  // Eye icon for toggling location visibility.
                  Positioned(
                    top: -10,
                    right: -10,
                    child: IconButton(
                      iconSize: 20,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              isHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: isHidden ? Colors.red : Colors.green,
                            ),
                      tooltip: isHidden ? 'Unhide Location' : 'Hide Location',
                      onPressed: _toggleLocationVisibility,
                    ),
                  ),
                ],
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
