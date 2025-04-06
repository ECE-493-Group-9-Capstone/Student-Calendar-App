import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'package:student_app/utils/firebase_wrapper.dart';
import 'package:student_app/utils/cache_helper.dart'; // For caching functions

class MapsBottomSheet extends StatefulWidget {
  final DraggableScrollableController draggableController;
  final List<dynamic> friends;
  final ValueNotifier<Map<String, DateTime?>> lastUpdatedNotifier;
  final void Function(dynamic friend) onFriendTap;

  const MapsBottomSheet({
    Key? key,
    required this.draggableController,
    required this.friends,
    required this.lastUpdatedNotifier,
    required this.onFriendTap,
  }) : super(key: key);

  @override
  _MapsBottomSheetState createState() => _MapsBottomSheetState();
}

class _MapsBottomSheetState extends State<MapsBottomSheet> {
  StreamSubscription? _friendLocationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAndSubscribe();
  }

  Set<String> _getFriendIds(List<dynamic> friends) {
    return friends.map<String>((friend) => friend.ccid as String).toSet();
  }

  Future<void> _initializeAndSubscribe() async {
    await initializeLastSeen(widget.friends, widget.lastUpdatedNotifier);
    List<String> friendIds =
        widget.friends.map<String>((friend) => friend.ccid as String).toList();
    _friendLocationSubscription =
        subscribeToFriendLocations(friendIds, widget.lastUpdatedNotifier);
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
        maxChildSize: 0.5,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle similar to Find My iPhone
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                Expanded(
                  child: _FriendsList(
                    friends: widget.friends,
                    lastUpdatedNotifier: widget.lastUpdatedNotifier,
                    onFriendTap: widget.onFriendTap,
                    controller: scrollController,
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

  const _FriendsList({
    Key? key,
    required this.friends,
    required this.lastUpdatedNotifier,
    required this.onFriendTap,
    required this.controller,
  }) : super(key: key);

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
        );
      },
    );
  }
}

class FriendTile extends StatelessWidget {
  final dynamic friend;
  final ValueNotifier<Map<String, DateTime?>> lastUpdatedNotifier;
  final VoidCallback onTap;

  const FriendTile({
    Key? key,
    required this.friend,
    required this.lastUpdatedNotifier,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fallbackInitials = (friend.username?.toString() ?? '')
        .split(" ")
        .where((p) => p.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    return ListTile(
      leading: CachedProfileImage(
        photoURL: friend.photoURL?.toString() ?? '',
        size: 50,
        fallbackText: fallbackInitials,
        fallbackBackgroundColor: const Color(0xFF909533),
      ),
      title: Text(
        friend.username.toString(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: ValueListenableBuilder<Map<String, DateTime?>>(
        valueListenable: lastUpdatedNotifier,
        builder: (_, lastUpdatedMap, __) {
          final updated = lastUpdatedMap[friend.ccid];
          return Row(
            children: [
              const Text(
                'Last seen: ',
                style: TextStyle(color: Color(0xFF757575)),
              ),
              if (updated == null)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CupertinoActivityIndicator(radius: 8, color: Colors.grey),
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
      onTap: onTap,
    );
  }
}

///
/// CachedProfileImage widget follows the same approach as in your friends page.
/// It downloads the image on the first load (from Firebase) and then caches it for future use.
///
Future<Uint8List?> downloadImageBytes(String photoURL) async {
  try {
    final response = await http.get(Uri.parse(photoURL));
    if (response.statusCode == 200) return response.bodyBytes;
  } catch (e) {
    debugPrint("Error downloading image: $e");
  }
  return null;
}

class CachedProfileImage extends StatefulWidget {
  final String? photoURL;
  final double size;
  final String? fallbackText;
  final Color? fallbackBackgroundColor;
  const CachedProfileImage({
    Key? key,
    required this.photoURL,
    this.size = 64,
    this.fallbackText,
    this.fallbackBackgroundColor,
  }) : super(key: key);

  @override
  _CachedProfileImageState createState() => _CachedProfileImageState();
}

class _CachedProfileImageState extends State<CachedProfileImage> {
  Future<Uint8List?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    if (widget.photoURL != null && widget.photoURL!.isNotEmpty) {
      _imageFuture = _getProfileImage(widget.photoURL!);
    }
  }

  Future<Uint8List?> _getProfileImage(String photoURL) async {
    final key = 'circle_${photoURL.hashCode}_${widget.size}';
    Uint8List? bytes = await loadCachedImageBytes(key);
    if (bytes != null) return bytes;
    bytes = await downloadImageBytes(photoURL);
    if (bytes != null) await cacheImageBytes(key, bytes);
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photoURL == null || widget.photoURL!.isEmpty) {
      return CircleAvatar(
        radius: widget.size / 2,
        backgroundColor: widget.fallbackBackgroundColor ?? Colors.grey,
        child: widget.fallbackText != null
            ? Text(
                widget.fallbackText!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.size / 2.5,
                ),
              )
            : null,
      );
    }
    return FutureBuilder<Uint8List?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return ClipOval(
            child: Image.memory(
              snapshot.data!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            ),
          );
        }
        return CircleAvatar(
          radius: widget.size / 2,
          backgroundColor: widget.fallbackBackgroundColor ?? Colors.grey,
          child: widget.fallbackText != null
              ? Text(
                  widget.fallbackText!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.size / 2.5,
                  ),
                )
              : null,
        );
      },
    );
  }
}
