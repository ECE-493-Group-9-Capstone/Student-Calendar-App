import 'package:firebase_auth/firebase_auth.dart';
import './utils/firebase_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import './utils/user.dart';

class AppUser {
  static final AppUser _instance = AppUser._internal(); // Singleton instance

  String? _ccid;
  String? _email;
  String? _name;
  String? _discipline;
  String? _educationLvl;
  String? _degree;
  String? _schedule; 
  String? _phoneNumber;
  String? _instagram;
  bool _isActive = false;
  List<UserModel> _friends = [];
  final ValueNotifier<List<UserModel>> friendsNotifier = ValueNotifier([]);
  List<Map<String, dynamic>> _friendRequests = [];
  List<String> _requestedFriends = [];
  final ValueNotifier<List<Map<String, dynamic>>> friendRequestsNotifier = ValueNotifier([]);

  bool _isLoaded = false;
  String? _locationTracking;
  Map<String, dynamic>? _currentLocation; 
  String? _photoURL;

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
    await _fetchAndUpdateUserData();
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
      _photoURL = userData['photoURL'];
      _discipline = userData['discipline'];
      _educationLvl = userData['education_lvl'];
      _degree = userData['degree'];
      _schedule = userData['schedule'];
      _locationTracking = userData['location_tracking'];
      _currentLocation = userData['currentLocation']; // current location
      _isActive = userData["isActive"] ?? false;
      _phoneNumber = userData["phone_number"];
      _instagram = userData["instagram"];
      List<String> processedFriends = List<String>.from(userData['friends'] ?? []);
      _friends = await _friendProcessor(processedFriends);
      friendsNotifier.value = List.from(_friends);
      _friendRequests = await getFriendRequests(_ccid!);
      friendRequestsNotifier.value = List.from(_friendRequests);
      _requestedFriends = await getRequestedFriends(_ccid!);
      debugPrint("User Data Loaded: $_name, $_discipline, Friends: $_friends");
    } else {
      debugPrint("No user data found in Firestore!");
    }
  }

  // Listen for real-time Firestore updates
  void _listenForUserUpdates() async {
    if (_ccid == null) return;
    _userSubscription = _firestore.collection('users').doc(_ccid).snapshots().listen((userDoc) async {
      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data();
        if (data != null) {
          _name = data['name'];
          _discipline = data['discipline'];
          _educationLvl = data['education_lvl'];
          _degree = data['degree'];
          _schedule = data['schedule'];
          _locationTracking = data['location_tracking'];
          _currentLocation = data['currentLocation'];
          _photoURL = data['photoURL'];
          _isActive = data["isActive"] ?? false;
          _phoneNumber = data["phone_number"];
          _instagram = data["instagram"];
          List<String> processedFriends = List<String>.from(data['friends'] ?? []);
          _friends = await _friendProcessor(processedFriends);
          friendsNotifier.value = List.from(_friends);

          _friendRequests = await getFriendRequests(_ccid!);
          friendRequestsNotifier.value = List.from(_friendRequests);

          _requestedFriends = await getRequestedFriends(_ccid!);
        }
        debugPrint("User data updated in real-time: $_name, $_discipline, Friends: $_friends");
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
          friends[i],                                      // ccid
          userData['name'] ?? "Unknown",                   // username
          userData["email"] ?? "No email",                 // email
          userData['discipline'] ?? "No discipline",       // discipline
          userData['schedule'] ?? "",                      // schedule
          userData['education_lvl'] ?? "No education",     // educationLvl
          userData['degree'] ?? "No degree",               // degree
          userData['location_tracking'] ?? "No tracking",  // locationTracking
          userData['photoURL'] ?? "",                      // photoURL
          userData['currentLocation'],                     // currentLocation
          userData['phone_number'],
          userData['instagram'],   
        );
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
    _instagram = null;
    _friendRequests = [];
    _isLoaded = false;
    _requestedFriends = [];
    _userSubscription?.cancel();
    _userSubscription = null;
    _locationTracking = null;
    _currentLocation = null;
    _photoURL = null;
    _isActive = false;
    _phoneNumber = null;
  }

  // Getters
  static AppUser get instance => _instance;
  String? get ccid => _ccid;
  String? get email => _email;
  String? get name => _name;
  String? get discipline => _discipline;
  String? get educationLvl => _educationLvl;
  String? get degree => _degree;
  String? get schedule => _schedule;
  String? get locationTracking => _locationTracking;
  String? get phoneNumber => _phoneNumber;
  String? get instagram => _instagram;
  Map<String, dynamic>? get currentLocation => _currentLocation;
  List<UserModel> get friends => _friends;
  List<Map<String, dynamic>> get friendRequests => _friendRequests;
  List<String> get requestedFriends => _requestedFriends;
  String? get photoURL => _photoURL;

  // Refresh user data from Firestore
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

  bool get isActive => _isActive;

  // Send a friend request or accept if one exists
  Future<void> sendFriendRequest(String receiverID) async {
    if (_ccid == null) return;
    bool requestExists = _friendRequests.any((request) => request['id'] == receiverID);
    if (requestExists) {
      debugPrint("Friend request from $receiverID already exists. Accepting request...");
      await addFriend(receiverID);
    } else {
      debugPrint("Sending friend request to $receiverID...");
      await sendRecieveRequest(_ccid!, receiverID);
    }
    await refreshUserData();
  }

  // Decline a friend request
  Future<void> declineFriend(String requesterId) async {
    if (_ccid == null) return;
    await declineFriendRequest(requesterId, _ccid!);
    await refreshUserData();
  }

  // Logout user & reset singleton data
  void logout() {
    FirebaseAuth.instance.signOut();
    _resetUserData();
    _isLoaded = false;
  }

  @override
  String toString() {
    return 'AppUser('
           'ccid: $_ccid, email: $_email, name: $_name, '
           'discipline: $_discipline, educationLvl: $_educationLvl, '
           'degree: $_degree, schedule: $_schedule, friends: $_friends, '
           'friendRequests: $_friendRequests, requestedFriends: $_requestedFriends, '
           'locationTracking: $_locationTracking, currentLocation: $_currentLocation, '
           'photoURL: $_photoURL'
           ')';
  }
}
