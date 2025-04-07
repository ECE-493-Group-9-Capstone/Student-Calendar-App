// maps_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:student_app/utils/firebase_wrapper.dart';
import 'package:student_app/utils/profile_picture.dart';

class MapsBottomSheet extends StatefulWidget {
  final DraggableScrollableController draggableController;
  final List<dynamic> friends;
  final Set<String> hiddenFromMe;
  final ValueNotifier<Map<String, DateTime?>> lastUpdatedNotifier;
  final void Function(dynamic friend) onFriendTap;

  const MapsBottomSheet(
      {Key? key,
      required this.draggableController,
      required this.friends,
      required this.lastUpdatedNotifier,
      required this.onFriendTap,
      required this.hiddenFromMe})
      : super(key: key);

  @override
  _MapsBottomSheetState createState() => _MapsBottomSheetState();
}

class _MapsBottomSheetState extends State<MapsBottomSheet> {
  StreamSubscription? _friendLocationSubscription;
  Map<String, bool> mapFilters = {
    'Study Spots': true,
    'Events': true,
    'Heat Map': true,
  };

  @override
  void initState() {
    super.initState();
    _initializeAndSubscribe();
  }

  Set<String> _getFriendIds(List<dynamic> friends) {
    return friends.map<String>((friend) => friend.ccid as String).toSet();
  }

  Future<void> _initializeAndSubscribe() async {
    if (widget.friends.isEmpty) {
      return;
    } else {
      await initializeLastSeen(widget.friends, widget.lastUpdatedNotifier);
      List<String> friendIds = widget.friends
          .map<String>((friend) => friend.ccid as String)
          .toList();
      _friendLocationSubscription =
          subscribeToFriendLocations(friendIds, widget.lastUpdatedNotifier);
    }
  }

  @override
  void didUpdateWidget(covariant MapsBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldFriendIds = _getFriendIds(oldWidget.friends);
    final newFriendIds = _getFriendIds(widget.friends);
    if (oldFriendIds.length != newFriendIds.length ||
        !oldFriendIds.containsAll(newFriendIds)) {
      _friendLocationSubscription?.cancel();
      _initializeAndSubscribe();
    }
  }

  @override
  void dispose() {
    _friendLocationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        controller: widget.draggableController,
        initialChildSize: 0.4,
        minChildSize: 0.1,
        maxChildSize: 0.6,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 190, 190, 190),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Friends',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _FriendsList(
                    friends: widget.friends,
                    lastUpdatedNotifier: widget.lastUpdatedNotifier,
                    onFriendTap: widget.onFriendTap,
                    controller: scrollController,
                    hiddenFromMe: widget.hiddenFromMe,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  final List<dynamic> friends;
  final ValueNotifier<Map<String, DateTime?>> lastUpdatedNotifier;
  final void Function(dynamic) onFriendTap;
  final ScrollController controller;
  final Set<String> hiddenFromMe;

  const _FriendsList({
    super.key,
    required this.friends,
    required this.lastUpdatedNotifier,
    required this.onFriendTap,
    required this.controller,
    required this.hiddenFromMe,
  });

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.zero,
      itemCount: friends.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final friend = friends[i];
        return FriendTile(
          friend: friend,
          lastUpdatedNotifier: lastUpdatedNotifier,
          onTap: () => onFriendTap(friend),
          isHiddenFromMe: hiddenFromMe.contains(friend.ccid),
        );
      },
    );
  }
}

class FriendTile extends StatefulWidget {
  final dynamic friend;
  final ValueNotifier<Map<String, DateTime?>> lastUpdatedNotifier;
  final VoidCallback onTap;
  final bool isHiddenFromMe;

  const FriendTile({
    Key? key,
    required this.friend,
    required this.lastUpdatedNotifier,
    required this.onTap,
    required this.isHiddenFromMe,
  }) : super(key: key);

  @override
  _FriendTileState createState() => _FriendTileState();
}

class _FriendTileState extends State<FriendTile> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallbackInitials = (widget.friend.username?.toString() ?? '')
        .split(" ")
        .where((p) => p.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    return ListTile(
      leading: CachedProfileImage(
        photoURL: widget.friend.photoURL?.toString() ?? '',
        size: 50,
        fallbackText: fallbackInitials,
        fallbackBackgroundColor: const Color(0xFF909533),
      ),
      title: Text(
        widget.friend.username.toString(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: widget.isHiddenFromMe
          ? const Text(
              'Location hidden',
              style: TextStyle(color: Colors.grey),
            )
          : ValueListenableBuilder<Map<String, DateTime?>>(
              valueListenable: widget.lastUpdatedNotifier,
              builder: (_, lastUpdatedMap, __) {
                final updated = lastUpdatedMap[widget.friend.ccid];
                return Row(
                  children: [
                    const Text(
                      'Last seen: ',
                      style: TextStyle(color: Color(0xFF757575)),
                    ),
                    if (updated == null)
                      const Text(
                        'not found',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Text(
                        '${DateTime.now().difference(updated).inMinutes} min ago',
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                );
              },
            ),
      onTap: widget.isHiddenFromMe ? null : widget.onTap,
    );
  }
}
