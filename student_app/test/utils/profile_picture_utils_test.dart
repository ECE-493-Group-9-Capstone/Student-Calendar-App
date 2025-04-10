import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:student_app/utils/profile_picture_utils.dart';
import 'dart:typed_data';
import 'profile_picture_utils_test.mocks.dart' as profile_mocks;

@GenerateMocks([http.Client])
void main() {
  group('downloadImageBytes', () {
    test('returns image bytes when the request is successful', () async {
      final photoURL = 'https://example.com/image.jpg';
      final mockClient = profile_mocks.MockClient();
      when(mockClient.get(Uri.parse(photoURL))).thenAnswer(
        (_) async => http.Response('image data', 200),
      );

      final result = await downloadImageBytes(photoURL, client: mockClient);

      expect(result, isNotNull);
      expect(result, isA<Uint8List>());
    });

    test('returns null when the request fails', () async {
      final photoURL = 'https://example.com/image.jpg';
      final mockClient = profile_mocks.MockClient();
      when(mockClient.get(Uri.parse(photoURL))).thenAnswer(
        (_) async => http.Response('error', 404),
      );

      final result = await downloadImageBytes(photoURL, client: mockClient);

      expect(result, isNull);
    });
  });

  group('CachedProfileImage', () {
    testWidgets('displays fallback avatar when photoURL is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CachedProfileImage(
            photoURL: null,
            fallbackText: 'AB',
            size: 64,
          ),
        ),
      );

      expect(find.text('AB'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('displays CircularProgressIndicator while loading image',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CachedProfileImage(
            photoURL: 'https://example.com/image.jpg',
            size: 64,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
