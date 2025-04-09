import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

class WelcomeView extends StatelessWidget {
  final String firstName;

  const WelcomeView({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting text with gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF396548),
                Color(0xFF6B803D),
                Color(0xFF909533),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            blendMode: BlendMode.srcIn,
            child: Text(
              'Hello $firstName,',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Welcome to Bear Buddy! Let's get started and set up your account.",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          const SizedBox(height: 20),
          Center(
            child: FadeInUp(
              duration: const Duration(milliseconds: 1000),
              delay: const Duration(milliseconds: 1500),
              from: 50,
              child: SizedBox(
                height: 200, // adjust as needed
                child: Image.asset(
                  'assets/bear-wave-ezgif.com-gif-maker (1).gif',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      );
}
