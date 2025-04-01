import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class LocationView extends StatefulWidget {
  final Function(String)
      onPreferenceUpdated; // Callback to update user preference
  final BuildContext parentContext; // Parent context for showing dialogs

  const LocationView({
    super.key,
    required this.onPreferenceUpdated,
    required this.parentContext,
  });

  @override
  LocationViewState createState() => LocationViewState();
}

class LocationViewState extends State<LocationView>
    with WidgetsBindingObserver {
  String _currentPreference = "Checking...";

  @override
  void initState() {
    super.initState();
    developer.log("[LocationView] initState", name: 'LocationView');
    WidgetsBinding.instance.addObserver(this);
    _checkCurrentPermission();
  }

  @override
  void dispose() {
    developer.log("[LocationView] dispose", name: 'LocationView');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log("[LocationView] Lifecycle state: $state",
        name: 'LocationView');
    if (state == AppLifecycleState.resumed) {
      _checkCurrentPermission();
    }
  }

  // Checks the current permission and updates the parent's callback
  Future<void> _checkCurrentPermission() async {
    try {
      developer.log("[LocationView] Checking location permissions...",
          name: 'LocationView');

      // Check locationAlways first
      PermissionStatus status = await Permission.locationAlways.status;
      String newPreference;

      if (status.isGranted) {
        newPreference = "Live Tracking"; // user grants "Always"
        widget.onPreferenceUpdated(newPreference);
      } else {
        // If not Always, check locationWhenInUse
        PermissionStatus fgStatus = await Permission.locationWhenInUse.status;
        if (fgStatus.isGranted) {
          newPreference = "Only When Using App";
          widget.onPreferenceUpdated(newPreference);
        } else {
          // If neither is granted => "No Permission Granted"
          newPreference = "No Permission Granted";
        }
      }

      setState(() => _currentPreference = newPreference);

      developer.log(
          "[LocationView] Updated _currentPreference: $_currentPreference",
          name: 'LocationView');
    } catch (e, stack) {
      developer.log("[LocationView] Exception in _checkCurrentPermission: $e",
          name: 'LocationView', error: e, stackTrace: stack);
    }
  }

  void _redirectToSettings() async {
    try {
      // If user already has "Live Tracking" or "Only When Using App," show a simple AlertDialog
      if (_currentPreference == "Live Tracking" ||
          _currentPreference == "Only When Using App") {
        _showAlreadySetDialog();
        developer.log("[LocationView] Already set. Showing AlertDialog.",
            name: 'LocationView');
        return;
      }

      // Otherwise, open app settings
      developer.log("[LocationView] Calling openAppSettings()",
          name: 'LocationView');
      await openAppSettings();
      await Future.delayed(const Duration(seconds: 2));
      _checkCurrentPermission();
    } catch (e, stack) {
      developer.log("[LocationView] Exception in _redirectToSettings: $e",
          name: 'LocationView', error: e, stackTrace: stack);
    }
  }

  void _showAlreadySetDialog() {
    showDialog(
      context: widget.parentContext,
      builder: (context) {
        Widget gradientText(String text,
            {double fontSize = 20,
            FontWeight fontWeight = FontWeight.bold,
            TextAlign textAlign = TextAlign.center}) {
          return ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Text(
              text,
              textAlign: textAlign,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  color: Colors.white),
            ),
          );
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF396548),
                  Color(0xFF6B803D),
                  Color(0xFF909533)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25.0),
            ),
            child: Container(
              margin: const EdgeInsets.all(3), // Border effect
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: gradientText("Permission Already Set", fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Permission already set. Change it in your device settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 25),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: gradientText("OK",
                          fontSize: 16, fontWeight: FontWeight.normal),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => gradient
              .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          blendMode: BlendMode.srcIn,
          child: const Text(
            "Location Tracking",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "Set your location tracking preference in settings.",
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _redirectToSettings,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Container(
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(23),
                ),
                child: _currentPreference == "Live Tracking" ||
                        _currentPreference == "Only When Using App"
                    ? Text(
                        _currentPreference,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF396548),
                        ),
                      )
                    : const Text(
                        "Go to Settings",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF396548),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
