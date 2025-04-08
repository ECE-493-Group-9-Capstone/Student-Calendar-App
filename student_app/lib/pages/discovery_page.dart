import 'package:flutter/material.dart';
import 'events_page.dart';

class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar or TabBar here
      body: EventsPage(),
    );
  }
}
