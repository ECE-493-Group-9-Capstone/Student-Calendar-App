import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/user_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:async';

class FirebaseService {
  final FirebaseFirestore firestore;
  FirebaseService({required this.firestore});

  Future<void> addUser(String name, String ccid,
      {String? photoURL, bool merge = false}) async {
    try {
      final DocumentReference documentRef =
          firestore.collection('users').doc(ccid);
      await documentRef.set({
        'name': name,
        'email': '$ccid@ualberta.ca',
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
      }, SetOptions(merge: merge));
      debugPrint('User added with doc ID: $ccid');
    } catch (e) {
      debugPrint('Error adding user: $e');
    }
  }

  Future<void> acceptFriendRequest(String userId1, String userId2) async {
    try {
      final DocumentReference userRef1 =
          firestore.collection('users').doc(userId1);
      final DocumentReference userRef2 =
          firestore.collection('users').doc(userId2);

      // add each other to their friends lists
      await userRef1.update({
        'friends': FieldValue.arrayUnion(
            [userId2]), // add userId2 to userId1's friends list
        'friend_requests':
            FieldValue.arrayRemove([userId2]) // remove from friend_requests
      });

      await userRef2.update({
        'friends': FieldValue.arrayUnion(
            [userId1]), // add userId1 to userId2's friends list
        'requested_friends':
            FieldValue.arrayRemove([userId1]) // remove from requested_friends
      });

      debugPrint('Users $userId1 and $userId2 are now friends.');
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
    }
  }

  Future<void> sendRecieveRequest(String senderId, String receiverId) async {
    try {
      final DocumentReference senderRef =
          firestore.collection('users').doc(senderId);
      final DocumentReference receiverRef =
          firestore.collection('users').doc(receiverId);

      // add senderId to receiver's friend_requests list
      await receiverRef.update({
        'friend_requests': FieldValue.arrayUnion([senderId])
      });

      // add receiverId to sender's requested_friends list
      await senderRef.update({
        'requested_friends': FieldValue.arrayUnion([receiverId])
      });

      debugPrint('Friend request sent from $senderId to $receiverId.');
    } catch (e) {
      debugPrint('Error sending friend request: $e');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await firestore
          .collection('users') // specify the collection
          .doc(id) // specify the document ID
          .delete(); // delete the document
      debugPrint('User deleted successfully!');
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final QuerySnapshot querySnapshot =
          await firestore.collection('users').get();

      final List<UserModel> allUsers = [];
      final List<Map<String, dynamic>> users = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      for (int i = 0; i < users.length; i++) {
        final UserModel user = UserModel(
          users[i]['id'] ?? 'Unknown ID', // ccid
          users[i]['name'] ?? 'Unknown', // username
          users[i]['email'] ?? 'No email', // email
          users[i]['discipline'] ?? 'No discipline', // discipline
          users[i]['schedule'], // schedule (nullable)
          users[i]['education_lvl'] ?? 'No education', // educationLvl
          users[i]['degree'] ?? 'No degree', // degree
          users[i]['location_tracking'] ?? 'No tracking', // locationTracking
          users[i]['photoURL'] ?? '', // photoURL (nullable)
          users[i]['currentLocation'], // currentLocation (Map or null)
          users[i]['phone_number'],
          users[i]['insagram'],
        );
        allUsers.add(user);
      }
      return allUsers;
    } catch (e, stacktrace) {
      debugPrint('Error fetching users: $e');
      debugPrint('Stacktrace: $stacktrace');
      return [];
    }
  }

