import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapsBottomSheet extends StatelessWidget {
  final DraggableScrollableController draggableController;
  final List<dynamic> friends;
  final Map<String, MemoryImage> circleMemoryImages;
  final ValueNotifier<Map<String, DateTime?>> lastUpdatedNotifier;
  final void Function(dynamic friend) onFriendTap;
  final List<dynamic> events;
  final void Function(dynamic event) onEventTap;

  const MapsBottomSheet({
    super.key,
    required this.draggableController,
    required this.friends,
    required this.circleMemoryImages,
    required this.lastUpdatedNotifier,
    required this.onFriendTap,
    required this.events,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        controller: draggableController,
        initialChildSize: 0.4,
        minChildSize: 0.1,
        maxChildSize: 0.5,
        // Note: We ignore the provided scroll controller here so that inner scrolling is independent.
        builder: (_, __) {
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(child: _buildTabViews()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: const LinearGradient(
          colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
        ),
      ),
      child: TabBar(
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [Tab(text: 'Friends'), Tab(text: 'Events')],
      ),
    );
  }

  Widget _buildTabViews() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: TabBarView(
        children: [
          _FriendsList(
            friends: friends,
            circleMemoryImages: circleMemoryImages,
            lastUpdatedNotifier: lastUpdatedNotifier,
            onFriendTap: onFriendTap,
          ),
          _EventsList(
            events: events,
            onEventTap: onEventTap,
          ),
        ],
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  final List<dynamic> friends;
  final Map<String, MemoryImage> circleMemoryImages;
  final ValueNotifier<Map<String, DateTime?>> lastUpdatedNotifier;
  final void Function(dynamic) onFriendTap;

  const _FriendsList({
    super.key,
    required this.friends,
    required this.circleMemoryImages,
    required this.lastUpdatedNotifier,
    required this.onFriendTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // No controller is passed so the ListView manages its own scrolling.
      padding: EdgeInsets.zero,
      itemCount: friends.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final friend = friends[i];
        return FriendTile(
          friend: friend,
          avatar: circleMemoryImages[friend.ccid],
          lastUpdatedNotifier: lastUpdatedNotifier,
          onTap: () => onFriendTap(friend),
        );
      },
    );
  }
}

class FriendTile extends StatelessWidget {
  final dynamic friend;
  final MemoryImage? avatar;
  final ValueNotifier<Map<String, DateTime?>> lastUpdatedNotifier;
  final VoidCallback onTap;

  const FriendTile({
    super.key,
    required this.friend,
    required this.avatar,
    required this.lastUpdatedNotifier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Avatar(image: avatar, fallback: friend.username[0]),
      title: Text(friend.username,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: ValueListenableBuilder<Map<String, DateTime?>>(
        valueListenable: lastUpdatedNotifier,
        builder: (_, lastUpdatedMap, __) {
          final updated = lastUpdatedMap[friend.ccid];
          return Row(
            children: [
              const Text('Last seen: ',
                  style: TextStyle(color: Color(0xFF757575))),
              if (updated == null)
                SizedBox(
                  height: 16,
                  width: 16,
                  child:
                      CupertinoActivityIndicator(radius: 8, color: Colors.grey),
                )
              else
                Text('${DateTime.now().difference(updated).inMinutes} min ago',
                    style: const TextStyle(color: Colors.grey)),
            ],
          );
        },
      ),
      onTap: onTap,
    );
  }
}

class Avatar extends StatelessWidget {
  final MemoryImage? image;
  final String fallback;

  const Avatar({super.key, this.image, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 25,
      backgroundImage: image,
      child: image == null ? Text(fallback) : null,
    );
  }
}

class _EventsList extends StatelessWidget {
  final List<dynamic> events;
  final void Function(dynamic) onEventTap;

  const _EventsList({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    // Create a copy and sort the events by their date in increasing order.
    final sortedEvents = List<dynamic>.from(events)
      ..sort((a, b) {
        DateTime dateA;
        DateTime dateB;
        try {
          dateA = a['date'] is Timestamp
              ? a['date'].toDate()
              : DateTime.parse(a['date'].toString());
        } catch (e) {
          debugPrint('Error parsing event date for event A: $e');
          dateA = DateTime.now();
        }
        try {
          dateB = b['date'] is Timestamp
              ? b['date'].toDate()
              : DateTime.parse(b['date'].toString());
        } catch (e) {
          debugPrint('Error parsing event date for event B: $e');
          dateB = DateTime.now();
        }
        return dateA.compareTo(dateB);
      });

    if (sortedEvents.isEmpty) {
      return ListView(
        // No controller is passed so this ListView scrolls independently.
        padding: EdgeInsets.zero,
        children: const [
          _EventsHeader(),
          Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child:
                  Text('No events yet', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      // No controller is passed so this ListView scrolls independently.
      padding: EdgeInsets.zero,
      itemCount: sortedEvents.length + 1,
      separatorBuilder: (_, index) {
        if (index == 0) return const SizedBox.shrink();
        return const Divider(height: 1);
      },
      itemBuilder: (_, index) {
        if (index == 0) {
          return const _EventsHeader();
        } else {
          final event = sortedEvents[index - 1];
          return EventTile(
            event: event,
            onTap: () => onEventTap(event),
          );
        }
      },
    );
  }
}

class _EventsHeader extends StatelessWidget {
  const _EventsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Text(
            'Upcoming Events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: const Icon(Icons.calendar_today, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class EventTile extends StatelessWidget {
  final dynamic event;
  final VoidCallback onTap;

  const EventTile({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final eventName = event['title'] ?? 'Event';
    DateTime eventDate;
    try {
      final dynamic dateValue = event['date'];
      eventDate = dateValue is Timestamp
          ? dateValue.toDate()
          : DateTime.parse(dateValue.toString());
    } catch (e) {
      debugPrint('Error parsing event date: $e');
      eventDate = DateTime.now();
    }
    final String formattedDate =
        DateFormat('MMMM dd, yyyy').format(eventDate);

    final startTimeStr = event['start_time'] ?? '00:00:00';
    final endTimeStr = event['end_time'] ?? '00:00:00';
    DateTime parsedStart;
    DateTime parsedEnd;
    try {
      parsedStart = DateFormat('HH:mm:ss').parse(startTimeStr);
      parsedEnd = DateFormat('HH:mm:ss').parse(endTimeStr);
    } catch (e) {
      debugPrint('Error parsing event times: $e');
      parsedStart = DateTime(0);
      parsedEnd = DateTime(0);
    }
    if (parsedEnd.isBefore(parsedStart)) {
      parsedEnd = parsedEnd.add(const Duration(days: 1));
    }
    final formattedStart =
        DateFormat('h:mma').format(parsedStart).toLowerCase();
    final formattedEnd =
        DateFormat('h:mma').format(parsedEnd).toLowerCase();
    final timeText = "$formattedDate $formattedStart - $formattedEnd";

    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.event, color: Colors.black),
      ),
      title: Text(eventName,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(timeText),
      onTap: onTap,
    );
  }
}
