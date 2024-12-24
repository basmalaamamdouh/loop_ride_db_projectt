import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uber_db_project/search_places.dart';
import 'Authentications/login_screen.dart';
import 'pages/home_page.dart';  // Your home page import
import 'Authentications/signup_screen.dart';  // Your signup screen import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Request location permission if denied
  PermissionStatus status = await Permission.locationWhenInUse.status;
  if (status.isDenied) {
    await Permission.locationWhenInUse.request();
  }

  // Check if permission is granted
  if (await Permission.locationWhenInUse.isGranted) {
    // You can now access the location
    await _getLocation();
  } else {
    print('Location permission is denied');
  }

  runApp(const MyApp());
}

Future<void> _getLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print("Location services are disabled.");
    return;
  }

  // Check for location permission
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      print("Location permission is denied");
      return;
    }
  }

  // Get current location
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  print('Current location: ${position.latitude}, ${position.longitude}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),  // Replace with your HomePage widget
    );
  }
}
