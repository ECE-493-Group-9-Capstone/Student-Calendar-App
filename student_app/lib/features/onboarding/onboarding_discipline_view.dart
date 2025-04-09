import 'package:flutter/material.dart';

class DisciplineView extends StatelessWidget {
  final String? selectedEducationLevel;
  final String? selectedDegree;
  final String? selectedMajor;
  final Function(String?) onEducationLevelChanged;
  final Function(String?) onDegreeChanged;
  final Function(String?) onMajorChanged;
  final List<String> educationLevels;
  final List<String> degreeOptions;
  final List<String> majorOptions;

  const DisciplineView({
    super.key,
    required this.selectedEducationLevel,
    required this.selectedDegree,
    required this.selectedMajor,
    required this.onEducationLevelChanged,
    required this.onDegreeChanged,
    required this.onMajorChanged,
    required this.educationLevels,
    required this.degreeOptions,
    required this.majorOptions,
  });

  Widget buildDropdown(String hint, String? value, List<String> items,
          Function(String?) onChanged) =>
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 16),
              border: InputBorder.none,
            ),
            icon: const Icon(Icons.keyboard_arrow_down),
            items: items
                .map((item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item, style: const TextStyle(fontSize: 16)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            blendMode: BlendMode.srcIn,
            child: const Text(
              'What are you studying?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 25),
          Center(
            child: buildDropdown('Education Level', selectedEducationLevel,
                educationLevels, onEducationLevelChanged),
          ),
          const SizedBox(height: 35),
          Center(
            child: buildDropdown('Degree Program', selectedDegree,
                degreeOptions, onDegreeChanged),
          ),
          const SizedBox(height: 35),
          Center(
            child: buildDropdown(
                'Major', selectedMajor, majorOptions, onMajorChanged),
          ),
        ],
      );
}
