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

Future<void> addUser(String name, String ccid) async {
  try {
    DocumentReference documentRef =
        FirebaseFirestore.instance.collection('users').doc(ccid);
    await documentRef.set({
      'name': name,
      'friends': <String>[], // Ensure it's a List<String>
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
      'friends': FieldValue.arrayUnion([userId2]) // Add userId2 to userId1's friends list
    });

    await userRef2.update({
      'friends': FieldValue.arrayUnion([userId1]) // Add userId1 to userId2's friends list
    });

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

Future<void> getAllUsers() async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users') // Specify the collection
        .get(); // Fetch all documents in the collection

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      // Print document ID and data
      print("User ID: ${doc.id}, Data: ${doc.data()}");
    }
  } catch (e) {
    print("Error fetching users: $e");
  }
}
