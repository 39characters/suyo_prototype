import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'customer_pending_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  LatLng? _centerLocation;
  LatLng? _userLocation;
  Map<String, dynamic>? _selectedProvider;
  List<Map<String, dynamic>> allProviders = [];
  List<Map<String, dynamic>> filteredProviders = [];
  bool _isBuffering = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    await Geolocator.requestPermission();
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _userLocation = LatLng(pos.latitude, pos.longitude);
    _centerLocation = _userLocation;
    await _loadMapStyle();
    await _fetchProviders();
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_style.json');
    _mapController?.setMapStyle(style);
  }

  double _degToRad(double deg) => deg * (pi / 180);

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> _fetchProviders() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'Service Provider')
        .where('serviceCategory', isEqualTo: widget.serviceCategory)
        .get();

    final results = snapshot.docs.map((doc) {
      final data = doc.data();
      final location = data['location'];

      if (location == null || location['lat'] == null || location['lng'] == null) return null;

      final lat = location['lat'].toDouble();
      final lng = location['lng'].toDouble();

      return {
        "id": doc.id,
        "name": data['businessName'] ?? "${data['firstName']} ${data['lastName']}",
        "lat": lat,
        "lng": lng,
        "rating": data['rating'] != null ? (data['rating'] as num).toDouble() : 4.5,
      };
    }).whereType<Map<String, dynamic>>().toList();

    allProviders = results;
    _filterProvidersByCenter();
  }

  void _filterProvidersByCenter() {
    if (_centerLocation == null) return;

    setState(() {
      _isBuffering = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      final results = allProviders.map((p) {
        final distance = _calculateDistance(
          _centerLocation!.latitude,
          _centerLocation!.longitude,
          p['lat'],
          p['lng'],
        );
        return {
          ...p,
          "distance": distance.toStringAsFixed(2),
          "eta": "~${(distance * 2).toStringAsFixed(0)} min",
        };
      }).toList();

      setState(() {
        filteredProviders = results;
        _isBuffering = false;
      });
    });
  }

  Set<Marker> _buildMarkers() {
    return filteredProviders.map((p) {
      return Marker(
        markerId: MarkerId(p['name']),
        position: LatLng(p['lat'], p['lng']),
        infoWindow: InfoWindow(
          title: p['name'],
          snippet: 'ETA: ${p['eta']} (${p['distance']} km)',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
    }).toSet();
  }

  void _onCameraMove(CameraPosition position) {
    _centerLocation = position.target;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _filterProvidersByCenter();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _userLocation!,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _loadMapStyle();
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onCameraMove: _onCameraMove,
                  markers: _buildMarkers(),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.31,
                  left: MediaQuery.of(context).size.width / 2 - 25,
                  child: const IgnorePointer(
                    child: Icon(Icons.location_on, size: 50, color: Color(0xFFF56D16)),
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
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
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
                        const Text(
                          "Nearby Providers",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _isBuffering
                              ? const Center(
                                  child: SizedBox(
                                    height: 50,
                                    child: ColoredBox(
                                      color: Color(0xFFEDEBFF),
                                      child: Center(child: Text("Loading nearby providers...")),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filteredProviders.length,
                                  separatorBuilder: (_, __) => const Divider(height: 16),
                                  itemBuilder: (context, index) {
                                    final p = filteredProviders[index];
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
                                                  "ETA: ${p['eta']} (${p['distance']} km)",
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

                                  final uid = FirebaseAuth.instance.currentUser!.uid;

                                  final bookingRef = await FirebaseFirestore.instance.collection('bookings').add({
                                    'customerId': uid,
                                    'providerId': _selectedProvider!['id'],
                                    'serviceCategory': widget.serviceCategory,
                                    'status': 'pending',
                                    'timestamp': DateTime.now(),
                                    'location': {
                                      'lat': _centerLocation?.latitude,
                                      'lng': _centerLocation?.longitude,
                                    },
                                    'price': widget.price,
                                  });

                                  Navigator.pop(context);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CustomerPendingScreen(
                                        provider: _selectedProvider!,
                                        serviceCategory: widget.serviceCategory,
                                        price: widget.price,
                                        location: {
                                          'lat': _centerLocation?.latitude,
                                          'lng': _centerLocation?.longitude,
                                        },
                                        bookingId: bookingRef.id,
                                        customerId: uid,
                                      ),
                                    ),
                                  );
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
