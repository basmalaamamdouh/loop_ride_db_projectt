import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../globall/global.dart';
import '../search_places.dart';

class HomePage extends StatefulWidget {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapCompleterController =
  Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  late Position currentPositionOfUser;
  final TextEditingController currentLocationController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _debounce;


  Future<void> storePaymentForUser(String userId, double price) async {
    Position userPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    final databaseRef = FirebaseDatabase.instance.ref();

    Map userTripInfo = {
      'userId': FirebaseAuth.instance.currentUser?.uid ?? 'Anonymous',
      'price': price,
      'timestamp': DateTime.now().toIso8601String(), // Use local timestamp
      'location': {
        'latitude': userPosition.latitude,
        'longitude': userPosition.longitude,
      },
    };

    DatabaseReference driversRef = FirebaseDatabase.instance.ref().child("users");
    driversRef.child(currentFirebaseUser!.uid).child("trip_details").set(userTripInfo);
  }

  // Replace with your API key (store it securely)
  final String googleApiKey = 'AIzaSyBMxqcgsUUcn-VPboBJp0gMHAB3qYcceuk';

  List<String> suggestions = [];
  List<dynamic> predictions = [];
  bool isLoading = false;

  // Function to update the map style
  void updateMapTheme(GoogleMapController controller) {
    getJsonFileFromThemes("themes/night_style.json").then((value) {
      setGoogleMapStyle(value, controller);
    });
  }

