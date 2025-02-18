import 'package:flutter/material.dart';
import '../utils/firebase_wrapper.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Events Page')),
      body: Center(
        child: Text('Welcome to the Events Page!'),
      ),
    );
  }
}
