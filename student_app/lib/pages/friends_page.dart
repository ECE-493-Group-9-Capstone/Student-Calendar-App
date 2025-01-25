import 'package:flutter/material.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Friends Page')),
      body: Center(
        child: Text('Welcome to the Friends Page!'),
      ),
    );
  }
}
