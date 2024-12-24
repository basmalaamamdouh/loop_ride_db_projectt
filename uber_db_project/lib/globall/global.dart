import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName="";
final FirebaseAuth fAuth = FirebaseAuth.instance;
User? currentFirebaseUser;
String googleMapKey="AIzaSyBMxqcgsUUcn-VPboBJp0gMHAB3qYcceuk";
const CameraPosition googlePlexInitialPosition = CameraPosition(
 target: LatLng(37.42796133580664, -122.085749655962),
 zoom: 14.4746,
);