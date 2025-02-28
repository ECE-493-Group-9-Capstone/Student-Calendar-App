import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_wrapper.dart';
import '../utils/user.dart';
import './firebase_wrapper.dart';

import 'dart:async';
import 'firebase_wrapper.dart';
import 'user.dart';

class SocialGraph {
  Map<String, UserModel> users = {}; // Stores all users
  Map<String, List<String>> connections = {}; // Adjacency list of friends
  
  static final SocialGraph _instance = SocialGraph._internal();
  factory SocialGraph() => _instance;
  
  SocialGraph._internal();

  Future<void> buildGraph() async {
    List<UserModel> userList = await getAllUsers();
    users.clear();
    connections.clear();
    
    for (UserModel user in userList) {
      users[user.ccid] = user;
      List<String> friends = await getUserFriends(user.ccid);
      connections[user.ccid] = friends;
    }
  }
  
  Future<void> updateGraph() async {
    await buildGraph();
  }
  
  List<UserModel> getFriends(String userId) {
    if (!connections.containsKey(userId)) return [];
    return connections[userId]!.map((id) => users[id]!).toList();
  }
  
  Future<void> startAutoUpdate(Duration interval) async {
    Timer.periodic(interval, (timer) async {
      await updateGraph();
    });
  }

  List<UserModel> getFriendRecommendations(String userId) {
    Set<String> recommended = {};
    
    if (!connections.containsKey(userId)) return [];
    List<String> friends = connections[userId]!;
    
    // Mutual friends recommendation
    for (String friend in friends) {
      for (String mutual in connections[friend] ?? []) {
        if (mutual != userId && !friends.contains(mutual)) {
          recommended.add(mutual);
        }
      }
    }
    
    // Discipline-based recommendation
    String userDiscipline = users[userId]?.discipline ?? "";
    for (UserModel user in users.values) {
      if (user.ccid != userId && user.discipline == userDiscipline) {
        recommended.add(user.ccid);
      }
    }
    
    return recommended.map((id) => users[id]!).toList();
  }
}

