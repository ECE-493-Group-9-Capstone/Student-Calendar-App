import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'firebase_wrapper.dart';
import 'package:student_app/user_singleton.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  StreamSubscription<Position>? _positionSubscription;

 Future<void> startLiveTracking() async {
  debugPrint('🔄 startLiveTracking() called');

  // 1️⃣ Confirm device‑level Location Services are ON
  if (!await Geolocator.isLocationServiceEnabled()) {
    debugPrint('❌ Location services are OFF → opening settings');
    await Geolocator.openLocationSettings();
    return;
  }

  // 2️⃣ Confirm “Allow all the time” permission
  var perm = await Geolocator.checkPermission();
  if (perm != LocationPermission.always) {
    debugPrint('❌ Missing background permission → requesting');
    perm = await Geolocator.requestPermission();
    if (perm != LocationPermission.always) {
      debugPrint('❌ User did not grant ALWAYS permission → abort');
      await Geolocator.openAppSettings();
      return;
    }
  }

  // 3️⃣ Show notification immediately by subscribing
  await _testOneTimePosition();
  _subscribe(locationSettings: _buildSettings(isBackground: true));
}

  Future<void> startForegroundTracking() async {
    debugPrint('🔄 startForegroundTracking() called');
    if (!await _checkAndRequestPermissions(background: false)) return;
    await _testOneTimePosition();
    _subscribe(locationSettings: _buildSettings(isBackground: false));
  }

  void stopTracking() {
    debugPrint('⛔ stopTracking() called');
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<bool> _checkAndRequestPermissions({required bool background}) async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('📡 Service enabled = $enabled');
    if (!enabled) {
      enabled = await Geolocator.openLocationSettings();
      debugPrint('📡 Service after open settings = $enabled');
      if (!enabled) return false;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    debugPrint('🔐 Current permission = $perm');
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (background && perm == LocationPermission.whileInUse) {
      perm = await Geolocator.requestPermission();
    }
    debugPrint('🔐 Final permission = $perm');
    return perm == LocationPermission.always;
  }

  Future<void> _testOneTimePosition() async {
    try {
      final Position p = await Geolocator.getCurrentPosition();
      debugPrint('📍 One‑time position = $p');
    } catch (e) {
      debugPrint('❌ One‑time getCurrentPosition error: $e');
    }
  }
LocationSettings _buildSettings({required bool isBackground}) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: isBackground ? 100 : 100,
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
  return defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS
      ? AppleSettings(accuracy: LocationAccuracy.high, distanceFilter: 0, pauseLocationUpdatesAutomatically: false)
      : const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
}


  void _subscribe({required LocationSettings locationSettings}) {
  _positionSubscription?.cancel();
  _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen(
    (pos) async {
      debugPrint('📡 Stream position = $pos');
      final ccid = AppUser.instance.ccid;
      if (ccid != null) {
        await updateUserLocation(ccid, pos.latitude, pos.longitude);
        await AppUser.instance.refreshUserData();
      }
    },
    onError: (e) => debugPrint('❌ Stream error: $e'),
  );
}

}
