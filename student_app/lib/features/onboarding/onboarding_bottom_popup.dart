import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'onboarding_welcome_view.dart';
import 'onboarding_discipline_view.dart';
import 'onboarding_socials_view.dart';
import 'onboarding_location_view.dart';
import 'package:student_app/user_singleton.dart';
import 'package:student_app/services/firebase_service.dart';
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

  final GlobalKey<SocialsViewState> _scheduleKey =
      GlobalKey<SocialsViewState>();

  String? _selectedEducationLevel;
  String? _selectedDegree;
  String? _selectedMajor;
  String _selectedLocationOption = 'Only When Using App';

  final List<String> _educationLevels = ['Undergraduate', 'Graduate'];
  final List<String> _degreeOptions = [
    'Bachelor of Science',
    'Bachelor of Arts',
    'Bachelor of Engineering',
    'Master of Science',
    'Master of Arts',
    'Master of Engineering'
  ];
  final List<String> _majorOptions = [
    'Computer Science',
    'Business',
    'Engineering',
    'Psychology',
    'Biology',
    'Art'
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = _savedStep;
    developer.log('BottomPopup initState: _savedStep=$_savedStep',
        name: 'BottomPopup');
  }

  void _updateLocationPreference(String preference) {
    developer.log('Updating location preference to: $preference',
        name: 'BottomPopup');
    setState(() {
      _selectedLocationOption = preference;
    });
  }

  Widget _buildContent() {
    developer.log('Building content for step: $_currentStep',
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
            setState(() => _selectedEducationLevel = value);
          },
          onDegreeChanged: (value) {
            setState(() => _selectedDegree = value);
          },
          onMajorChanged: (value) {
            setState(() => _selectedMajor = value);
          },
          educationLevels: _educationLevels,
          degreeOptions: _degreeOptions,
          majorOptions: _majorOptions,
        );
      case 2:
        return SocialsView(key: _scheduleKey);
      case 3:
        return LocationView(
          onPreferenceUpdated: _updateLocationPreference,
          parentContext: Navigator.of(context, rootNavigator: true).context,
        );
      default:
        return Container();
    }
  }

  Widget _buildFloatingButton() {
    IconData icon;
    VoidCallback? onPressed;

    if (_currentStep < 3) {
      icon = Icons.arrow_forward;
      onPressed = () async {
        try {
          developer.log('Floating button pressed at step: $_currentStep',
              name: 'BottomPopup');

          if (_currentStep == 1) {
            if (_selectedEducationLevel == null ||
                _selectedDegree == null ||
                _selectedMajor == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Please complete all fields before proceeding.')),
              );
              return;
            }

            final ccid = AppUser.instance.ccid;
            if (ccid != null) {
              await updateUserProfile(
                ccid,
                discipline: _selectedMajor,
                educationLvl: _selectedEducationLevel,
                degree: _selectedDegree,
              );
            }
          }

          if (_currentStep == 2) {
            final success =
                await _scheduleKey.currentState?.submitPhoneNumber() ?? false;
            if (!success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Please enter and submit a valid phone number.')),
              );
              return;
            }
          }

          setState(() {
            _currentStep++;
            _savedStep = _currentStep;
          });
        } catch (e, stack) {
          developer.log('Exception in floating button onPressed: $e',
              name: 'BottomPopup', error: e, stackTrace: stack);
        }
      };
    } else {
      icon = Icons.check;
      onPressed = () async {
        try {
          final ccid = AppUser.instance.ccid;
          if (ccid != null) {
            await updateUserLocationPreference(ccid, _selectedLocationOption);
          }
          _savedStep = 0;
          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (e, stack) {
          developer.log('Exception in final step onPressed: $e',
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
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
                  offset: Offset(0, 3),
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
              color: const Color(0xFF396548).withValues(alpha: 0.5),
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
