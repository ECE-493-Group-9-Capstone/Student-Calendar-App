import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:student_app/pages/events_page.dart';
import 'package:student_app/pages/friends_page.dart';
import 'package:student_app/pages/map_page.dart';
import 'package:student_app/pages/onBoarding.dart';
import 'package:student_app/pages/home_page.dart';
import 'firebase_options.dart';
import 'user_singleton.dart';
import 'utils/firebase_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
    // return const MainPage();
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Loading state
        }

        // If user exists but is not in Firebase, log them out
        if (snapshot.hasData) {
          final user = snapshot.data;

          // Check if the user still exists in Firebase
          return FutureBuilder<bool>(
            future: _ensureUserExists(user),
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator()); // Wait for validation
              }

              // If the user is valid, show the main page
              if (asyncSnapshot.hasData && asyncSnapshot.data == true) {
                AppUser.instance.initialize(user!);
                return const MainPage();
              }

              // Otherwise, log out and redirect to onboarding
              FirebaseAuth.instance.signOut(); // Log out the invalid user
              return const Onboarding();
            },
          );
        }

        return const Onboarding();
      },
    );
  }
}

  /// Helper function to check if a user exists in Firebase
Future<bool> _ensureUserExists(User? user) async {
  if (user == null) return false;
  try {
    final idTokenResult = await user.getIdTokenResult(true);
    if (idTokenResult == null) return false;
  } catch (e) {
    return false;
  }
  final String ccid = user.email?.split('@')[0] ?? user.uid;
  final firestoreData = await fetchUserData(ccid);
  if (firestoreData == null) {
    await addUser(user.displayName ?? "New User", ccid, "");
  }

  // Always return true if everything is okay.
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


    // This function will show the location tracking dialog on first login.
  Future<void> _askLocationTrackingPreference() async {
    final option = await showLocationTrackingDialog(context);
    if (option != null) {
      // For demonstration, we just print the selected option.
      // Here you might want to update the user's document in Firestore with their preference.
      print("User selected location tracking: $option");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askLocationTrackingPreference();
    });
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: "Events",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "Friends",
          ),
        ],
      ),
    );
  }
}

enum LocationTrackingOption {live, onDemand}

//store the users choice of live tracking vs only when active
Future<LocationTrackingOption?> showLocationTrackingDialog(BuildContext context) {
  return showDialog<LocationTrackingOption>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Location Tracking"),
        content: const Text(
            "Do you want your location to be tracked live (continually updated) or only when using the app?"),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(LocationTrackingOption.onDemand);
            },
            child: const Text("Only When Using App"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(LocationTrackingOption.live);
            },
            child: const Text("Live Tracking"),
          ),
        ],
      );
    },
  );
}