import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:student_app/pages/events_page.dart';
import 'package:student_app/pages/friends_page.dart';
import 'package:student_app/pages/map_page.dart';
import 'package:student_app/pages/on_boarding.dart';
import 'package:student_app/pages/home_page.dart';
import 'firebase_options.dart';
import 'user_singleton.dart';
import 'utils/firebase_wrapper.dart';
import 'pages/model/bottom_popup.dart';
import 'dart:developer' as developer;
import 'utils/location_service.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(android: androidInit),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Bottom Navigation Example',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthWrapper(),
      );
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            final user = snapshot.data!;
            return FutureBuilder<bool>(
              future: _ensureUserExists(user),
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (asyncSnapshot.data == true) {
                  developer.log('✅ User exists & initialized',
                      name: 'AuthWrapper');
                  AppUser.instance.initialize(user);
                  developer.log(
                      'AppUser instance: ${AppUser.instance.toString()}',
                      name: 'AuthWrapper');
                  return const MainPage();
                }
                FirebaseAuth.instance.signOut();
                return const Onboarding();
              },
            );
          }
          return const Onboarding();
        },
      );
}

Future<bool> _ensureUserExists(User user) async {
  final ccid = user.email?.split('@')[0] ?? user.uid;
  developer.log('Checking Firestore for CCID: $ccid',
      name: '_ensureUserExists');
  final firestoreData = await fetchUserData(ccid);
  if (firestoreData == null) {
    await addUser(user.displayName ?? 'New User', ccid,
        photoURL: user.photoURL);
    developer.log('🆕 Created new Firestore user', name: '_ensureUserExists');
  } else if (user.photoURL != null &&
      firestoreData['photoURL'] != user.photoURL) {
    await updateUserPhoto(ccid, user.photoURL!);
    developer.log('🔄 Updated photoURL in Firestore',
        name: '_ensureUserExists');
  }
  return true;
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  AppLifecycleState? _lastState;
  Timer? _debounce;

  // Lazy-load pages list: initially null so that pages are built only on first request.
  final List<Widget?> _pages = List<Widget?>.filled(4, null, growable: false);
  final GlobalKey<MapPageState> _mapPageKey = GlobalKey<MapPageState>();

  // Lazy builder: only build a page when it's first requested.
  Widget _getPage(int index) {
    if (_pages[index] == null) {
      switch (index) {
        case 0:
          _pages[index] = HomePage();
          break;
        case 1:
          _pages[index] = MapPage(key: _mapPageKey);
          break;
        case 2:
          _pages[index] = EventsPage();
          break;
        case 3:
          _pages[index] = FriendsPage();
          break;
      }
    }
    return _pages[index]!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Schedule _initializeApp() to run after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_lastState == state) return;
      _lastState = state;

      final pref = AppUser.instance.locationTracking;
      developer.log('MAJOR Lifecycle → $state | pref=$pref', name: 'MainPage');

      // Stop current tracking first.
      LocationTrackingService().stopTracking();

      if (state == AppLifecycleState.resumed) {
        developer.log('➡️ Starting FOREGROUND tracking', name: 'MainPage');
        LocationTrackingService().startForegroundTracking();
      } else if ((state == AppLifecycleState.paused ||
              state == AppLifecycleState.detached) &&
          pref == 'Live Tracking') {
        developer.log('➡️ Starting BACKGROUND tracking', name: 'MainPage');
        LocationTrackingService().startLiveTracking();
      } else {
        developer.log('➡️ Tracking stopped', name: 'MainPage');
      }
    });
  }

  Future<void> _initializeApp() async {
    final ccid = AppUser.instance.ccid;
    developer.log('AppUser CCID = $ccid', name: 'MainPage');
    if (ccid == null) return;

    // Run the bottom popup check after a short delay.
    // The popup will only appear if the user hasn't seen it already.
    Future.delayed(const Duration(seconds: 2), () async {
      final userData = await fetchUserData(ccid);
      // The bottom popup check will be skipped if hasSeenBottomPopup is true.
      if (!(userData?['hasSeenBottomPopup'] ?? false)) {
        final firstName = (AppUser.instance.name ?? 'Guest').split(' ').first;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: true, // Allow dismissal for smoother UX.
          enableDrag: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BottomPopup(userName: firstName),
        );
        await markPopupAsSeen(ccid);
      }
    });

    // Defer location tracking until after the UI is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('➡️ Starting FOREGROUND tracking (deferred)',
          name: 'MainPage');
      LocationTrackingService().startForegroundTracking();
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) _mapPageKey.currentState?.refreshMarkers();
  }

  Widget _buildNavItem(IconData icon, bool isSelected) => isSelected
      ? Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Icon(icon, size: 30, color: const Color(0xFF396548)),
        )
      : Icon(icon, size: 30, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: List.generate(4, (index) {
          return Offstage(
            offstage: _currentIndex != index,
            child: TickerMode(
              enabled: _currentIndex == index,
              child: _getPage(index),
            ),
          );
        }),
      ),
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF396548),
                  const Color(0xFF6B803D),
                  const Color(0xFF909533)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          CurvedNavigationBar(
            index: _currentIndex,
            height: 55,
            backgroundColor: Colors.transparent,
            buttonBackgroundColor: Colors.transparent,
            animationCurve: Curves.easeInOut,
            animationDuration: const Duration(milliseconds: 300),
            items: [
              _buildNavItem(Icons.home, _currentIndex == 0),
              _buildNavItem(Icons.map, _currentIndex == 1),
              _buildNavItem(Icons.event, _currentIndex == 2),
              _buildNavItem(Icons.group, _currentIndex == 3),
            ],
            onTap: _onTabTapped,
            color: Colors.transparent.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
