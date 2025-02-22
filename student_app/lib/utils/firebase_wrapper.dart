import 'package:cloud_firestore/cloud_firestore.dart';

void readDocument(String id) async {
  try {
    DocumentSnapshot documentSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(id).get();

    if (documentSnapshot.exists) {
      Map<String, dynamic>? data =
          documentSnapshot.data() as Map<String, dynamic>?;
      print("Document Data: $data");
    } else {
      print("Document does not exist");
    }
  } catch (e) {
    print("Error reading document: $e");
  }
}

Future<void> addUser(String name, String ccid, String discipline) async {
  try {
    DocumentReference documentRef =
        FirebaseFirestore.instance.collection('users').doc(ccid);
    await documentRef.set({
      'name': name,
      'discipline': discipline,
      'friends': <String>[], // Ensure it's a List<String>
      'friend_requests': <String>[],
    });
    print("User added with doc ID: $ccid");
  } catch (e) {
    print("Error adding user: $e");
  }
}

Future<void> addFriend(String userId1, String userId2) async {
  try {
    DocumentReference userRef1 =
        FirebaseFirestore.instance.collection('users').doc(userId1);
    DocumentReference userRef2 =
        FirebaseFirestore.instance.collection('users').doc(userId2);

    // Add each other to their friends lists
    await userRef1.update({
      'friends': FieldValue.arrayUnion(
          [userId2]) // Add userId2 to userId1's friends list
    });

    await userRef2.update({
      'friends': FieldValue.arrayUnion(
          [userId1]) // Add userId1 to userId2's friends list
    });

    await userRef1.update(({
      'friend_requests': FieldValue.arrayRemove([userId2])
    }));

    print("Users $userId1 and $userId2 are now friends.");
  } catch (e) {
    print("Error adding friend: $e");
  }
}

Future<void> deleteUser(String id) async {
  try {
    await FirebaseFirestore.instance
        .collection('users') // Specify the collection
        .doc(id) // Specify the document ID
        .delete(); // Delete the document
    print("User deleted successfully!");
  } catch (e) {
    print("Error deleting user: $e");
  }
}

Future<List<QueryDocumentSnapshot>> getAllUsers() async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users') // Specify the Firestore collection
        .get(); // Fetch all documents in the collection

    List<QueryDocumentSnapshot> allUsers =
        querySnapshot.docs; // Store the documents

    // Debugging: Print user data
    for (var doc in allUsers) {
      print("User ID: ${doc.id}, Data: ${doc.data()}");
    }
    return allUsers;
  } catch (e) {
    print("Error fetching users: $e");
    return []; // Return an empty list in case of error
  }
}

Future<List<String>> getUserFriends(String userId) async {
  try {
    DocumentSnapshot documentSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (documentSnapshot.exists) {
      Map<String, dynamic>? data =
          documentSnapshot.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey('friends')) {
        List<String> friends = List<String>.from(data['friends']);
        print("User $userId friends: $friends");
        return friends;
      } else {
        print("User $userId has no friends listed.");
        return [];
      }
    } else {
      print("User does not exist.");
      return [];
    }
  } catch (e) {
    print("Error fetching user friends: $e");
    return [];
  }
}

Future<Map<String, dynamic>?> fetchUserData(String userId) async {
  try {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      return null;
    }
  } catch (e) {
    print("Error fetching user data: $e");
    return null;
  }
}

Future<List<Map<String, dynamic>>> getFriendRequests(String userId) async {
  try {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null && userData.containsKey('friend_requests')) {
        List<String> friendRequestIds =
            List<String>.from(userData['friend_requests']);

        if (friendRequestIds.isEmpty) {
          print("User $userId has no friend requests.");
          return [];
        }

        // Fetch details for each friend request sender
        List<Map<String, dynamic>> friendRequestsDetails = [];
        for (String requesterId in friendRequestIds) {
          DocumentSnapshot requesterDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(requesterId)
              .get();

          if (requesterDoc.exists) {
            Map<String, dynamic>? requesterData =
                requesterDoc.data() as Map<String, dynamic>?;
            if (requesterData != null) {
              requesterData['id'] = requesterId; // Include the requester's ID
              friendRequestsDetails.add(requesterData);
            }
          }
        }

        print("Friend Requests for User $userId: $friendRequestsDetails");
        return friendRequestsDetails;
      } else {
        print("User $userId has no friend requests field.");
        return [];
      }
    } else {
      print("User does not exist.");
      return [];
    }
  } catch (e) {
    print("Error fetching friend requests: $e");
    return [];
  }
}

Future<void> declineFriendRequest(String requesterId, String userId) async {
  try {
    // Remove from friend requests only
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'friend_requests': FieldValue.arrayRemove([requesterId]),
    });

    print("Friend request declined from $requesterId");
  } catch (e) {
    print("Error declining friend request: $e");
  }
}
