import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'welcome_view.dart';
import 'discipline_view.dart';
import 'schedule_view.dart';
import 'location_permission.dart'; // This is the LocationView file.
import 'package:student_app/user_singleton.dart';
import 'package:student_app/utils/firebase_wrapper.dart';
import 'dart:developer' as developer;

class BottomPopup extends StatefulWidget {
  final String userName;
  const BottomPopup({super.key, required this.userName});
  String get firstName => userName.split(' ').first;
  @override
  BottomPopupState createState() => BottomPopupState();
}

class BottomPopupState extends State<BottomPopup> {
  static int _savedStep = 0;
  int _currentStep = 0;

  String? _selectedEducationLevel;
  String? _selectedDegree;
  String? _selectedMajor;
  String _selectedLocationOption = "Only When Using App";

  //change these based on actual degrees
  final List<String> _educationLevels = ["Undergraduate", "Graduate"];
  final List<String> _degreeOptions = [
    "Bachelor of Science",
    "Bachelor of Arts",
    "Bachelor of Engineering",
    "Master of Science",
    "Master of Arts",
    "Master of Engineering"
  ];
  final List<String> _majorOptions = [
    "Computer Science",
    "Business",
    "Engineering",
    "Psychology",
    "Biology",
    "Art"
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = _savedStep;
    developer.log("BottomPopup initState: _savedStep=$_savedStep",
        name: 'BottomPopup');
  }

  //location setter
  void _updateLocationPreference(String preference) {
    developer.log("Updating location preference to: $preference",
        name: 'BottomPopup');
    setState(() {
      _selectedLocationOption = preference;
    });
  }

  Widget _buildContent() {
    developer.log("Building content for step: $_currentStep",
        name: 'BottomPopup');
    switch (_currentStep) {
      case 0:
        return WelcomeView(firstName: widget.firstName);

      case 1:
        return DisciplineView(
          selectedEducationLevel: _selectedEducationLevel,
          selectedDegree: _selectedDegree,
          selectedMajor: _selectedMajor,
          onEducationLevelChanged: (value) {
            developer.log("Education level changed to: $value",
                name: 'BottomPopup');
            setState(() => _selectedEducationLevel = value);
          },
          onDegreeChanged: (value) {
            developer.log("Degree changed to: $value", name: 'BottomPopup');
            setState(() => _selectedDegree = value);
          },
          onMajorChanged: (value) {
            developer.log("Major changed to: $value", name: 'BottomPopup');
            setState(() => _selectedMajor = value);
          },
          educationLevels: _educationLevels,
          degreeOptions: _degreeOptions,
          majorOptions: _majorOptions,
        );

      case 2:
        return const ScheduleView();

      case 3:
        return LocationView(
          onPreferenceUpdated: _updateLocationPreference,
          parentContext: Navigator.of(context, rootNavigator: true).context,
        );

      default:
        return Container();
    }
  }

  //floating button
  Widget _buildFloatingButton() {
    IconData icon;
    VoidCallback? onPressed;

    if (_currentStep < 3) {
      icon = Icons.arrow_forward;
      onPressed = () async {
        try {
          developer.log("Floating button pressed at step: $_currentStep",
              name: 'BottomPopup');

          // On step 1, we ensure discipline fields are not empty before proceeding.
          if (_currentStep == 1) {
            if (_selectedEducationLevel == null ||
                _selectedDegree == null ||
                _selectedMajor == null) {
              developer.log("Incomplete discipline fields",
                  name: 'BottomPopup');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Please complete all fields before proceeding.')),
              );
              return;
            }

            final ccid = AppUser.instance.ccid;
            if (ccid != null) {
              developer.log("Updating user profile with discipline data",
                  name: 'BottomPopup');
              // This calls Firestore and updates the user doc
              await updateUserProfile(
                ccid,
                discipline: _selectedMajor,
                educationLvl: _selectedEducationLevel,
                degree: _selectedDegree,
              );
            }
          }

          setState(() {
            _currentStep++;
            _savedStep = _currentStep;
            developer.log("Moving to next step: $_currentStep",
                name: 'BottomPopup');
          });
        } catch (e, stack) {
          developer.log("Exception in floating button onPressed: $e",
              name: 'BottomPopup', error: e, stackTrace: stack);
        }
      };
    } else {
      // If we're on the last step => checkmark
      icon = Icons.check;
      onPressed = () async {
        try {
          developer.log(
              "Final step pressed. Saving location preference: $_selectedLocationOption",
              name: 'BottomPopup');
          final ccid = AppUser.instance.ccid;
          if (ccid != null) {
            await updateUserLocationPreference(ccid, _selectedLocationOption);
          }
          _savedStep = 0;
          developer.log("Popup flow complete. Closing BottomPopup",
              name: 'BottomPopup');
          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (e, stack) {
          developer.log("Exception in final step onPressed: $e",
              name: 'BottomPopup', error: e, stackTrace: stack);
        }
      };
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 1000),
      delay: const Duration(milliseconds: 1000),
      from: 70,
      child: Align(
        alignment: Alignment.bottomRight,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF396548),
                  Color(0xFF6B803D),
                  Color(0xFF909533),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.75;
    developer.log("Building BottomPopup widget with height: $sheetHeight",
        name: 'BottomPopup');
    return FadeInUp(
      duration: const Duration(milliseconds: 1000),
      delay: const Duration(milliseconds: 500),
      child: Container(
        height: sheetHeight,
        padding:
            const EdgeInsets.only(left: 30, top: 40, right: 30, bottom: 50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(60),
            topRight: Radius.circular(60),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF396548).withOpacity(0.5),
              offset: const Offset(0, -5),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContent(),
            const Spacer(),
            _buildFloatingButton(),
          ],
        ),
      ),
    );
  }
}
