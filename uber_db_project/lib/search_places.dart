import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchPlaces extends StatefulWidget {

  final Function(String) onPlaceSelected;

  SearchPlaces({required this.onPlaceSelected});
  @override
  State<SearchPlaces> createState() => _SearchPlacesState();
}

class _SearchPlacesState extends State<SearchPlaces> {
  final TextEditingController searchController = TextEditingController();
  List<String> suggestions = [];
  List<dynamic> predictions = [];
  bool isLoading = false;

  final String googleApiKey = 'AIzaSyAYee63JgEDjW0y3RrnevDsI3jJv1ZJpwo'; // Replace with your API key
  // Replace with your API key
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Fetch user's current location
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentPosition = position;
      });
      print(
          "Current Location: Lat: ${position.latitude}, Lng: ${position.longitude}");
    } catch (e) {
      print("Error fetching current location: $e");
    }
  }

  Future<void> fetchPlaceSuggestions(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          suggestions.clear();
          predictions = [];
        });
      }
      return;
    }

    setState(() => isLoading = true);

    String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          predictions = data['predictions'];
          suggestions = predictions
              .map<String>((prediction) => prediction['description'] as String)
              .toList();
        });
      } else {
        print('Error fetching predictions: ${response.body}');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> fetchPlaceDetailsAndCalculate(String placeId) async {
    if (currentPosition == null) {
      print("Current location not available.");
      return;
    }

    String url =
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=$googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var location = data['result']['geometry']['location'];
        double destLat = location['lat'];
        double destLng = location['lng'];

        // Calculate distance
        double distance = calculateDistance(
          currentPosition!.latitude,
          currentPosition!.longitude,
          destLat,
          destLng,
        );

        // Calculate payment
        double payment = calculatePayment(distance);

        print("Distance: ${distance.toStringAsFixed(2)} km");
        print("Payment: \$${payment.toStringAsFixed(2)}");

        // Show results in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Payment Details"),
            content: Text(
              "Distance: ${distance.toStringAsFixed(2)} km\n"
                  "Payment: \$${payment.toStringAsFixed(2)}",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      } else {
        print('Error fetching place details: ${response.body}');
      }
    } catch (e) {
      print("Error fetching place details: $e");
    }
  }

  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth's radius in km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double calculatePayment(double distance) {
    const double baseFare = 5.0; // Base fare in $
    const double ratePerKm = 2.0; // Rate per km in $
    return baseFare + (distance * ratePerKm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Search & Calculate Payment',
          style: TextStyle(color: Colors.amber),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: fetchPlaceSuggestions,
              style: TextStyle(color: Colors.yellow),
              decoration: InputDecoration(
                hintText: 'Search location here...',
                hintStyle: TextStyle(color: Colors.yellow.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: Colors.yellow),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: isLoading
                  ? Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
                  : ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      suggestions[index],
                      style: TextStyle(color: Colors.yellow),
                    ),
                    tileColor: Colors.grey.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    onTap: () {
                      final placeId = predictions[index]['place_id'];
                      widget.onPlaceSelected(placeId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

