import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:student_app/services/firebase_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseService firebaseService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firebaseService = FirebaseService(firestore: fakeFirestore);
  });

  group('FirebaseService', () {
    test('addUser adds a user to Firestore', () async {
      await firebaseService.addUser('John Doe', 'jdoe123',
          photoURL: 'http://example.com/photo.jpg');

      final userDoc =
          await fakeFirestore.collection('users').doc('jdoe123').get();
      expect(userDoc.exists, true);
      expect(userDoc.data()?['name'], 'John Doe');
      expect(userDoc.data()?['email'], 'jdoe123@ualberta.ca');
      expect(userDoc.data()?['photoURL'], 'http://example.com/photo.jpg');
    });

    test('acceptFriendRequest updates friends lists', () async {
      await fakeFirestore.collection('users').doc('user1').set({
        'friends': [],
        'friend_requests': ['user2'],
      });
      await fakeFirestore.collection('users').doc('user2').set({
        'friends': [],
        'requested_friends': ['user1'],
      });

      await firebaseService.acceptFriendRequest('user1', 'user2');

      final user1Doc =
          await fakeFirestore.collection('users').doc('user1').get();
      final user2Doc =
          await fakeFirestore.collection('users').doc('user2').get();

      expect(user1Doc.data()?['friends'], contains('user2'));
      expect(user1Doc.data()?['friend_requests'], isNot(contains('user2')));
      expect(user2Doc.data()?['friends'], contains('user1'));
      expect(user2Doc.data()?['requested_friends'], isNot(contains('user1')));
    });

    test('sendRecieveRequest adds friend requests and requested friends',
        () async {
      await fakeFirestore.collection('users').doc('sender').set({
        'requested_friends': [],
      });
      await fakeFirestore.collection('users').doc('receiver').set({
        'friend_requests': [],
      });

      await firebaseService.sendRecieveRequest('sender', 'receiver');

      final senderDoc =
          await fakeFirestore.collection('users').doc('sender').get();
      final receiverDoc =
          await fakeFirestore.collection('users').doc('receiver').get();

      expect(senderDoc.data()?['requested_friends'], contains('receiver'));
      expect(receiverDoc.data()?['friend_requests'], contains('sender'));
    });

    test('deleteUser removes a user from Firestore', () async {
      await fakeFirestore
          .collection('users')
          .doc('user1')
          .set({'name': 'John Doe'});

      await firebaseService.deleteUser('user1');

      final userDoc =
          await fakeFirestore.collection('users').doc('user1').get();
      expect(userDoc.exists, false);
    });

    test('getAllUsers retrieves all users', () async {
      await fakeFirestore
          .collection('users')
          .doc('user1')
          .set({'name': 'John Doe', 'email': 'jdoe@example.com'});
      await fakeFirestore
          .collection('users')
          .doc('user2')
          .set({'name': 'Jane Smith', 'email': 'jsmith@example.com'});

      final users = await firebaseService.getAllUsers();

      expect(users.length, 2);
      expect(users[0].username, 'John Doe');
      expect(users[1].username, 'Jane Smith');
    });

    test('getUserFriends retrieves friends list', () async {
      await fakeFirestore.collection('users').doc('user1').set({
        'friends': ['user2', 'user3']
      });

      final friends = await firebaseService.getUserFriends('user1');

      expect(friends, containsAll(['user2', 'user3']));
    });

    test('declineFriendRequest removes friend request', () async {
      await fakeFirestore.collection('users').doc('user1').set({
        'friend_requests': ['user2'],
      });

      await firebaseService.declineFriendRequest('user2', 'user1');

      final user1Doc =
          await fakeFirestore.collection('users').doc('user1').get();
      expect(user1Doc.data()?['friend_requests'], isNot(contains('user2')));
    });

    test('removeFriendFromUsers removes friends from both users', () async {
      await fakeFirestore.collection('users').doc('user1').set({
        'friends': ['user2'],
      });
      await fakeFirestore.collection('users').doc('user2').set({
        'friends': ['user1'],
      });

      await firebaseService.removeFriendFromUsers('user1', 'user2');

      final user1Doc =
          await fakeFirestore.collection('users').doc('user1').get();
      final user2Doc =
          await fakeFirestore.collection('users').doc('user2').get();

      expect(user1Doc.data()?['friends'], isNot(contains('user2')));
      expect(user2Doc.data()?['friends'], isNot(contains('user1')));
    });
  });
}
