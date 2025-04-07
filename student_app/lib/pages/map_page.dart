import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:student_app/user_singleton.dart';
import 'model/map_style.dart';
import 'package:student_app/utils/marker_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_app/utils/event_service.dart';
import 'maps_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:student_app/utils/study_spot_service.dart';
import 'event_popup.dart';
import 'package:student_app/utils/firebase_wrapper.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  MapPageState createState() => MapPageState();
}

class _FriendMarker {
  Marker marker;
  DateTime? lastUpdated;
  _FriendMarker(this.marker, {this.lastUpdated});
}

final Map<String, _FriendMarker> _friendMarkers = {};

class MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {
  bool _showHeatmap = false;
  Set<Circle> _heatmapCircles = {};
  GoogleMapController? _controller;
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  late CameraPosition _initialCameraPosition;
  late CameraPosition _currentCameraPosition;
  Set<String> _hiddenFromMe = {};
  final Map<MarkerId, Marker> _markers = {};

  final Map<String, BitmapDescriptor> _circleIcons = {};
  final Map<String, BitmapDescriptor> _pinIcons = {};
  final Map<String, MemoryImage> _circleMemoryImages = {};
  StreamSubscription<DocumentSnapshot>? _hiddenListSub;
  final Map<String, StreamSubscription<DocumentSnapshot>> _friendSubscriptions =
      {};
  final ValueNotifier<Map<String, DateTime?>> _lastUpdatedNotifier =
      ValueNotifier({});

  Timer? _refreshTimer;

  BitmapDescriptor? _eventMarkerIcon;
  BitmapDescriptor? _studySpotIcon;

