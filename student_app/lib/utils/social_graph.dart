import 'dart:async';
import '../services/firebase_service.dart';
import 'user_model.dart';
// FR37 - SocialGraph.Generate - The system shall create a social graph with users as nodes and 
// friendships with other users as edges 
// FR38 - SocialGraph.Sync - The system shall keep the graph up to date by adding or removing 
// nodes and edges 
// FR39 - SocialGraph.Recommend - The system shall recommend potential friends based on the 
// user's mutual friends and/or schedules
class SocialGraph {
  final FirebaseService _firebaseService;
  Map<String, UserModel> users = {}; // Stores all users
  Map<String, List<String>> connections = {}; // Adjacency list of friends
  Timer? _updateTimer;

  static SocialGraph? _instance;

  factory SocialGraph({FirebaseService? firebaseService}) {
    if (_instance == null) {
      if (firebaseService == null) {
        throw ArgumentError(
            'firebaseService cannot be null when creating SocialGraph');
      }
      _instance = SocialGraph._internal(firebaseService);
    }
    return _instance!;
  }

  SocialGraph._internal(this._firebaseService);

  Future<void> buildGraph() async {
    final List<UserModel> userList = await _firebaseService.getAllUsers();
    users.clear();
    connections.clear();

    // Preload users
    for (UserModel user in userList) {
      users[user.ccid] = user;
    }

    // Fetch all user connections
    for (String userId in users.keys) {
      connections[userId] = await _firebaseService.getUserFriends(userId);
    }
  }

  Future<void> updateGraph() async {
    await buildGraph();
  }

  List<UserModel> getFriends(String userId) {
    if (!connections.containsKey(userId)) {
      return [];
    }
    return connections[userId]!
        .map((id) => users[id])
        .where((user) => user != null)
        .cast<UserModel>()
        .toList();
  }

  void startAutoUpdate(Duration interval) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(interval, (timer) async {
      await updateGraph();
    });
  }

  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  List<UserModel> getFriendRecommendations(String userId) {
    final Set<String> recommended = {};
    if (!connections.containsKey(userId)) {
      return [];
    }

    final List<String> friends = connections[userId]!;
    final Set<String> friendSet = friends.toSet();

    // Mutual Friends Logic
    final Map<String, int> mutualFriendCount = {};

    for (String friend in friends) {
      for (String mutual in connections[friend] ?? []) {
        if (mutual != userId && !friendSet.contains(mutual)) {
          mutualFriendCount[mutual] = (mutualFriendCount[mutual] ?? 0) + 1;
        }
      }
    }

    // Discipline-based Logic
    final String userDiscipline = users[userId]?.discipline ?? '';
    for (UserModel user in users.values) {
      if (user.ccid != userId &&
          user.discipline == userDiscipline &&
          !friendSet.contains(user.ccid)) {
        recommended.add(user.ccid);
      }
    }

    // Sort by mutual friend count
    final List<String> sortedMutuals = mutualFriendCount.keys.toList()
      ..sort((a, b) => mutualFriendCount[b]!.compareTo(mutualFriendCount[a]!));

    // Combine both, avoiding duplicates
    final Set<String> combined = {...sortedMutuals, ...recommended};

    // remove self, friends, and invalid users
    final List<UserModel> finalRecommendations = combined
        .where((id) =>
            id != userId && !friendSet.contains(id) && users.containsKey(id))
        .map((id) => users[id]!)
        .toList();
    return finalRecommendations;
  }
}
