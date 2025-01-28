class User {
  final String id; // Unique identifier for the user (will maybe replace with firebase id?)
  final String name; // Name of the user
  final String age; // temp
  Set<String> friends; // List of direct friends (user IDs)

  User({required this.id, required this.name, required this.age,}) : friends = {};

  // Add a friend
  void addFriend(String friendId) {
    friends.add(friendId);
  }

  // Remove a friend
  void removeFriend(String friendId) {
    friends.remove(friendId);
  }

  // Check if a user is a friend
  bool isFriend(String friendId) {
    return friends.contains(friendId);
  }

  // Get all friends
  Set<String> getFriends() {
    return friends;
  }
}

class SocialGraphManager {
  Map<String, User> users = {}; // Store users by their ID

  // Add a new user
  void addUser(String id, String name) {
    if (users.containsKey(id)) {
      print("User with ID $id already exists.");
      return;
    }
    users[id] = User(id: id, name: name);
  }

  // Add a friend connection between two users
  void addFriendConnection(String userId1, String userId2) {
    if (!users.containsKey(userId1) || !users.containsKey(userId2)) {
      print("One or both users do not exist.");
      return;
    }
    users[userId1]?.addFriend(userId2);
    users[userId2]?.addFriend(userId1);
  }

  // Remove a friend connection
  void removeFriendConnection(String userId1, String userId2) {
    if (!users.containsKey(userId1) || !users.containsKey(userId2)) {
      print("One or both users do not exist.");
      return;
    }
    users[userId1]?.removeFriend(userId2);
    users[userId2]?.removeFriend(userId1);
  }

  // Get mutual friends between two users
  Set<String> getMutualFriends(String userId1, String userId2) {
    if (!users.containsKey(userId1) || !users.containsKey(userId2)) {
      return {};
    }
    return users[userId1]!.friends.intersection(users[userId2]!.friends);
  }

  // Recommend friends for a user
  Set<String> recommendFriends(String userId) {
    if (!users.containsKey(userId)) return {};

    Set<String> recommendations = {};
    User? user = users[userId];

    user?.friends.forEach((friendId) {
      recommendations.addAll(users[friendId]?.friends ?? {});
    });

    // Exclude direct friends and the user themselves
    recommendations.removeAll(user!.friends);
    recommendations.remove(user.id);

    return recommendations;
  }

  // Display the user's friend graph
  void displayUserGraph(String userId) {
    if (!users.containsKey(userId)) {
      print("User with ID $userId does not exist.");
      return;
    }
    User user = users[userId]!;
    print("${user.name}'s friends: ${user.friends.join(", ")}");
  }
}
