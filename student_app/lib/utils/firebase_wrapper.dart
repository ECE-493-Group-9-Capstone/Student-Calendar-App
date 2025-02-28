import 'package:cloud_firestore/cloud_firestore.dart';
import './user.dart';
import 'package:flutter/material.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

void readDocument(String id) async {
  try {
    DocumentSnapshot documentSnapshot =
        await db.collection('users').doc(id).get();

    if (documentSnapshot.exists) {
      Map<String, dynamic>? data =
          documentSnapshot.data() as Map<String, dynamic>?;
      debugPrint("Document Data: $data");
    } else {
      debugPrint("Document does not exist");
    }
  } catch (e) {
    debugPrint("Error reading document: $e");
  }
}

Future<void> addUser(String name, String ccid, String discipline) async {
  try {
    DocumentReference documentRef = db.collection('users').doc(ccid);
    await documentRef.set({
      'name': name,
      'discipline': discipline,
      'friends': <String>[], // Ensure it's a List<String>
      'friend_requests': <String>[],
    });
    debugPrint("User added with doc ID: $ccid");
  } catch (e) {
    debugPrint("Error adding user: $e");
  }
}

Future<void> acceptFriendRequest(String userId1, String userId2) async {
  try {
    DocumentReference userRef1 = db.collection('users').doc(userId1);
    DocumentReference userRef2 = db.collection('users').doc(userId2);

    // Add each other to their friends lists
    await userRef1.update({
      'friends': FieldValue.arrayUnion(
          [userId2]), // Add userId2 to userId1's friends list
      'friend_requests':
          FieldValue.arrayRemove([userId2]) // Remove from friend_requests
    });

    await userRef2.update({
      'friends': FieldValue.arrayUnion(
          [userId1]), // Add userId1 to userId2's friends list
      'requested_friends':
          FieldValue.arrayRemove([userId1]) // Remove from requested_friends
    });

    debugPrint("Users $userId1 and $userId2 are now friends.");
  } catch (e) {
    debugPrint("Error accepting friend request: $e");
  }
}

Future<void> sendRecieveRequest(String senderId, String receiverId) async {
  try {
    DocumentReference senderRef = db.collection('users').doc(senderId);
    DocumentReference receiverRef = db.collection('users').doc(receiverId);

    // Add senderId to receiver's friend_requests list
    await receiverRef.update({
      'friend_requests': FieldValue.arrayUnion([senderId])
    });

    // Add receiverId to sender's requested_friends list
    await senderRef.update({
      'requested_friends': FieldValue.arrayUnion([receiverId])
    });

    debugPrint("Friend request sent from $senderId to $receiverId.");
  } catch (e) {
    debugPrint("Error sending friend request: $e");
  }
}

Future<void> deleteUser(String id) async {
  try {
    await db
        .collection('users') // Specify the collection
        .doc(id) // Specify the document ID
        .delete(); // Delete the document
    debugPrint("User deleted successfully!");
  } catch (e) {
    debugPrint("Error deleting user: $e");
  }
}

Future<List<UserModel>> getAllUsers() async {
  try {
    QuerySnapshot querySnapshot = await db
        .collection('users') // Specify the Firestore collection
        .get(); // Fetch all documents in the collection

    List<UserModel> allUsers = [];
    List<Map<String, dynamic>> users = querySnapshot.docs
        .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();

    for (int i = 0; i < users.length; i++) {
      UserModel user = UserModel(users[i]["id"], users[i]["name"],
          users[i]["email"], users[i]["discipline"]);
      allUsers.add(user);
    }
    return allUsers;
  } catch (e) {
    debugPrint("Error fetching users: $e");
    return []; // Return an empty list in case of error
  }
}

Future<List<String>> getUserFriends(String userId) async {
  try {
    DocumentSnapshot documentSnapshot =
        await db.collection('users').doc(userId).get();

    if (documentSnapshot.exists) {
      Map<String, dynamic>? data =
          documentSnapshot.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey('friends')) {
        List<String> friends = List<String>.from(data['friends']);
        debugPrint("User $userId friends: $friends");
        return friends;
      } else {
        debugPrint("User $userId has no friends listed.");
        return [];
      }
    } else {
      debugPrint("User does not exist.");
      return [];
    }
  } catch (e) {
    debugPrint("Error fetching user friends: $e");
    return [];
  }
}

