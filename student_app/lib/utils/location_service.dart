import 'package:location/location.dart';

class LocationService {
  final Location location = Location();



  Future<bool> requestPermission() async{
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    //check if location service is enabled 
    serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if(!serviceEnabled) {
        return false;
      }
    }

    //check permission based on users choice 
    permissionGranted = await location.hasPermission();
    if(permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted)  {
        return false;
      }
    }

    return true;
  }

  //get current location -> when user says no to live tracking 

Future<LocationData?> getCurrentLocation() async {
    try {
      return await location.getLocation();
    } catch (e) {
      print("Error getting location: $e");
      return null;
    }
  }

   // Listen to location changes (for live tracking)
  Stream<LocationData> getLocationStream() {
    return location.onLocationChanged;
  }


}