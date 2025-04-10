import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:student_app/user_singleton.dart';
import 'package:student_app/services/firebase_service.dart';

class OnboardingSocialsView extends StatefulWidget {
  const OnboardingSocialsView({super.key});

  @override
  OnboardingSocialsViewState createState() => OnboardingSocialsViewState();
}

class OnboardingSocialsViewState extends State<OnboardingSocialsView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  String? _submittedPhoneNumber;
  String? _submittedInstagram;
  bool _isSubmitted = false;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(###) ###-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool hasSubmittedPhoneNumber() => _isSubmitted;

  String formatPrettyPhone(String input) {
    final digits = _getDigits(input);
    if (digits.length == 10) {
      final area = digits.substring(0, 3);
      final prefix = digits.substring(3, 6);
      final line = digits.substring(6, 10);
      return '($area) $prefix-$line';
    }
    return input;
  }

  Future<bool> submitPhoneNumber() async {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    final ccid = AppUser.instance.ccid;
    if (ccid == null) {
      return false;
    }

    final formattedPhone = formatPrettyPhone(_phoneController.text);
    final rawInstagramInput = _instagramController.text.trim();
    String? fullInstagramLink;

    if (rawInstagramInput.isNotEmpty) {
      fullInstagramLink = rawInstagramInput.startsWith('http')
          ? rawInstagramInput
          : 'https://instagram.com/$rawInstagramInput';
    }

    try {
      await firebaseService.uploadPhoneNumber(ccid, formattedPhone);

      if (fullInstagramLink != null) {
        await firebaseService.uploadInstagramLink(ccid, fullInstagramLink);
      }

      setState(() {
        _submittedPhoneNumber = formattedPhone;
        _submittedInstagram = fullInstagramLink;
        _isSubmitted = true;
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  String _getDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

  @override
  void dispose() {
    _phoneController.dispose();
    _instagramController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
padding: const EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF396548),
                    Color(0xFF6B803D),
                    Color(0xFF909533)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                blendMode: BlendMode.srcIn,
                child: const Text(
                  'Submit your phone number',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'We need your phone number to personalize your experience and '
                'help you connect with others.',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneFormatter],
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '(123) 456-7890',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final digitsOnly = _getDigits(value ?? '');
                  if (digitsOnly.length != 10) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _instagramController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Instagram (optional)',
                  hintText: 'your_username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 0),
              if (_submittedPhoneNumber != null)
                Text(
                  'Submitted: $_submittedPhoneNumber',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (_submittedInstagram != null)
                const Text(
                  'Instagram saved!',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      );
}
