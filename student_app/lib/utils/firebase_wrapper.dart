import 'package:cloud_firestore/cloud_firestore.dart';
import './user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:async';


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

Future<void> addUser(String name, String ccid, {String? photoURL}) async {
  try {
    DocumentReference documentRef = db.collection('users').doc(ccid);
    await documentRef.set({
      'name': name,
      'email': "$ccid@ualberta.ca",
      'photoURL': photoURL,
      'discipline': null,
      'education_lvl': null,
      'degree': null,
      'friends': <String>[],
      'friend_requests': <String>[],
      'requested_friends': <String>[],
      'schedule': null,
      'hasSeenBottomPopup': false,
      'isActive': false,
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
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    List<UserModel> allUsers = [];
    List<Map<String, dynamic>> users = querySnapshot.docs
        .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();

    for (int i = 0; i < users.length; i++) {
      UserModel user = UserModel(
        users[i]["id"] ?? "Unknown ID", // ccid
        users[i]["name"] ?? "Unknown", // username
        users[i]["email"] ?? "No email", // email
        users[i]["discipline"] ?? "No discipline", // discipline
        users[i]["schedule"], // schedule (nullable)
        users[i]["education_lvl"] ?? "No education", // educationLvl
        users[i]["degree"] ?? "No degree", // degree
        users[i]["location_tracking"] ?? "No tracking", // locationTracking
        users[i]["photoURL"] ?? "", // photoURL (nullable)
        users[i]["currentLocation"], // currentLocation (Map or null)
        users[i]["phone_number"],
        users[i]["insagram"],
      );
      allUsers.add(user);
    }
    return allUsers;
  } catch (e, stacktrace) {
    debugPrint("Error fetching users: $e");
    debugPrint("Stacktrace: $stacktrace");
    return [];
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

    // Remove each other from friends lists
    await userRef1.update({
      'friends': FieldValue.arrayRemove([userId2]),
      'requested_friends': FieldValue.arrayRemove([userId2]),
      'friend_requests': FieldValue.arrayRemove([userId2]),
    });

    await userRef2.update({
      'friends': FieldValue.arrayRemove([userId1]),
      'requested_friends': FieldValue.arrayRemove([userId1]),
      'friend_requests': FieldValue.arrayRemove([userId1]),
    });

    debugPrint("Users $userId1 and $userId2 are fully disconnected.");
  } catch (e) {
    debugPrint("Error removing friend: $e");
  }
}


Future<void> addUserSchedule(String userId, String scheduleContent) async {
  try {
    DocumentReference documentRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    await documentRef.update({
      'schedule': scheduleContent,
    });
    debugPrint("User schedule added for user $userId");
  } catch (e) {
    debugPrint("Error adding schedule to user: $e");
  }
}

Future<void> markPopupAsSeen(String userId) async {
  try {
    DocumentReference documentRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    await documentRef.update({
      'hasSeenBottomPopup': true,
    });
    debugPrint("Popup marked as seen for user $userId");
  } catch (e) {
    debugPrint("Error marking popup as seen: $e");
  }
}

Future<void> updateUserProfile(
  String ccid, {
  String? discipline,
  String? educationLvl,
  String? degree,
}) async {
  try {
    DocumentReference documentRef =
        FirebaseFirestore.instance.collection('users').doc(ccid);

    Map<String, dynamic> data = {};
    if (discipline != null) data['discipline'] = discipline;
    if (educationLvl != null) data['education_lvl'] = educationLvl;
    if (degree != null) data['degree'] = degree;

    await documentRef.update(data);
    debugPrint("User profile updated for $ccid with data: $data");
  } catch (e) {
    debugPrint("Error updating user profile: $e");
  }
}

Future<void> updateUserLocationPreference(
    String ccid, String trackingOption) async {
  try {
    DocumentReference docref =
        FirebaseFirestore.instance.collection('users').doc(ccid);
    Map<String, dynamic> updates = {};

    // Directly assign because trackingOption can't be null.
    updates['location_tracking'] = trackingOption;

    // Optionally, you could remove this check as well because updates won't be empty.
    if (updates.isEmpty) {
      debugPrint("No location preference provided. Skipping Firestore update.");
      return;
    }

    await docref.update(updates);
    debugPrint("Location preference updated for $ccid: $trackingOption");
  } catch (e) {
    debugPrint("Error updating location preference: $e");
  }
}

Future<void> updateUserLocation(
    String ccid, double latitude, double longitude) async {
  try {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection('users').doc(ccid);
    await docRef.update({
      'currentLocation': {
        'lat': latitude,
        'lng': longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }
    });
    debugPrint("Location updated for user $ccid");
  } catch (e) {
    debugPrint("Error updating location for user $ccid: $e");
  }
}

Future<void> updateUserPhoto(String ccid, String photoURL) async {
  try {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection('users').doc(ccid);
    await docRef.update({
      'photoURL': photoURL, // <-- Updates the user's profile image URL
    });
    debugPrint("User photo updated for $ccid");
  } catch (e) {
    debugPrint("Error updating user photo: $e");
  }
}

Future<void> updateUserActiveStatus(String ccid, bool isActive) async {
  try {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection('users').doc(ccid);
    await docRef.update({'isActive': isActive});
    debugPrint("User $ccid activity status updated: $isActive");
  } catch (e) {
    debugPrint("Error updating isActive status for user $ccid: $e");
  }
}

Future<void> uploadPhoneNumber(String userId, String phoneNumber) async {
  try {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    await docRef.set({'phone_number': phoneNumber}, SetOptions(merge: true));
  } catch (e) {
    debugPrint("Error uploading phone number for user $userId: $e");
  }
}


Future<void> uploadInstagramLink(String userId, String instagramUrl) async {
  try {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    await docRef.set({'instagram': instagramUrl}, SetOptions(merge: true));
  } catch (e) {
    debugPrint("Error uploading Instagram link for user $userId: $e");
  }
}


Future<Uint8List?> downloadImageBytes(String photoURL) async {
  try {
    final response = await http.get(Uri.parse(photoURL));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      debugPrint("Failed to download image, status code: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Error downloading image: $e");
  }
  return null;
}



Future<void> initializeLastSeen(List<dynamic> friends, ValueNotifier<Map<String, DateTime?>> notifier) async {
  List<String> friendIds = friends.map<String>((friend) => friend.ccid as String).toList();
  Map<String, DateTime?> initialData = {};

  for (final id in friendIds) {
    try {
      DocumentSnapshot doc = await db.collection('users').doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('currentLocation') &&
            data['currentLocation'] is Map &&
            data['currentLocation']['timestamp'] != null) {
          Timestamp ts = data['currentLocation']['timestamp'];
          initialData[id] = ts.toDate();
        } else {
          initialData[id] = null;
        }
      } else {
        initialData[id] = null;
      }
    } catch (e) {
      debugPrint("Error fetching last seen for friend $id: $e");
      initialData[id] = null;
    }
  }
  notifier.value = initialData;
}


StreamSubscription subscribeToFriendLocations(List<String> friendIds, ValueNotifier<Map<String, DateTime?>> notifier) {
  return db.collection('users')
      .where(FieldPath.documentId, whereIn: friendIds)
      .snapshots()
      .listen((QuerySnapshot snapshot) {
    Map<String, DateTime?> updatedMap = {};
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('currentLocation') &&
          data['currentLocation'] is Map &&
          data['currentLocation']['timestamp'] != null) {
        Timestamp ts = data['currentLocation']['timestamp'];
        updatedMap[doc.id] = ts.toDate();
      } else {
        updatedMap[doc.id] = null;
      }
    }
    notifier.value = updatedMap;
  });
}
