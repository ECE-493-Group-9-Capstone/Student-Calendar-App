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
import 'utils/social_graph.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SocialGraph().buildGraph();
  SocialGraph().startAutoUpdate(Duration(minutes: 5));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bottom Navigation Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(), // Use AuthWrapper as the initial screen
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Loading
        }

        if (snapshot.hasData) {
          final user = snapshot.data;
          return FutureBuilder<bool>(
            future: _ensureUserExists(user),
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Always call initialize to update AppUser with the current user's data
              if (asyncSnapshot.hasData && asyncSnapshot.data == true) {
                AppUser.instance.initialize(user!);
                return const MainPage();
              }

              // If user data is invalid, sign out and return onboarding.
              FirebaseAuth.instance.signOut();
              return const Onboarding();
            },
          );
        }

        // If not logged in
        return const Onboarding();
      },
    );
  }
}

/// Helper function to check if a user exists in Firebase
Future<bool> _ensureUserExists(User? user) async {
  if (user == null) return false;
  try {} catch (e) {
    return false;
  }
  final String ccid = user.email?.split('@')[0] ?? user.uid;
  final firestoreData = await fetchUserData(ccid);
  if (firestoreData == null) {
    await addUser(user.displayName ?? "New User", ccid);
  }
  return true;
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // List of pages to navigate between
  final List<Widget> _pages = [
    HomePage(),
    MapPage(),
    EventsPage(),
    FriendsPage(),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ccid = AppUser.instance.ccid;
      developer.log(ccid ?? 'ccid is null', name: 'AppUser');

      if (ccid != null) {
        // Fetch the user data from Firestore
        final userData = await fetchUserData(ccid);
        if (userData != null) {
          final bool hasSeenPopup = userData['hasSeenBottomPopup'] ?? false;
          if (!hasSeenPopup) {
            final String firstName =
                (AppUser.instance.name ?? 'Guest').split(' ').first;
            developer.log(firstName, name: 'AppUser');

            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              isDismissible: false,
              enableDrag: false,
              backgroundColor: Colors.transparent,
              builder: (context) => BottomPopup(userName: firstName),
            );

            // Log the user after the popup is done
            developer.log("AFTER bottom popup: ${AppUser.instance.toString()}",
                name: 'MainPageState');

            // Mark as seen
            await markPopupAsSeen(ccid);

            // Now that the user has chosen their location preference in the popup,
            // let's apply it.
            // (They might have chosen "Live Tracking" or "Only When Using App".)
            _applyLocationTracking();
          } else {
            // If they've seen the popup before, we can also apply tracking here
            // in case user preference is stored from a previous session.
            _applyLocationTracking();
          }
        }
      }
    });
  }

  /// This method checks AppUser's location tracking and starts the relevant approach.
  void _applyLocationTracking() {
    final trackingPref = AppUser.instance.locationTracking;
    developer.log("Applying location tracking preference: $trackingPref",
        name: 'MainPageState');

    // Hypothetical approach using a "LocationTrackingService".
    // If you haven't created one, adapt to your real code.
    // Stop any existing tracking first, to avoid duplication.
    LocationTrackingService().stopTracking();

    if (trackingPref == "Live Tracking") {
      // Start background/continuous tracking
      LocationTrackingService().startLiveTracking();
    } else if (trackingPref == "Only When Using App") {
      // Start foreground-only tracking
      // If you REALLY only want it while user is in the foreground,
      // you might also track app lifecycle events (didChangeAppLifecycleState)
      // and stop tracking in the background.
      LocationTrackingService().startForegroundTracking();
    } else {
      // "No Preference" or user hasn't chosen -> do nothing
      developer.log("No valid location preference set; not tracking location.",
          name: 'MainPageState');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Friends"),
        ],
      ),
    );
  }
}
