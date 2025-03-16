import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'firebase_wrapper.dart'; // Import the file with updateUserLocation
import 'package:student_app/user_singleton.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;

  StreamSubscription<Position>? _positionSubscription;

  /// Start background location tracking (Live Tracking)
  Future<void> startLiveTracking() async {
    final hasPermission = await _requestBackgroundLocationPermission();
    if (!hasPermission) {
      debugPrint("No background location permission granted.");
      return;
    }
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _uploadLocationToFirestore(position);
    });
  }

  /// Start foreground-only tracking
  Future<void> startForegroundTracking() async {
    final hasPermission = await _requestForegroundLocationPermission();
    if (!hasPermission) {
      debugPrint("No foreground location permission granted.");
      return;
    }
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _uploadLocationToFirestore(position);
    });
  }

  /// Stop tracking entirely
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Request background location permission
  Future<bool> _requestBackgroundLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return false;
      }
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  /// Request foreground location permission
  Future<bool> _requestForegroundLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return false;
      }
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  /// Upload the location to Firestore.
  void _uploadLocationToFirestore(Position position) {
    final ccid = AppUser.instance.ccid;
    if (ccid == null) return;

    // Update Firestore with the new location. The AppUser singleton
    // will automatically update its _currentLocation field based on its
    // real-time listener (_listenForUserUpdates).
    updateUserLocation(ccid, position.latitude, position.longitude);
  }
}
