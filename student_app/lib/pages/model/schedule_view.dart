import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:student_app/user_singleton.dart';
import 'package:student_app/utils/firebase_wrapper.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  ScheduleViewState createState() => ScheduleViewState();
}

class ScheduleViewState extends State<ScheduleView> {
  String? _selectedFileName;
  // We no longer display file content

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF396548), Color(0xFF6B803D), Color(0xFF909533)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          blendMode: BlendMode.srcIn,
          child: const Text(
            "Upload your schedule",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.only(bottom: 10, left: 3, right: 16.0),
          child: Text(
            "We need your schedule so we can suggest friends in your classes. Your schedule's .ics file can be found on Beartracks under 'My Schedule and Exams.'",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['ics'],
              );
              if (result != null && result.files.single.path != null) {
                String fileName = result.files.single.name;
                String filePath = result.files.single.path!;
                File file = File(filePath);
                // Read the file content as a string
                String fileContent = await file.readAsString();

                // Ensure the user's ccid is available before uploading
                if (AppUser.instance.ccid != null) {
                  await addUserSchedule(AppUser.instance.ccid!, fileContent);
                } else {
                  debugPrint("User ID not found. Cannot upload schedule.");
                }

                setState(() {
                  _selectedFileName = fileName;
                });
                debugPrint("Selected file: $fileName");
              } else {
                debugPrint("File picking cancelled");
              }
            },
            child: Container(
              padding: const EdgeInsets.all(2),
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
                borderRadius: BorderRadius.circular(25),
              ),
              child: Container(
                width: 340,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: _selectedFileName != null
                      ? ShaderMask(
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
                          child: const Icon(
                            Icons.check,
                            size: 40,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.insert_drive_file,
                              color: Colors.grey,
                              size: 30,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Select file",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
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
