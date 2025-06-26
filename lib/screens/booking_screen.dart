import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingScreen extends StatefulWidget {
  final String serviceCategory;
  final double price;

  const BookingScreen({
    required this.serviceCategory,
    required this.price,
  });

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  Map<String, dynamic>? _selectedProvider;
  List<Map<String, dynamic>> nearbyProviders = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    await Geolocator.requestPermission();
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _userLocation = LatLng(pos.latitude, pos.longitude);
    });
    await _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'Service Provider')
        .where('serviceCategory', isEqualTo: widget.serviceCategory)
        .get();

    final results = snapshot.docs.map((doc) {
      final data = doc.data();
      final lat = data['lat'];
      final lng = data['lng'];

      if (lat == null || lng == null) return null;

      return {
        "name": data['businessName'] ?? "${data['firstName']} ${data['lastName']}",
        "lat": lat.toDouble(),
        "lng": lng.toDouble(),
        "eta": "10 min",
        "rating": data['rating'] != null ? (data['rating'] as num).toDouble() : 4.5,
      };
    }).whereType<Map<String, dynamic>>().toList();

    if (results.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("No Providers Found"),
          content: Text(
            "No current available services for '${widget.serviceCategory}'. Please try again later.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to home
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      setState(() => nearbyProviders = results);
    }
  }

  Set<Marker> _buildMarkers() {
    return nearbyProviders.map((p) {
      return Marker(
        markerId: MarkerId(p['name']),
        position: LatLng(p['lat'], p['lng']),
        infoWindow: InfoWindow(
          title: p['name'],
          snippet: 'ETA: ${p['eta']}',
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _userLocation!,
                      zoom: 15,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _buildMarkers(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    height: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Nearby Providers",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: nearbyProviders.length,
                            separatorBuilder: (_, __) => const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final p = nearbyProviders[index];
                              final isSelected = _selectedProvider == p;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedProvider = p;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFEDEBFF) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: isSelected ? const Color(0xFF4B2EFF) : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            "ETA: ${p['eta']}",
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, size: 16, color: Color(0xFFF56D16)),
                                          const SizedBox(width: 4),
                                          Text("${p['rating']}"),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _selectedProvider == null
                              ? null
                              : () async {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const AlertDialog(
                                      content: Row(
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(width: 16),
                                          Text("Finding available provider..."),
                                        ],
                                      ),
                                    ),
                                  );

                                  await Future.delayed(const Duration(seconds: 2));
                                  Navigator.pop(context);

                                  Navigator.pushNamed(context, "/inprogress");
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedProvider == null ? Colors.grey : const Color(0xFF4B2EFF),
                            minimumSize: const Size.fromHeight(45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Request Service",
                            style: TextStyle(color: Colors.white),
                          ),
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
