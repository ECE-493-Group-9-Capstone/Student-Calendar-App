import 'package:firebase_auth/firebase_auth.dart';
import './utils/firebase_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import './utils/user.dart';

// Main class for logged in user
class AppUser {
  static final AppUser _instance = AppUser._internal(); // Singleton instance

  String? _ccid;
  String? _email;
  String? _name;
  String? _discipline;
  String? _educationLvl;
  String? _degree;
  String? _schedule;
  List<UserModel> _friends = [];
  List<Map<String, dynamic>> _friendRequests = [];
  List<String> _requestedFriends = [];
  bool _isLoaded = false;
  String? _locationTracking;
  Map<String, dynamic>? _currentLocation;

  StreamSubscription<DocumentSnapshot>? _userSubscription;
  // Private constructor
  AppUser._internal();
  // Factory constructor returns the same instance
  factory AppUser() {
    return _instance;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize AppUser with a Firebase User object
  Future<void> initialize(User firebaseUser) async {
    if (_isLoaded) return;

    _email = firebaseUser.email;
    _ccid = _email?.split('@')[0] ?? '';

    debugPrint("Initializing AppUser for: $_email ($_ccid)");
    // Fetch user data from Firestore
    await _fetchAndUpdateUserData();

    // Start listening for Firestore updates
    _listenForUserUpdates();

    _isLoaded = true;
  }

  // Fetch user data from Firestore
  Future<void> _fetchAndUpdateUserData() async {
    if (_ccid == null) return;

    debugPrint("Fetching Firestore data for user: $_ccid");

    Map<String, dynamic>? userData = await fetchUserData(_ccid!);
    if (userData != null) {
      _name = userData['name'];
      _discipline = userData['discipline'];
      _educationLvl = userData['education_lvl'];
      _degree = userData['degree'];
      _schedule = userData['schedule'];
      _locationTracking = userData['location_tracking'];
      _currentLocation = userData['currentLocation']; // Fetch current location
      List<String> proccessedFriends =
          List<String>.from(userData['friends'] ?? []);
      _friends = await _friendProcessor(proccessedFriends);
      _friendRequests = await getFriendRequests(_ccid!);
      _requestedFriends = await getRequestedFriends(_ccid!);
      debugPrint("User Data Loaded: $_name, $_discipline, Friends: $_friends");
    } else {
      debugPrint("No user data found in Firestore!");
    }
  }

  // Listen for real-time Firestore updates
  void _listenForUserUpdates() async {
    if (_ccid == null) return;
    _userSubscription = _firestore
        .collection('users')
        .doc(_ccid)
        .snapshots()
        .listen((userDoc) async {
      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data();
        if (data != null) {
          _name = data['name'];
          _discipline = data['discipline'];
          _educationLvl = data['education_lvl'];
          _degree = data['degree'];
          _schedule = data['schedule'];
          _locationTracking = data['location_tracking'];
          _currentLocation = data['currentLocation']; // Update current location
          List<String> proccessedFriends =
              List<String>.from(data['friends'] ?? []);
          _friends = await _friendProcessor(proccessedFriends);
          _friendRequests = await getFriendRequests(_ccid!);
          _requestedFriends = await getRequestedFriends(_ccid!);
        }
        debugPrint(
            "User data updated in real-time: $_name, $_discipline, Friends: $_friends");
      }
    });
  }

  Future<List<UserModel>> _friendProcessor(List<String> friends) async {
    List<UserModel> userFriends = [];
    for (int i = 0; i < friends.length; i++) {
      debugPrint(friends[i]);
      Map<String, dynamic>? userData = await fetchUserData(friends[i]);
      if (userData != null) {
        UserModel userModel = UserModel(
            friends[i],
            userData['name'],
            userData["email"],
            userData['discipline'],
            userData["schedule"],
            userData["education_1v1"],
            userData["degree"],
            userData["location_tracking"]);
        userFriends.add(userModel);
      } else {
        debugPrint("No user data found in Firestore!");
      }
    }
    return userFriends;
  }

  // Reset user data (for logout)
  void _resetUserData() {
    _ccid = null;
    _email = null;
    _name = null;
    _discipline = null;
    _educationLvl = null;
    _degree = null;
    _schedule = null;
    _friends = [];
    _friendRequests = [];
    _isLoaded = false;
    _requestedFriends = [];
    _userSubscription?.cancel();
    _userSubscription = null;
    _locationTracking = null;
    _currentLocation = null;
  }

  // Getter methods for user data
  static AppUser get instance => _instance;
  String? get ccid => _ccid;
  String? get email => _email;
  String? get name => _name;
  String? get discipline => _discipline;
  String? get educationLvl => _educationLvl;
  String? get degree => _degree;
  String? get schedule => _schedule;
  String? get locationTracking => _locationTracking;
  Map<String, dynamic>? get currentLocation => _currentLocation;
  List<UserModel> get friends => _friends;
  List<Map<String, dynamic>> get friendRequests => _friendRequests;
  List<String> get requestedFriends => _requestedFriends;

  // Manually refresh user data from Firestore
  Future<void> refreshUserData() async {
    await _fetchAndUpdateUserData();
  }

  // Add a friend
  Future<void> addFriend(String friendId) async {
    if (_ccid == null) return;
    await acceptFriendRequest(_ccid!, friendId);
    await refreshUserData();
  }

  Future<void> removeFriend(String friendId) async {
    if (_ccid == null) return;
    await removeFriendFromUsers(_ccid!, friendId);
    await refreshUserData();
  }

  // send a friend request or accept if one already exists
  Future<void> sendFriendRequest(String receiverID) async {
    if (_ccid == null) return;

    // Check if the receiver has already sent a friend request to the current user
    bool requestExists =
        _friendRequests.any((request) => request['id'] == receiverID);

    if (requestExists) {
      // Accept the friend request instead
      debugPrint(
          "Friend request from $receiverID already exists. Accepting request...");
      await addFriend(receiverID);
    } else {
      // Otherwise, send a new friend request
      debugPrint("Sending friend request to $receiverID...");
      await sendRecieveRequest(_ccid!, receiverID);
    }

    // Refresh user data to update friend requests and friends list
    await refreshUserData();
  }

  // Decline a friend request**
  Future<void> declineFriend(String requesterId) async {
    if (_ccid == null) return;
    await declineFriendRequest(requesterId, _ccid!);
    await refreshUserData();
  }

  // Logout user & reset singleton data**
  void logout() {
    FirebaseAuth.instance.signOut();
    _resetUserData();
    _isLoaded = false;
  }

  String toString() {
    return 'AppUser('
        'ccid: $_ccid, email: $_email, name: $_name, '
        'discipline: $_discipline, educationLvl: $_educationLvl, '
        'degree: $_degree, schedule: $_schedule, friends: $_friends, '
        'friendRequests: $_friendRequests, requestedFriends: $_requestedFriends, '
        'locationTracking: $_locationTracking, currentLocation: $_currentLocation)';
  }
}
