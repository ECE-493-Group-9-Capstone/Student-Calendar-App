import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_app/utils/event_service.dart';
import 'package:student_app/pages/model/event_model.dart';
import 'package:intl/intl.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage>
    with AutomaticKeepAliveClientMixin {
  final EventService eventService =
      EventService(firestore: FirebaseFirestore.instance);
  final TextEditingController searchController = TextEditingController();

  List<Event> allEvents = [];
  List<Event> filteredEvents = [];
  bool isSearching = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final events = await eventService.getAllEvents();
      if (!mounted) return; // Ensure the widget is still in the tree
      setState(() {
        allEvents =
            events.map((data) => Event.fromMap(data, data['id'])).toList();
        filteredEvents = allEvents;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching events: $e");
      if (!mounted) return; // Ensure the widget is still in the tree
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    final lc = query.toLowerCase();
    setState(() {
      isSearching = query.isNotEmpty;
      filteredEvents = allEvents.where((event) {
        return event.title.toLowerCase().contains(lc);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super.build to ensure state preservation
    return Scaffold(
      appBar: AppBar(title: const Text('Events Page')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  _buildEventsList(),
                ],
              ),
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildSearchBar() => Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(colors: [
            Color(0xFF396548),
            Color(0xFF6B803D),
            Color(0xFF909533)
          ]),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(13)),
          child: Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                      hintText: "Search for events", border: InputBorder.none),
                  onChanged: _onSearch,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEventsList() {
    if (filteredEvents.isEmpty) {
      return const Center(child: Text('No matches found'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredEvents.length,
      itemBuilder: (_, i) {
        final event = filteredEvents[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20), // Add consistent spacing
          child: _buildEventTile(event),
        );
      },
    );
  }

  Widget _buildEventTile(Event event) {
    final DateFormat dateFormatter = DateFormat('MMMM d, yyyy');
    final DateFormat timeFormatter = DateFormat('h:mm a');
    String dateString;
    if (event.endDate != null) {
      dateString =
          "${dateFormatter.format(event.startDate)} - ${dateFormatter.format(event.endDate!)}";
    } else {
      dateString = dateFormatter.format(event.startDate);
    }

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 190, 190, 190),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              event.imageUrl ?? '',
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) {
                return Container(
                  height: 120,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(Icons.event, size: 40, color: Colors.white),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
            child: Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "${dateString}\n${timeFormatter.format(DateFormat('HH:mm').parse(event.startTime))} - ${timeFormatter.format(DateFormat('HH:mm').parse(event.endTime))}\n${event.location}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
