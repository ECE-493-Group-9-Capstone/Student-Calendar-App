import 'package:flutter/material.dart';
import 'package:student_app/pages/google_signin.dart';


class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height, // Not hardcoding
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF396548),
              Color(0xFF4F7143),
              Color(0xff5A7741),
              Color(0xFF657D3E),
              Color(0xFF6B803D),
              Color(0xFF70833C),
              Color(0xFF868F36),
              Color(0xFF909533),
            ],
            begin: Alignment.topLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 80.0),
            Image.asset(
              "images/BearBuddyLogo.PNG",
              height: 170,
              width: 150,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 40.0),
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0, left: 20.0, right: 20.0),
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Color(0xFF396548),
                            Color(0xFF6B803D),
                            Color(0xFF909533),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'CustomFont',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        "Log in using your UAlberta email address to continue. You’ll be redirected to your university portal for verification.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 40.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Container(
                        height: 60.0, 
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF396548),
                              Color(0xFF6B803D),
                              Color(0xFF909533),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        child: ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent, // Make the button background transparent
    shadowColor: Colors.transparent, 
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30.0),
    ),
  ),
  onPressed: () async {
    final authService = AuthService(); // Create an instance of AuthService
    final result = await authService.loginWithGoogle(); // Call the function

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: result.startsWith("Welcome") ? Colors.green : Colors.red,
          ),
        );
      }
    }
  },
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(
        "images/google.png", 
        height: 24.0,
        width: 24.0,
      ),
      SizedBox(width: 10.0),
      Text(
        "Sign in with Google",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),

                      ),
                    ),
                    Spacer(), 
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