  List<dynamic> _events = [];

  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  double _calculateDistanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);

    final originLat = _degToRad(a.latitude);
    final targetLat = _degToRad(b.latitude);

    final aVal = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(originLat) * cos(targetLat);
    final c = 2 * atan2(sqrt(aVal), sqrt(1 - aVal));
    return earthRadius * c;
  }

  Color _getDensityColor(int count) {
    if (count == 0) return Colors.transparent;
    if (count < 3) return Colors.green.withOpacity(0.3);
    if (count < 7) return Colors.orange.withOpacity(0.4);
    return Colors.red.withOpacity(0.5);
  }

  Future<void> _generateStudySpotHeatmap() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final spotsSnapshot = await firestore.collection('studySpots').get();
      final spots = spotsSnapshot.docs
          .map((doc) {
            final data = doc.data();
            final dynamic coord = data['coordinates'];

            double? lat;
            double? lng;

            if (coord is GeoPoint) {
              lat = coord.latitude;
              lng = coord.longitude;
            } else if (coord is Map<String, dynamic>) {
              lat = coord['lat'];
              lng = coord['lng'];
            } else {
              debugPrint("Invalid coordinates format for: ${data['name']}");
            }

            if (lat != null && lng != null) {
              return {
                'name': data['name'],
                'location': LatLng(lat, lng),
              };
            }
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      final usersSnapshot = await firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      final userLocations = usersSnapshot.docs
          .map((doc) {
            final loc = doc['currentLocation'];
            if (loc == null || loc['lat'] == null || loc['lng'] == null) {
              debugPrint("Skipping user with missing location: ${doc.id}");
              return null;
            }
            return LatLng(loc['lat'], loc['lng']);
          })
          .whereType<LatLng>()
          .toList();

      Set<Circle> spotCircles = {};

      for (int i = 0; i < spots.length; i++) {
        final spot = spots[i];
        final LatLng spotLocation = spot['location'];

        int count = userLocations
            .where((userLoc) =>
                _calculateDistanceMeters(spotLocation, userLoc) <= 50)
            .length;

        final circle = Circle(
          circleId: CircleId("spot_${spot['name']}"),
          center: spotLocation,
          radius: 50,
          strokeWidth: 0,
          fillColor: _getDensityColor(count),
        );

        spotCircles.add(circle);
      }

      setState(() {
        _heatmapCircles = spotCircles;
      });
    } catch (e) {
      debugPrint("Error in _generateStudySpotHeatmap: $e");
    }
  }

  double _degToRad(double deg) => deg * (pi / 180);

  void _toggleHeatmap() {
    setState(() {
      _showHeatmap = !_showHeatmap;
    });

    if (_showHeatmap) {
      _generateStudySpotHeatmap();
    } else {
      setState(() {
        _heatmapCircles.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (AppUser.instance.currentLocation != null) {
      final lat = AppUser.instance.currentLocation!['lat'];
      final lng = AppUser.instance.currentLocation!['lng'];
      if (lat != null && lng != null) {
        _initialCameraPosition =
            CameraPosition(target: LatLng(lat, lng), zoom: 15.0);
      } else {
        _initialCameraPosition = _fallbackPosition();
      }
    } else {
      _initialCameraPosition = _fallbackPosition();
    }
    _currentCameraPosition = _initialCameraPosition;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadFriendIcons();
      await _loadEventIcon();
      await _loadStudySpotIcon();

      await _addFriendMarkers();
      await _addEventMarkers();
      await _addStudySpotMarkers();

      _updateFriendSubscriptions();

      _refreshTimer = Timer.periodic(Duration(seconds: 15), (_) {
        if (_showHeatmap) _generateStudySpotHeatmap();
      });
    });
    final ccid = AppUser.instance.ccid;
    if (ccid != null) {
      _hiddenListSub = FirebaseFirestore.instance
          .collection('users')
          .doc(ccid)
          .snapshots()
          .listen((docSnapshot) {
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null && data.containsKey('hidden_from_me')) {
            final List<dynamic> hiddenList = data['hidden_from_me'] ?? [];
            setState(() {
              _hiddenFromMe = hiddenList.cast<String>().toSet();
            });
            _addFriendMarkers(); 
            _updateFriendSubscriptions(); 
          }
        }
      });
    }
  }

  CameraPosition _fallbackPosition() {
    return const CameraPosition(
      target: LatLng(53.522518, -113.530457),
      zoom: 15.0,
    );
  }

  @override
  void dispose() {
    _hiddenListSub?.cancel();
    _refreshTimer?.cancel();
    for (var sub in _friendSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> refreshMarkers() async {
    await _loadFriendIcons();
    await _addFriendMarkers();
    await _addEventMarkers();
    await _addStudySpotMarkers();
  }

  Future<void> _loadFriendIcons() async {
    final friends = AppUser.instance.friends;
    for (var friend in friends) {
      final photoUrl = friend.photoURL;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        try {
          final circleBytes = await createCircleImageBytes(photoUrl, 80);
          final circleMemoryImage = MemoryImage(circleBytes);
          final circleIcon = BitmapDescriptor.fromBytes(circleBytes);

          final pinIcon = await getPinMarkerIcon(
            photoUrl,
            pinWidth: 100,
            pinAssetPath: 'assets/marker_asset.png',
          );

          _circleMemoryImages[friend.ccid] = circleMemoryImage;
          _circleIcons[friend.ccid] = circleIcon;
          _pinIcons[friend.ccid] = pinIcon;
        } catch (e) {
          debugPrint("Error loading icons for ${friend.ccid}: $e");
          _circleIcons[friend.ccid] = BitmapDescriptor.defaultMarker;
          _pinIcons[friend.ccid] = BitmapDescriptor.defaultMarker;
        }
      } else {
        _circleIcons[friend.ccid] = BitmapDescriptor.defaultMarker;
        _pinIcons[friend.ccid] = BitmapDescriptor.defaultMarker;
      }
    }
  }

  Future<void> _loadEventIcon() async {
    if (_eventMarkerIcon != null) return;

    try {
      _eventMarkerIcon =
          await getResizedMarkerIcon('assets/event_marker.png', 80, 80);
      debugPrint("Successfully loaded event_marker.png as custom marker");
    } catch (e) {
      debugPrint("Error loading event marker icon: $e");
      _eventMarkerIcon = BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _loadStudySpotIcon() async {
    if (_studySpotIcon != null) return;

    try {
      _studySpotIcon =
          await getResizedMarkerIcon('assets/study_spot.png', 80, 80);
      debugPrint("Successfully loaded study_spot_marker.png as custom marker");
    } catch (e) {
      debugPrint("Error loading study spot marker icon: $e");
      _studySpotIcon = BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _addFriendMarkers() async {
    final friends = AppUser.instance.friends;
    for (var friend in friends) {
      if (_hiddenFromMe.contains(friend.ccid)) continue;
      final lat = friend.currentLocation?['lat'];
      final lng = friend.currentLocation?['lng'];
      if (lat == null || lng == null) continue;

      final markerId = MarkerId(friend.ccid);
      final circleIcon =
          _circleIcons[friend.ccid] ?? BitmapDescriptor.defaultMarker;

      final marker = Marker(
        markerId: markerId,
        position: LatLng(lat, lng),
        icon: circleIcon,
        onTap: () {
          _switchToPinIcon(markerId, friend);
          _controller
              ?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16));
        },
      );

      _markers[markerId] = marker;
    }
    setState(() {});
  }

  void _switchToPinIcon(MarkerId markerId, dynamic friend) {
    final oldMarker = _markers[markerId];
    if (oldMarker == null) return;
    final newIcon = _pinIcons[friend.ccid] ?? BitmapDescriptor.defaultMarker;
    final updatedMarker = oldMarker.copyWith(iconParam: newIcon);
    setState(() {
      _markers[markerId] = updatedMarker;
    });
  }

  void _resetAllMarkersToCircle() {
    final friends = AppUser.instance.friends;
    for (var friend in friends) {
      final markerId = MarkerId(friend.ccid);
      final oldMarker = _markers[markerId];
      if (oldMarker == null) continue;
      final circleIcon =
          _circleIcons[friend.ccid] ?? BitmapDescriptor.defaultMarker;
      final updatedMarker = oldMarker.copyWith(iconParam: circleIcon);
      _markers[markerId] = updatedMarker;
    }
    setState(() {});
  }

  Future<void> _addEventMarkers() async {
    if (_eventMarkerIcon == null) return;

    final eventService = EventService(firestore: FirebaseFirestore.instance);
    final allEvents = await eventService.getAllEvents();

    _events = allEvents;

    for (var event in allEvents) {
      final coords = event['coordinates'] as Map<String, dynamic>?;
      if (coords == null) continue;

      final lat = coords['lat'] as double?;
      final lng = coords['lng'] as double?;
      if (lat == null || lng == null) continue;

      final markerId = MarkerId("event_${event['id']}");
      final marker = Marker(
        markerId: markerId,
        position: LatLng(lat, lng),
        icon: _eventMarkerIcon!,
        onTap: () {
  final eventLatLng = LatLng(lat, lng);
  _controller?.animateCamera(CameraUpdate.newLatLngZoom(eventLatLng, 16));
  _customInfoWindowController.addInfoWindow!(
  EventPopup(
    event: event,
    onMoreInfo: () {
      // Redirect to your detailed event page, for example:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventPopup(event: event),
        ),
      );
    },
  ),
  eventLatLng,
);
},
      );
      _markers[markerId] = marker;
    }
    setState(() {});
  }

  Future<void> _addStudySpotMarkers() async {
    if (_studySpotIcon == null) return;

    final studySpotService =
        StudySpotService(firestore: FirebaseFirestore.instance);
    final allStudySpots = await studySpotService.getAllStudySpots();

    for (var spot in allStudySpots) {
      final dynamic coord = spot['coordinates'];
      double? lat;
      double? lng;
      if (coord is GeoPoint) {
        lat = coord.latitude;
        lng = coord.longitude;
      } else if (coord is Map<String, dynamic>) {
        lat = coord['lat'];
        lng = coord['lng'];
      }
      final markerId = MarkerId("studySpot_${spot['id']}");
      final marker = Marker(
        markerId: markerId,
        position: LatLng(lat!, lng!),
        icon: _studySpotIcon!,
        onTap: () {
          _controller?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(lat!, lng!), 16));
        },
      );
      _markers[markerId] = marker;
    }
    setState(() {});
  }

  void _updateFriendSubscriptions() {
    final friendIds = AppUser.instance.friends.map((f) => f.ccid).toSet();

    _friendSubscriptions.keys
        .where((id) => !friendIds.contains(id) || _hiddenFromMe.contains(id))
        .toList()
        .forEach((id) {
      _friendSubscriptions.remove(id)?.cancel();
      _friendMarkers.remove(id);
      _markers.remove(MarkerId(id));
      setState(() {});
    });

    for (final friend in AppUser.instance.friends) {
      if (_hiddenFromMe.contains(friend.ccid)) continue;
      if (_friendSubscriptions.containsKey(friend.ccid)) continue;

      final sub = FirebaseFirestore.instance
          .collection('users')
          .doc(friend.ccid)
          .snapshots()
          .listen((doc) {
        if (!doc.exists) return;
        final data = doc.data()!;
        final loc = data['currentLocation'] as Map<String, dynamic>?;

        final timestamp =
            loc != null ? (loc['timestamp'] as Timestamp?)?.toDate() : null;

        _lastUpdatedNotifier.value = {
          ..._lastUpdatedNotifier.value,
          friend.ccid: timestamp,
        };

        if (loc == null || loc['lat'] == null || loc['lng'] == null) return;
        final newPos = LatLng(loc['lat'], loc['lng']);
        final markerId = MarkerId(friend.ccid);
        final existing = _friendMarkers[friend.ccid];

        if (existing != null) {
          if (existing.marker.position != newPos) {
            final updatedMarker =
                existing.marker.copyWith(positionParam: newPos);
            _friendMarkers[friend.ccid] =
                _FriendMarker(updatedMarker, lastUpdated: timestamp);
            _markers[markerId] = updatedMarker;
            setState(() {});
          }
        } else {
          final icon =
              _circleIcons[friend.ccid] ?? BitmapDescriptor.defaultMarker;
          final newMarker = Marker(
            markerId: markerId,
            position: newPos,
            icon: icon,
            onTap: () {
              _controller
                  ?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
              _resetAllMarkersToCircle();
            },
          );

          _friendMarkers[friend.ccid] =
              _FriendMarker(newMarker, lastUpdated: timestamp);
          _markers[markerId] = newMarker;
          setState(() {});
        }
      });

      _friendSubscriptions[friend.ccid] = sub;
    }
  }

  @override
  bool get wantKeepAlive => true;

  Widget gradientIcon() {
    return Container(
      padding: const EdgeInsets.all(3.0),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF396548),
            Color(0xFF6B803D),
            Color(0xFF909533),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Image.asset(
          'assets/Google_Maps_icon_(2015-2020).png',
          width: 30,
          height: 30,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: AppBar(
          backgroundColor: Colors.white.withOpacity(0.2),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _openThemeSelector,
              icon: const Icon(Icons.layers),
            ),
          ],
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.white.withOpacity(0)),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            markers: Set<Marker>.of(_markers.values),
            myLocationButtonEnabled: true,
            circles: _heatmapCircles,
            onTap: (LatLng latLng) {
              _customInfoWindowController.hideInfoWindow!();
              _resetAllMarkersToCircle();
            },
            onCameraMove: (CameraPosition position) {
              _customInfoWindowController.onCameraMove!();
              _currentCameraPosition = position;
            },
            onMapCreated: (controller) {
              _controller = controller;
              _customInfoWindowController.googleMapController = controller;
              controller.setMapStyle(MapStyle().retro);
            },
          ),
          Positioned(
            top: 80,
            right: 5,
            child: FloatingActionButton(
              mini: true,
              heroTag: "open_gmaps",
              onPressed: () async {
                final lat = _currentCameraPosition.target.latitude;
                final lng = _currentCameraPosition.target.longitude;
                final url =
                    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  debugPrint("Could not launch Google Maps");
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: gradientIcon(),
            ),
          ),
          Positioned(
            top: 140,
            right: 5,
            child: FloatingActionButton(
              mini: true,
              heroTag: "toggle_heatmap",
              onPressed: _toggleHeatmap,
              backgroundColor: Colors.white,
              child: Icon(
                _showHeatmap ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF396548),
              ),
            ),
          ),
          CustomInfoWindow(
            controller: _customInfoWindowController,
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.8,
            offset: 50.0,
          ),
          MapsBottomSheet(
            draggableController: _draggableController,
            friends: AppUser.instance.friends,
            lastUpdatedNotifier: _lastUpdatedNotifier,
            onFriendTap: (friend) {
              _customInfoWindowController.hideInfoWindow!();
              _resetAllMarkersToCircle();
              final lat = friend.currentLocation?['lat'];
              final lng = friend.currentLocation?['lng'];
              if (lat != null && lng != null) {
                _controller?.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
                );
              }
            },
            hiddenFromMe: _hiddenFromMe,
          ),
        ],
      ),
    );
  }

  void _openThemeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.3,
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Map Theme",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mapThemes.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _controller?.setMapStyle(_mapThemes[index]['style']);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(_mapThemes[index]['image']),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          color: Colors.black.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text(
                            _mapThemes[index]['name'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  final List<dynamic> _mapThemes = [
    {
      'name': 'Standard',
      'style': MapStyle().dark,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=roadmap&style=element:labels%7Cvisibility:off&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.neighborhood%7Cvisibility:off&size=164x132&key=AIzaSyDk4C4EBWgjuL1eBnJlu1J80WytEtSIags&scale=2'
    },
    {
      'name': 'Sliver',
      'style': MapStyle().sliver,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=roadmap&style=element:geometry%7Ccolor:0xf5f5f5&style=element:labels%7Cvisibility:off&style=element:labels.icon%7Cvisibility:off&style=element:labels.text.fill%7Ccolor:0x616161&style=element:labels.text.stroke%7Ccolor:0xf5f5f5&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.land_parcel%7Celement:labels.text.fill%7Ccolor:0xbdbdbd&style=feature:administrative.neighborhood%7Cvisibility:off&style=feature:poi%7Celement:geometry%7Ccolor:0xeeeeee&style=feature:poi%7Celement:labels.text.fill%7Ccolor:0x757575&style=feature:poi.park%7Celement:geometry%7Ccolor:0xe5e5e5&style=feature:poi.park%7Celement:labels.text.fill%7Ccolor:0x9e9e9e&style=feature:road%7Celement:geometry%7Ccolor:0xffffff&style=feature:road.arterial%7Celement:labels.text.fill%7Ccolor:0x757575&style=feature:road.highway%7Celement:geometry%7Ccolor:0xdadada&style=feature:road.highway%7Celement:labels.text.fill%7Ccolor:0x616161&style=feature:road.local%7Celement:labels.text.fill%7Ccolor:0x9e9e9e&style=feature:transit.line%7Celement:geometry%7Ccolor:0xe5e5e5&style=feature:transit.station%7Celement:geometry%7Ccolor:0xeeeeee&style=feature:water%7Celement:geometry%7Ccolor:0xc9c9c9&style=feature:water%7Celement:labels.text.fill%7Ccolor:0x9e9e9e&size=164x132&key=AIzaSyDk4C4EBWgjuL1eBnJlu1J80WytEtSIags&scale=2'
    },
    {
      'name': 'Retro',
      'style': MapStyle().retro,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=roadmap&style=element:geometry%7Ccolor:0xebe3cd&style=element:labels%7Cvisibility:off&style=element:labels.text.fill%7Ccolor:0x523735&style=element:labels.text.stroke%7Ccolor:0xf5f1e6&style=feature:administrative%7Celement:geometry.stroke%7Ccolor:0xc9b2a6&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.land_parcel%7Celement:geometry.stroke%7Ccolor:0xdcd2be&style=feature:administrative.land_parcel%7Celement:labels.text.fill%7Ccolor:0xae9e90&style=feature:administrative.neighborhood%7Cvisibility:off&style=feature:landscape.natural%7Celement:geometry%7Ccolor:0xdfd2ae&style=feature:poi%7Celement:geometry%7Ccolor:0xdfd2ae&style=feature:poi%7Celement:labels.text.fill%7Ccolor:0x93817c&style=feature:poi.park%7Celement:geometry.fill%7Ccolor:0xa5b076&style=feature:poi.park%7Celement:labels.text.fill%7Ccolor:0x447530&style=feature:road%7Celement:geometry%7Ccolor:0xf5f1e6&style=feature:road.arterial%7Celement:geometry%7Ccolor:0xfdfcf8&style=feature:road.highway%7Celement:geometry%7Ccolor:0xf8c967&style=feature:road.highway%7Celement:geometry.stroke%7Ccolor:0xe9bc62&style=feature:road.highway.controlled_access%7Celement:geometry%7Ccolor:0xe98d58&style=feature:road.highway.controlled_access%7Celement:geometry.stroke%7Ccolor:0xdb8555&style=feature:road.local%7Celement:labels.text.fill%7Ccolor:0x806b63&style=feature:transit.line%7Celement:geometry%7Ccolor:0xdfd2ae&style=feature:transit.line%7Celement:labels.text.fill%7Ccolor:0x8f7d77&style=feature:transit.line%7Celement:labels.text.stroke%7Ccolor:0xebe3cd&style=feature:transit.station%7Celement:geometry%7Ccolor:0xdfd2ae&style=feature:water%7Celement:geometry.fill%7Ccolor:0xb9d3c2&style=feature:water%7Celement:labels.text.fill%7Ccolor:0x92998d&size=164x132&key=AIzaSyDk4C4EBWgjuL1eBnJlu1J80WytEtSIags&scale=2'
    },
    {
      'name': 'Dark',
      'style': MapStyle().dark,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=roadmap&style=element:geometry%7Ccolor:0x212121&style=element:labels%7Cvisibility:off&style=element:labels.icon%7Cvisibility:off&style=element:labels.text.fill%7Ccolor:0x757575&style=element:labels.text.stroke%7Ccolor:0x212121&style=feature:administrative%7Celement:geometry%7Ccolor:0x757575&style=feature:administrative.country%7Celement:labels.text.fill%7Ccolor:0x9e9e9e&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.locality%7Celement:labels.text.fill%7Ccolor:0xbdbdbd&style=feature:administrative.neighborhood%7Cvisibility:off&style=feature:poi%7Celement:labels.text.fill%7Ccolor:0x757575&style=feature:poi.park%7Celement:geometry%7Ccolor:0x181818&style=feature:poi.park%7Celement:labels.text.fill%7Ccolor:0x616161&style=feature:poi.park%7Celement:labels.text.stroke%7Ccolor:0x1b1b1b&style=feature:road%7Celement:geometry.fill%7Ccolor:0x2c2c2c&style=feature:road%7Celement:labels.text.fill%7Ccolor:0x8a8a8a&style=feature:road.arterial%7Celement:geometry%7Ccolor:0x373737&style=feature:road.highway%7Celement:geometry%7Ccolor:0x3c3c3c&style=feature:road.highway.controlled_access%7Celement:geometry%7Ccolor:0x4e4e4e&style=feature:road.local%7Celement:labels.text.fill%7Ccolor:0x616161&style=feature:transit%7Celement:labels.text.fill%7Ccolor:0x757575&style=feature:water%7Celement:geometry%7Ccolor:0x000000&style=feature:water%7Celement:labels.text.fill%7Ccolor:0x3d3d3d&size=164x132&key=AIzaSyDk4C4EBWgjuL1eBnJlu1J80WytEtSIags&scale=2'
    },
    {
      'name': 'Night',
      'style': MapStyle().night,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=roadmap&style=element:geometry%7Ccolor:0x242f3e&style=element:labels%7Cvisibility:off&style=element:labels.text.fill%7Ccolor:0x746855&style=element:labels.text.stroke%7Ccolor:0x242f3e&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.locality%7Celement:labels.text.fill%7Ccolor:0xd59563&style=feature:administrative.neighborhood%7Cvisibility:off&style=feature:poi%7Celement:labels.text.fill%7Ccolor:0xd59563&style=feature:poi.park%7Celement:geometry%7Ccolor:0x263c3f&style=feature:poi.park%7Celement:labels.text.fill%7Ccolor:0x6b9a76&style=feature:road%7Celement:geometry%7Ccolor:0x38414e&style=feature:road%7Celement:geometry.stroke%7Ccolor:0x212a37&style=feature:road%7Celement:labels.text.fill%7Ccolor:0x9ca5b3&style=feature:road.highway%7Celement:geometry%7Ccolor:0x746855&style=feature:road.highway%7Celement:geometry.stroke%7Ccolor:0x1f2835&style=feature:road.highway%7Celement:labels.text.fill%7Ccolor:0xf3d19c&style=feature:transit%7Celement:labels.text.fill%7Ccolor:0x757575&style=feature:water%7Celement:geometry%7Ccolor:0x17263c&style=feature:water%7Celement:labels.text.fill%7Ccolor:0x515c6d&style=feature:water%7Celement:labels.text.stroke%7Ccolor:0x17263c&size=164x132&key=AIzaSyDk4C4EBWgjuL1eBnJlu1J80WytEtSIags&scale=2'
    },
    {
      'name': 'Aubergine',
      'style': MapStyle().aubergine,
      'image':
          'https://maps.googleapis.com/maps/api/staticmap?center=-33.9775,151.036&zoom=13&format=png&maptype=roadmap&style=element:geometry%7Ccolor:0x1d2c4d&style=element:labels%7Cvisibility:off&style=element:labels.text.fill%7Ccolor:0x8ec3b9&style=element:labels.text.stroke%7Ccolor:0x1a3646&style=feature:administrative.country%7Celement:geometry.stroke%7Ccolor:0x4b6878&style=feature:administrative.land_parcel%7Cvisibility:off&style=feature:administrative.land_parcel%7Celement:labels.text.fill%7Ccolor:0x64779e&style=feature:administrative.neighborhood%7Cvisibility:off&style=feature:administrative.province%7Celement:geometry.stroke%7Ccolor:0x4b6878&style=feature:landscape.man_made%7Celement:geometry.stroke%7Ccolor:0x334e87&style=feature:landscape.natural%7Celement:geometry%7Ccolor:0x023e58&style=feature:poi%7Celement:geometry%7Ccolor:0x283d6a&style=feature:poi%7Celement:labels.text.fill%7Ccolor:0x6f9ba5&style=feature:poi%7Celement:labels.text.stroke%7Ccolor:0x1d2c4d&style=feature:poi.park%7Celement:geometry%7Ccolor:0x023e58&style=feature:poi.park%7Celement:labels.text.fill%7Ccolor:0x3C7680&style=feature:road%7Celement:geometry%7Ccolor:0x304a7d&style=feature:road%7Celement:labels.text.fill%7Ccolor:0x98a5be&style=feature:road%7Celement:labels.text.stroke%7Ccolor:0x1d2c4d&style=feature:road.highway%7Celement:geometry%7Ccolor:0x2c6675&style=feature:road.highway%7Celement:geometry.stroke%7Ccolor:0x255763&style=feature:road.highway%7Celement:labels.text.fill%7Ccolor:0xb0d5ce&style=feature:road.highway%7Celement:labels.text.stroke%7Ccolor:0x023e58&style=feature:transit%7Celement:labels.text.fill%7Ccolor:0x98a5be&style=feature:transit%7Celement:labels.text.stroke%7Ccolor:0x1d2c4d&style=feature:transit.line%7Celement:geometry.fill%7Ccolor:0x283d6a&style=feature:transit.station%7Celement:geometry%7Ccolor:0x3a4762&style=feature:water%7Celement:geometry%7Ccolor:0x0e1626&style=feature:water%7Celement:labels.text.fill%7Ccolor:0x4e6d70&size=164x132&key=AIzaSyDk4C4EBWgjuL1eBnJlu1J80WytEtSIags&scale=2'
    }
  ];
}
