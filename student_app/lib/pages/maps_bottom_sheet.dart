import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class MapsBottomSheet extends StatelessWidget {
  final List<dynamic> friends;
  final Map<String, MemoryImage> circleMemoryImages;
  final void Function(dynamic friend) onFriendTap;
  final ValueNotifier<Map<String, DateTime?>> lastUpdatedNotifier;

  const MapsBottomSheet({
    super.key,
    required this.friends,
    required this.circleMemoryImages,
    required this.onFriendTap,
    required this.lastUpdatedNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.08,
        maxChildSize: 0.8,
        builder: (_, scrollController) {
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(child: _buildTabViews(scrollController)),
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

  Widget _buildTabViews(ScrollController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
      ),
      child: TabBarView(
        children: [
          _FriendsList(
            friends: friends,
            circleMemoryImages: circleMemoryImages,
            lastUpdatedNotifier: lastUpdatedNotifier,
            scrollController: controller,
            onFriendTap: onFriendTap,
          ),
          const Center(
            child: Text('No events yet', style: TextStyle(color: Colors.grey)),
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
  final ScrollController scrollController;
  final void Function(dynamic) onFriendTap;

  const _FriendsList({
    required this.friends,
    required this.circleMemoryImages,
    required this.lastUpdatedNotifier,
    required this.scrollController,
    required this.onFriendTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
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
    Key? key,
    required this.friend,
    required this.avatar,
    required this.lastUpdatedNotifier,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Avatar(image: avatar, fallback: friend.username[0]),
      title: Text(friend.username, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: ValueListenableBuilder<Map<String, DateTime?>>(
        valueListenable: lastUpdatedNotifier,
        builder: (_, lastUpdatedMap, __) {
          final updated = lastUpdatedMap[friend.ccid];
          return Row(
            children: [
              const Text('Last seen: ', style: TextStyle(color: Color(0xFF757575))),
              if (updated == null)
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CupertinoActivityIndicator(radius: 8, color: Colors.grey),
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

  const Avatar({Key? key, this.image, required this.fallback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 25,
      backgroundImage: image,
      child: image == null ? Text(fallback) : null,
    );
  }
}