  Future<List<String>> getUserFriends(String userId) async {
    try {
      final DocumentSnapshot documentSnapshot =
          await firestore.collection('users').doc(userId).get();

      if (documentSnapshot.exists) {
        final Map<String, dynamic>? data =
            documentSnapshot.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('friends')) {
          final List<String> friends = List<String>.from(data['friends']);
          return friends;
        } else {
          debugPrint('User $userId has no friends listed.');
          return [];
        }
      } else {
        debugPrint('User does not exist.');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching user friends: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchUserData(String userId) async {
    try {
      final DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getFriendRequests(String userId) async {
    try {
      final DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('friend_requests')) {
          final List<String> friendRequestIds =
              List<String>.from(userData['friend_requests']);

          if (friendRequestIds.isEmpty) {
            return [];
          }

          // fetch details for each friend request sender
          final List<Map<String, dynamic>> friendRequestsDetails = [];
          for (String requesterId in friendRequestIds) {
            final DocumentSnapshot requesterDoc =
                await firestore.collection('users').doc(requesterId).get();

            if (requesterDoc.exists) {
              final Map<String, dynamic>? requesterData =
                  requesterDoc.data() as Map<String, dynamic>?;
              if (requesterData != null) {
                requesterData['id'] = requesterId; // include the requester's ID
                friendRequestsDetails.add(requesterData);
              }
            }
          }
          return friendRequestsDetails;
        } else {
          debugPrint('User $userId has no friend requests field.');
          return [];
        }
      } else {
        debugPrint('User does not exist.');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching friend requests: $e');
      return [];
    }
  }

  Future<List<String>> getRequestedFriends(String userId) async {
    try {
      final DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        if (userData != null && userData.containsKey('requested_friends')) {
          final List<String> requestedFriends =
              List<String>.from(userData['requested_friends']);
          return requestedFriends;
        } else {
          debugPrint('User $userId has no requested friends field.');
          return [];
        }
      } else {
        debugPrint('User does not exist.');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching requested friends: $e');
      return [];
    }
  }

  Future<void> declineFriendRequest(String requesterId, String userId) async {
    try {
      // remove from friend requests only
      await firestore.collection('users').doc(userId).update({
        'friend_requests': FieldValue.arrayRemove([requesterId]),
      });

      debugPrint('Friend request declined from $requesterId');
    } catch (e) {
      debugPrint('Error declining friend request: $e');
    }
  }

  Future<void> removeFriendFromUsers(String userId1, String userId2) async {
    try {
      final DocumentReference userRef1 =
          firestore.collection('users').doc(userId1);
      final DocumentReference userRef2 =
          firestore.collection('users').doc(userId2);

      // remove each other from friends lists
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

      debugPrint('Users $userId1 and $userId2 are fully disconnected.');
    } catch (e) {
      debugPrint('Error removing friend: $e');
    }
  }

  Future<void> addUserSchedule(String userId, String scheduleContent) async {
    try {
      final DocumentReference documentRef =
          firestore.collection('users').doc(userId);
      await documentRef.update({
        'schedule': scheduleContent,
      });
      debugPrint('User schedule added for user $userId');
    } catch (e) {
      debugPrint('Error adding schedule to user: $e');
    }
  }

  Future<void> markPopupAsSeen(String userId) async {
    try {
      final DocumentReference documentRef =
          firestore.collection('users').doc(userId);
      await documentRef.update({
        'hasSeenBottomPopup': true,
      });
      debugPrint('Popup marked as seen for user $userId');
    } catch (e) {
      debugPrint('Error marking popup as seen: $e');
    }
  }

  Future<void> updateUserProfile(
    String ccid, {
    String? discipline,
    String? educationLvl,
    String? degree,
  }) async {
    try {
      final DocumentReference documentRef =
          firestore.collection('users').doc(ccid);

      final Map<String, dynamic> data = {};
      if (discipline != null) {
        data['discipline'] = discipline;
      }
      if (educationLvl != null) {
        data['education_lvl'] = educationLvl;
      }
      if (degree != null) {
        data['degree'] = degree;
      }

      await documentRef.update(data);
      debugPrint('User profile updated for $ccid with data: $data');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }

  Future<void> updateUserLocationPreference(
      String ccid, String trackingOption) async {
    try {
      final DocumentReference docref = firestore.collection('users').doc(ccid);
      final Map<String, dynamic> updates = {};

      // directly assign because trackingOption can't be null
      updates['location_tracking'] = trackingOption;

      // optionally, you could remove this check as well because updates won't be empty
      if (updates.isEmpty) {
        debugPrint(
            'No location preference provided. skipping Firestore update.');
        return;
      }

      await docref.update(updates);
      debugPrint('Location preference updated for $ccid: $trackingOption');
    } catch (e) {
      debugPrint('Error updating location preference: $e');
    }
  }

  Future<void> updateUserLocation(
      String ccid, double latitude, double longitude) async {
    try {
      final DocumentReference docRef = firestore.collection('users').doc(ccid);
      await docRef.update({
        'currentLocation': {
          'lat': latitude,
          'lng': longitude,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
      debugPrint('Location updated for user $ccid');
    } catch (e) {
      debugPrint('Error updating location for user $ccid: $e');
    }
  }

  Future<void> updateUserPhoto(String ccid, String photoURL) async {
    try {
      final DocumentReference docRef = firestore.collection('users').doc(ccid);
      await docRef.update({
        'photoURL': photoURL, // updates the user's profile image URL
      });
      debugPrint('User photo updated for $ccid');
    } catch (e) {
      debugPrint('Error updating user photo: $e');
    }
  }

  Future<void> updateUserActiveStatus(String ccid, bool isActive) async {
    try {
      final DocumentReference docRef = firestore.collection('users').doc(ccid);
      await docRef.update({'isActive': isActive});
      debugPrint('User $ccid activity status updated: $isActive');
    } catch (e) {
      debugPrint('Error updating isActive status for user $ccid: $e');
    }
  }

  Future<void> uploadPhoneNumber(String userId, String phoneNumber) async {
    try {
      final DocumentReference docRef =
          firestore.collection('users').doc(userId);
      await docRef.set({'phone_number': phoneNumber}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error uploading phone number for user $userId: $e');
    }
  }

  Future<void> uploadInstagramLink(String userId, String instagramUrl) async {
    try {
      final DocumentReference docRef =
          firestore.collection('users').doc(userId);
      await docRef.set({'instagram': instagramUrl}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error uploading Instagram link for user $userId: $e');
    }
  }

  Future<Uint8List?> downloadImageBytes(String photoURL) async {
    try {
      final response = await http.get(Uri.parse(photoURL));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint(
            'Failed to download image, status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
    }
    return null;
  }

  Future<void> initializeLastSeen(List<dynamic> friends,
      ValueNotifier<Map<String, DateTime?>> notifier) async {
    final List<String> friendIds =
        friends.map<String>((friend) => friend.ccid as String).toList();
    final Map<String, DateTime?> initialData = {};

    for (final id in friendIds) {
      try {
        final DocumentSnapshot doc =
            await firestore.collection('users').doc(id).get();
        if (doc.exists) {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('currentLocation') &&
              data['currentLocation'] is Map &&
              data['currentLocation']['timestamp'] != null) {
            final Timestamp ts = data['currentLocation']['timestamp'];
            initialData[id] = ts.toDate();
          } else {
            initialData[id] = null;
          }
        } else {
          initialData[id] = null;
        }
      } catch (e) {
        debugPrint('Error fetching last seen for friend $id: $e');
        initialData[id] = null;
      }
    }
    notifier.value = initialData;
  }

  StreamSubscription subscribeToFriendLocations(List<String> friendIds,
          ValueNotifier<Map<String, DateTime?>> notifier) =>
      firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: friendIds)
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        final Map<String, DateTime?> updatedMap = {};
        for (var doc in snapshot.docs) {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('currentLocation') &&
              data['currentLocation'] is Map &&
              data['currentLocation']['timestamp'] != null) {
            final Timestamp ts = data['currentLocation']['timestamp'];
            updatedMap[doc.id] = ts.toDate();
          } else {
            updatedMap[doc.id] = null;
          }
        }
        notifier.value = updatedMap;
      });

  Future<void> toggleHideLocation(
      String currentUserId, String targetUserId, bool shouldHide) async {
    try {
      final currentUserRef = firestore.collection('users').doc(currentUserId);
      final targetUserRef = firestore.collection('users').doc(targetUserId);

      final currentUserSnapshot = await currentUserRef.get();
      final targetUserSnapshot = await targetUserRef.get();

      final Map<String, dynamic> currentUserData =
          currentUserSnapshot.data() ?? {};
      final Map<String, dynamic> targetUserData =
          targetUserSnapshot.data() ?? {};

      final List<String> locationHiddenFrom =
          List<String>.from(currentUserData['location_hidden_from'] ?? []);
      final List<String> hiddenFromMe =
          List<String>.from(targetUserData['hidden_from_me'] ?? []);

      if (shouldHide) {
        if (!locationHiddenFrom.contains(targetUserId)) {
          locationHiddenFrom.add(targetUserId);
        }
        if (!hiddenFromMe.contains(currentUserId)) {
          hiddenFromMe.add(currentUserId);
        }
      } else {
        locationHiddenFrom.remove(targetUserId);
        hiddenFromMe.remove(currentUserId);
      }

      await Future.wait([
        currentUserRef.update({'location_hidden_from': locationHiddenFrom}),
        targetUserRef.update({'hidden_from_me': hiddenFromMe}),
      ]);

      debugPrint(
          'Location visibility updated between $currentUserId and $targetUserId');
    } catch (e) {
      debugPrint('Error toggling hide location: $e');
    }
  }

  Future<Set<String>> getHiddenFromMeList(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null && data.containsKey('hidden_from_me')) {
        final list = List<String>.from(data['hidden_from_me']);
        return list.toSet();
      }
    } catch (e) {
      debugPrint('Error fetching hidden_from_me list: $e');
    }
    return {};
  }
}

final FirebaseService firebaseService =
    FirebaseService(firestore: FirebaseFirestore.instance);
