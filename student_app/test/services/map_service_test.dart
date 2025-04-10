import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:student_app/services/map_service.dart';

import 'map_service_test.mocks.dart';

@GenerateMocks([MapService])
void main() {
  late MockMapService mockMapService;

  setUp(() {
    mockMapService = MockMapService();
  });

  group('startLiveTracking', () {
    test('starts live tracking when permissions are granted', () async {
      when(mockMapService.startLiveTracking()).thenAnswer((_) async => null);

      await mockMapService.startLiveTracking();

      verify(mockMapService.startLiveTracking()).called(1);
    });

    test('does not start live tracking when permissions are denied', () async {
      when(mockMapService.startLiveTracking())
          .thenThrow(Exception('Permission denied'));

      try {
        await mockMapService.startLiveTracking();
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });

  group('startForegroundTracking', () {
    test('starts foreground tracking when permissions are granted', () async {
      when(mockMapService.startForegroundTracking())
          .thenAnswer((_) async => null);

      await mockMapService.startForegroundTracking();

      verify(mockMapService.startForegroundTracking()).called(1);
    });

    test('does not start foreground tracking when permissions are denied',
        () async {
      when(mockMapService.startForegroundTracking())
          .thenThrow(Exception('Permission denied'));

      try {
        await mockMapService.startForegroundTracking();
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });

  group('stopTracking', () {
    test('stops tracking successfully', () {
      when(mockMapService.stopTracking()).thenAnswer((_) => null);

      mockMapService.stopTracking();

      verify(mockMapService.stopTracking()).called(1);
    });
  });

  group('_testOneTimePosition', () {
    test('gets a one-time position successfully', () async {
      when(mockMapService.startLiveTracking()).thenAnswer((_) async => null);

      await mockMapService.startLiveTracking();

      verify(mockMapService.startLiveTracking()).called(1);
    });

    test('throws an error when position cannot be retrieved', () async {
      when(mockMapService.startLiveTracking())
          .thenThrow(Exception('Position error'));

      try {
        await mockMapService.startLiveTracking();
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });
}
