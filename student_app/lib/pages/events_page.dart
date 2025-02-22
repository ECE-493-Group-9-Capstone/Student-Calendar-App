import 'package:flutter/material.dart';
import 'package:student_app/utils/firebase_wrapper.dart';
import '../user_singleton.dart';
import '../utils/user.dart';
import '../utils/firebase_wrapper.dart';

test() async {
   AppUser user = AppUser(); // testing stuff
}

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});
  @override
  Widget build(BuildContext context) {
    test();
    return Scaffold(
      appBar: AppBar(title: Text('Events Page')),
      body: Center(
        child: Text('Welcome to the Events Page!'),
      ),
    );
  }
}
