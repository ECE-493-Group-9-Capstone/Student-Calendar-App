import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:student_app/features/events/events_page.dart';
import 'package:student_app/features/friends/friends_page.dart';
import 'package:student_app/features/map/map_page.dart';
import 'package:student_app/features/auth/auth_login_page.dart';
import 'package:student_app/features/home/home_page.dart';
import 'firebase_options.dart';
import 'user_singleton.dart';
import 'services/firebase_service.dart';
import 'features/onboarding/onboarding_bottom_popup.dart';
import 'services/map_service.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/auth_service.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  final authService = AuthService();
  await authService.getAccessToken();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Bottom Navigation Example',
        theme: ThemeData(primarySwatch: Colors.blue),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        navigatorObservers: [routeObserver],
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
                  AppUser.instance.initialize(user);
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
  final firestoreData = await firebaseService.fetchUserData(ccid);
  if (firestoreData == null) {
    await firebaseService.addUser(user.displayName ?? 'New User', ccid,
        photoURL: user.photoURL);
  } else if (user.photoURL != null &&
      firestoreData['photoURL'] != user.photoURL) {
    await firebaseService.updateUserPhoto(ccid, user.photoURL!);
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
  final List<Widget?> _pages = List<Widget?>.filled(4, null, growable: false);
  final GlobalKey<MapPageState> _mapPageKey = GlobalKey<MapPageState>();

  Widget _getPage(int index) {
    if (_pages[index] == null) {
      switch (index) {
        case 0:
          _pages[index] = const HomePage();
          break;
        case 1:
          _pages[index] = const FriendsPage();
          break;
        case 2:
          _pages[index] = MapPage(key: _mapPageKey);
          break;
        case 3:
          _pages[index] = const EventsPage();
          break;
      }
    }
    return _pages[index]!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (_lastState == state) {
        return;
      }
      _lastState = state;
      final pref = AppUser.instance.locationTracking;
      final ccid = AppUser.instance.ccid;
      if (ccid != null) {
        await firebaseService.updateUserActiveStatus(
            ccid, state == AppLifecycleState.resumed);
        MapService().stopTracking();
        final userData = await firebaseService.fetchUserData(ccid);
        final hasSeen = userData?['hasSeenBottomPopup'] ?? false;
        if (hasSeen) {
          if (state == AppLifecycleState.resumed) {
            MapService().startForegroundTracking();
          } else if ((state == AppLifecycleState.paused ||
                  state == AppLifecycleState.detached) &&
              pref == 'Live Tracking') {
            MapService().startLiveTracking();
          }
        }
      }
    });
  }

  Future<void> _initializeApp() async {
    final ccid = AppUser.instance.ccid;
    if (ccid == null) {
      return;
    }
    Future.delayed(const Duration(seconds: 2), () async {
      final userData = await firebaseService.fetchUserData(ccid);
      final bool hasSeen = userData?['hasSeenBottomPopup'] ?? false;
      if (!hasSeen) {
        final firstName = (AppUser.instance.name ?? 'Guest').split(' ').first;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: true,
          enableDrag: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BottomPopup(userName: firstName),
        );
        await firebaseService.markPopupAsSeen(ccid);
        final updatedData = await firebaseService.fetchUserData(ccid);
        final updatedPref = updatedData?['location_tracking'];
        if (updatedPref == 'Live Tracking' ||
            updatedPref == 'Only When Using App') {
          MapService().startForegroundTracking();
        }
      } else {
        final pref = AppUser.instance.locationTracking;
        if (pref == 'Live Tracking' || pref == 'Only When Using App') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            MapService().startForegroundTracking();
          });
        }
      }
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 2) {
      _mapPageKey.currentState?.refreshMarkers();
    }
  }

  Widget _buildNavItem(IconData icon, bool isSelected) => isSelected
      ? Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Icon(icon, size: 30, color: const Color(0xFF396548)),
        )
      : Icon(icon, size: 30, color: Colors.white);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: List.generate(
              4,
              (index) => Offstage(
                    offstage: _currentIndex != index,
                    child: TickerMode(
                      enabled: _currentIndex == index,
                      child: _getPage(index),
                    ),
                  )),
        ),
        bottomNavigationBar: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 55,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF396548),
                    Color(0xFF6B803D),
                    Color(0xFF909533),
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
                _buildNavItem(Icons.group, _currentIndex == 1),
                _buildNavItem(Icons.map, _currentIndex == 2),
                _buildNavItem(Icons.event, _currentIndex == 3),
              ],
              onTap: _onTabTapped,
              color: Colors.transparent.withValues(alpha: 0.3),
            ),
          ],
        ),
      );
}
