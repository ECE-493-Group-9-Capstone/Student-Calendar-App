import 'package:flutter/material.dart';
import 'events_page.dart';
import 'study_spots_page.dart';

class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Discovery'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Study Spots'),
              Tab(text: 'Events'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            StudySpotsPage(),
            EventsPage(),
          ],
        ),
      ),
    );
  }
}