  // Function to load the JSON file for map theme
  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    var byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asInt8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  // Function to set the map style
  void setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }

  // Function to get the user's current location
  Future<void> getCurrentLiveLocation() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    LatLng positionLatLng =
    LatLng(currentPositionOfUser.latitude, currentPositionOfUser.longitude);
    CameraPosition cameraPosition =
    CameraPosition(target: positionLatLng, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    currentLocationController.text =
    "Lat: ${currentPositionOfUser.latitude}, Long: ${currentPositionOfUser.longitude}";

    setState(() {
      _markers.add(Marker(
        markerId: MarkerId('current_location'),
        position: positionLatLng,
        infoWindow: InfoWindow(title: 'Current Location'),
      ));
    });
  }

  // Function to fetch place suggestions
  Future<void> fetchPlaceSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => suggestions.clear());
      return;
    }

    setState(() => isLoading = true);

    String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var predictionsData = data['predictions'];
        setState(() {
          predictions = predictionsData;
          suggestions = predictionsData
              .map((prediction) => prediction['description'] as String)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Function to fetch place details and calculate route
  Future<void> fetchPlaceDetails(String placeId) async {
    String url =
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var result = data['result'];
        double lat = result['geometry']['location']['lat'];
        double lng = result['geometry']['location']['lng'];
        LatLng destination = LatLng(lat, lng);

        // Calculate and display the route
        calculateRoute(destination);
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
  }

  // Function to calculate and draw the route on the map
  void calculateRoute(LatLng destination) async {
    if (controllerGoogleMap == null) return;

    // Fetch user's current location
    Position userPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    LatLng origin = LatLng(userPosition.latitude, userPosition.longitude);

    // Fetch route details from Google Directions API
    String directionsUrl =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(directionsUrl));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          var points = data['routes'][0]['overview_polyline']['points'];
          List<LatLng> routePoints = decodePolyline(points);

          // Add the polyline to the map
          setState(() {
            _polylines.clear(); // Clear existing polylines
            _polylines.add(Polyline(
              polylineId: PolylineId('route'),
              visible: true,
              points: routePoints,
              width: 5,
              color: Colors.blue,
            ));
          });

          // Move camera to show the route
          LatLngBounds bounds = _calculateLatLngBounds(origin, destination);
          controllerGoogleMap!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
        }
      } else {
        print('Error fetching directions: ${response.body}');
      }
    } catch (e) {
      print('Error fetching directions: $e');
    }
  }

  // Function to show the payment dialog


  // Function to calculate price based on distance
  double calculatePrice(double distanceInMeters) {
    const double ratePerKm = 1.5; // Rate per kilometer
    double distanceInKm = distanceInMeters / 1000; // Convert meters to kilometers
    return distanceInKm * ratePerKm;
  }

  // Function to decode the polyline
  List<LatLng> decodePolyline(String encoded) {
    var list = <LatLng>[];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        index++;
      } while (byte >= 0x20);
      int dLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        index++;
      } while (byte >= 0x20);
      int dLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dLng;

      list.add(LatLng((lat / 1E5), (lng / 1E5)));
    }
    return list;
  }

  // Helper function to calculate LatLngBounds for the route
  LatLngBounds _calculateLatLngBounds(LatLng origin, LatLng destination) {
    double minLat = min(origin.latitude, destination.latitude);
    double maxLat = max(origin.latitude, destination.latitude);
    double minLng = min(origin.longitude, destination.longitude);
    double maxLng = max(origin.longitude, destination.longitude);

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
  void showPaymentDialog(double price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Estimated Price: \$${price.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Store payment in Realtime Database for this specific user
              String userId = "5VoTEBRMmsdaEOkiC9dL5NGSFL93"; // Replace with the actual user ID
              await storePaymentForUser(userId, price);

              // Close dialog
              Navigator.pop(context);
            },
            child: Text('Pay'),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            initialCameraPosition: CameraPosition(target: LatLng(0, 0), zoom: 2),
            onMapCreated: (GoogleMapController mapController) {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!);
              googleMapCompleterController.complete(controllerGoogleMap);
              getCurrentLiveLocation();
            },
            markers: _markers,
            polylines: _polylines,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "From" Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.my_location, color: Colors.blue),
                        Expanded(
                          child: TextField(
                            controller: currentLocationController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'Enter starting point',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  // "To" Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red),
                        Expanded(
                          child: TextField(
                            controller: destinationController,
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchPlaces(
                                    onPlaceSelected: (String place) {
                                      setState(() {
                                        destinationController.text = place;
                                      });
                                      fetchPlaceDetails(place); // Fetch details of the place selected
                                    },
                                  ),
                                ),
                              );
                            },
                            onChanged: (value) {
                              if (_debounce?.isActive ?? false) _debounce!.cancel();
                              _debounce = Timer(Duration(milliseconds: 300), () {
                                fetchPlaceSuggestions(value);
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'To',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // "Request Ride" Button
                  ElevatedButton(
                    onPressed: () async {
                      // Check if the destination is empty
                      if (destinationController.text.isEmpty) {
                        // Show an alert dialog prompting the user to choose a destination
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Error'),
                            content: Text('Please choose a destination before requesting a ride.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the dialog
                                },
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Fetch user's current location
                        Position userPosition = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.bestForNavigation,
                        );

                        // Fetch destination coordinates
                        String destinationPlaceId = destinationController.text; // Assume this is the destination's place ID

                        // Fetch destination details from Google Places API
                        String placeDetailsUrl =
                            'https://maps.googleapis.com/maps/api/place/details/json?placeid=$destinationPlaceId&key=$googleApiKey';
                        final response = await http.get(Uri.parse(placeDetailsUrl));
                        if (response.statusCode == 200) {
                          var data = json.decode(response.body);
                          var result = data['result'];
                          double destinationLat = result['geometry']['location']['lat'];
                          double destinationLng = result['geometry']['location']['lng'];

                          // Calculate the distance between current position and destination
                          double distanceInMeters = Geolocator.distanceBetween(
                            userPosition.latitude,
                            userPosition.longitude,
                            destinationLat,
                            destinationLng,
                          );

                          // Calculate price based on distance
                          double price = calculatePrice(distanceInMeters);

                          // Show payment dialog with the calculated price
                          showPaymentDialog(price);
                        } else {
                          print('Error fetching place details: ${response.body}');
                        }
                      }
                    },
                    child: Text('Request Ride'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