Future<Map<String, dynamic>?> fetchUserData(String userId) async {
  try {
    DocumentSnapshot userDoc = await db.collection('users').doc(userId).get();

    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      return null;
    }
  } catch (e) {
    debugPrint("Error fetching user data: $e");
    return null;
  }
}

Future<List<Map<String, dynamic>>> getFriendRequests(String userId) async {
  try {
    DocumentSnapshot userDoc = await db.collection('users').doc(userId).get();

    if (userDoc.exists) {
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null && userData.containsKey('friend_requests')) {
        List<String> friendRequestIds =
            List<String>.from(userData['friend_requests']);

        if (friendRequestIds.isEmpty) {
          return [];
        }

        // Fetch details for each friend request sender
        List<Map<String, dynamic>> friendRequestsDetails = [];
        for (String requesterId in friendRequestIds) {
          DocumentSnapshot requesterDoc =
              await db.collection('users').doc(requesterId).get();

          if (requesterDoc.exists) {
            Map<String, dynamic>? requesterData =
                requesterDoc.data() as Map<String, dynamic>?;
            if (requesterData != null) {
              requesterData['id'] = requesterId; // Include the requester's ID
              friendRequestsDetails.add(requesterData);
            }
          }
        }
        return friendRequestsDetails;
      } else {
        debugPrint("User $userId has no friend requests field.");
        return [];
      }
    } else {
      debugPrint("User does not exist.");
      return [];
    }
  } catch (e) {
    debugPrint("Error fetching friend requests: $e");
    return [];
  }
}

Future<List<String>> getRequestedFriends(String userId) async {
  try {
    DocumentSnapshot userDoc = await db.collection('users').doc(userId).get();

    if (userDoc.exists) {
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null && userData.containsKey('requested_friends')) {
        List<String> requestedFriends =
            List<String>.from(userData['requested_friends']);
        debugPrint("User $userId requested friends: $requestedFriends");
        return requestedFriends;
      } else {
        debugPrint("User $userId has no requested friends field.");
        return [];
      }
    } else {
      debugPrint("User does not exist.");
      return [];
    }
  } catch (e) {
    debugPrint("Error fetching requested friends: $e");
    return [];
  }
}

Future<void> declineFriendRequest(String requesterId, String userId) async {
  try {
    // Remove from friend requests only
    await db.collection('users').doc(userId).update({
      'friend_requests': FieldValue.arrayRemove([requesterId]),
    });

    debugPrint("Friend request declined from $requesterId");
  } catch (e) {
    debugPrint("Error declining friend request: $e");
  }
}

Future<void> removeFriendFromUsers(String userId1, String userId2) async {
  try {
    DocumentReference userRef1 = db.collection('users').doc(userId1);
    DocumentReference userRef2 = db.collection('users').doc(userId2);

    // Remove each other from their friends lists
    await userRef1.update({
      'friends': FieldValue.arrayRemove([userId2]),
    });

    await userRef2.update({
      'friends': FieldValue.arrayRemove([userId1]),
    });

    debugPrint("Users $userId1 and $userId2 are no longer friends.");
  } catch (e) {
    debugPrint("Error removing friend: $e");
  }
}

Future<void> addStudySpot({
  required String name,
  required String building,
  required GeoPoint coordinates,
  required String description,
  double? rating,
  int? reviewCount,
  int? capacity,
  int? crowdDensity,
  bool? isOpen,
  List<String>? amenities,
  String? imageUrl,
  List<String>? tags,
}) async {
  try {
    Map<String, dynamic> studySpotData = {
      'name': name,
      'building': building,
      'coordinates': coordinates,
      'rating': rating,
      'reviewCount': reviewCount,
      'description': description,
      'capacity': capacity,
      'crowdDensity': crowdDensity,
      'isOpen': isOpen,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    if (amenities != null) {
      studySpotData['amenities'] = amenities;
    }
    if (imageUrl != null) {
      studySpotData['imageUrl'] = imageUrl;
    }
    if (tags != null) {
      studySpotData['tags'] = tags;
    }

    await db.collection('studySpots').add(studySpotData);

    debugPrint("Study spot added successfully!");
  } catch (e) {
    debugPrint("Error adding study spot: $e");
  }
}

//
