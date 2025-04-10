import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'package:student_app/user_singleton.dart';
// FR21 - Map.Display - The system shall integrate with Google Maps API to render the campus 
// map. 
// FR22 - Map.Markers - The system shall display markers for study spots with ratings, events 
// with clickable descriptions, and friend locations. 
// FR23 - Map.Search - The system shall allow users to search for specific locations, events, or 
// friends on the map, displaying results as pins or overlays. 
// FR24 - Map.Update - The system shall update map markers in real time based on changes in the 
// data. 
class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _heartbeatTimer;
  double? _lastLatitude;
  double? _lastLongitude;

  // Starts live tracking in background mode.
  Future<void> startLiveTracking() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm != LocationPermission.always) {
      perm = await Geolocator.requestPermission();
      if (perm != LocationPermission.always) {
        await Geolocator.openAppSettings();
        return;
      }
    }
    await _testOneTimePosition();
    _subscribe(
      locationSettings: _buildSettings(isBackground: true),
      startHeartbeat: false,
    );
  }

  // Starts foreground tracking with heartbeat.
  Future<void> startForegroundTracking() async {
    if (!await _checkAndRequestPermissions(background: false)) {
      return;
    }
    await _testOneTimePosition();
    _subscribe(
      locationSettings: _buildSettings(isBackground: false),
      startHeartbeat: true,
    );
  }

  // Stops all tracking subscriptions and timers.
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Checks and requests necessary location permissions.
  Future<bool> _checkAndRequestPermissions({required bool background}) async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      enabled = await Geolocator.openLocationSettings();
      if (!enabled) {
        return false;
      }
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (background && perm == LocationPermission.whileInUse) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always;
  }

  // Gets a one-time position update.
  Future<void> _testOneTimePosition() async {
    try {
      await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('One‑time getCurrentPosition error: $e');
    }
  }

  // Builds location settings based on platform and tracking mode.
  LocationSettings _buildSettings({required bool isBackground}) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
        intervalDuration: Duration(seconds: isBackground ? 45 : 30),
        foregroundNotificationConfig: isBackground
            ? const ForegroundNotificationConfig(
                notificationTitle: 'Live Tracking Active',
                notificationText: 'Updating every 45 seconds',
                enableWakeLock: true,
              )
            : null,
      );
    }
    return (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)
        ? AppleSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            pauseLocationUpdatesAutomatically: false)
        : const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 0);
  }

  // Subscribes to the position stream and starts heartbeat if required.
  void _subscribe({
    required LocationSettings locationSettings,
    required bool startHeartbeat,
  }) {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (pos) async {
        _lastLatitude = pos.latitude;
        _lastLongitude = pos.longitude;
        final ccid = AppUser.instance.ccid;
        if (ccid != null) {
          await updateUserLocation(ccid, pos.latitude, pos.longitude);
          await AppUser.instance.refreshUserData();
        }
      },
      onError: (e) => debugPrint('Stream error: $e'),
    );
    if (startHeartbeat) {
      _startHeartbeat();
    }
  }

  // Starts a periodic heartbeat to update location timestamp.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_lastLatitude != null && _lastLongitude != null) {
        final ccid = AppUser.instance.ccid;
        if (ccid != null) {
          await updateUserLocation(ccid, _lastLatitude!, _lastLongitude!);
        }
      }
    });
  }
}
