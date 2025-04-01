import 'package:flutter/material.dart';
import 'user_notification_popup.dart'; // adjust path if needed

class FriendRequestPage extends StatelessWidget {
  const FriendRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        backgroundColor: const Color(0xFF396548),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: const UserNotificationPopup(),
        ),
      ),
    );
  }
}
