import 'dart:async';
import 'firebase_wrapper.dart';
import '../utils/user.dart';

class SocialGraph {
  Map<String, UserModel> users = {}; // Stores all users
  Map<String, List<String>> connections = {}; // Adjacency list of friends
  Timer? _updateTimer;

  static final SocialGraph _instance = SocialGraph._internal();
  factory SocialGraph() => _instance;

  SocialGraph._internal();

  Future<void> buildGraph() async {
    List<UserModel> userList = await getAllUsers();
    users.clear();
    connections.clear();

    // Preload users
    for (UserModel user in userList) {
      users[user.ccid] = user;
    }

    // Fetch all user connections (optimize by bulk fetching if possible)
    for (String userId in users.keys) {
      connections[userId] = await getUserFriends(userId);
    }
  }

  Future<void> updateGraph() async {
    await buildGraph();
  }

  List<UserModel> getFriends(String userId) {
    if (!connections.containsKey(userId)) return [];
    return connections[userId]!
        .map((id) => users[id])
        .where((user) => user != null)
        .cast<UserModel>()
        .toList();
  }

  void startAutoUpdate(Duration interval) {
    _updateTimer?.cancel(); // Ensure only one timer instance runs
    _updateTimer = Timer.periodic(interval, (timer) async {
      await updateGraph();
    });
  }

  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  List<UserModel> getFriendRecommendations(String userId) {
    Set<String> recommended = {};
    if (!connections.containsKey(userId)) return [];

    List<String> friends = connections[userId]!;

    // Mutual friends recommendation
    Map<String, int> mutualFriendCount = {};

    for (String friend in friends) {
      for (String mutual in connections[friend] ?? []) {
        if (mutual != userId && !friends.contains(mutual)) {
          mutualFriendCount[mutual] = (mutualFriendCount[mutual] ?? 0) + 1;
        }
      }
    }

    // Discipline-based recommendation (excluding already connected users)
    String userDiscipline = users[userId]?.discipline ?? "";
    for (UserModel user in users.values) {
      if (user.ccid != userId &&
          user.discipline == userDiscipline &&
          !friends.contains(user.ccid)) {
        recommended.add(user.ccid);
      }
    }

    // Prioritize by mutual friends count
    List<String> sortedRecommendations = mutualFriendCount.keys.toList()
      ..sort((a, b) => mutualFriendCount[b]!.compareTo(mutualFriendCount[a]!));

    // Merge sorted mutual friends & discipline-based recommendations
    List<String> finalRecommendations =
        sortedRecommendations + recommended.toList();

    return finalRecommendations
        .map((id) => users[id])
        .where((user) => user != null)
        .cast<UserModel>()
        .toList();
  }
}
