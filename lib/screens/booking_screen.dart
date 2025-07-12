import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_pending_screen.dart';

class BookingScreen extends StatefulWidget {
  final String serviceCategory;
  final double price;

  const BookingScreen({
    required this.serviceCategory,
    required this.price,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _centerLocation;
  LatLng? _userLocation;
  Map<String, dynamic>? _selectedProvider;
  List<Map<String, dynamic>> allProviders = [];
  List<Map<String, dynamic>> filteredProviders = [];
  String _sortType = 'Nearest';
  bool _isBuffering = false;
  Timer? _debounce;
  bool _mapLocked = false;

  late DraggableScrollableController _sheetController;
  double _sheetSize = 0.35;

  final _formKey = GlobalKey<FormState>();
  String customerName = '';
  String phone = '';
  String address = '';

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    await Geolocator.requestPermission();
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _userLocation = LatLng(pos.latitude, pos.longitude);
    _centerLocation = _userLocation;
    await _loadMapStyle();
    await _fetchProviders();
    await _askUserDetails();
  }

  Future<void> _askUserDetails() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        elevation: 20,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter Your Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4B2EFF))),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  onSaved: (v) => customerName = v!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  onSaved: (v) => phone = v!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Complete Address'),
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                  onSaved: (v) => address = v!.trim(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          Navigator.pop(context, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B2EFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Submit', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );

    if (result != true) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Go back?"),
          content: const Text("You need to provide your details to continue."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Stay")),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text("Go Home"),
            ),
          ],
        ),
      );

      if (confirm != true) {
        await Future.delayed(const Duration(milliseconds: 300));
        _askUserDetails();
      }
    }
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_style.json');
    if (_mapController != null) {
      _mapController!.setMapStyle(style);
    }
  }

  double _degToRad(double deg) => deg * (pi / 180);

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
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
      final rating = data['rating'] != null ? ((data['rating'] as num).toDouble()).toStringAsFixed(1) : "0.0";

      return {
        "id": doc.id,
        "name": data['businessName'] ?? "${data['firstName']} ${data['lastName']}",
        "lat": lat,
        "lng": lng,
        "rating": double.tryParse(rating) ?? 0.0,
      };
    }).whereType<Map<String, dynamic>>().toList();

    allProviders = results;
    _filterProvidersByCenter();
  }

  void _filterProvidersByCenter() {
    if (_centerLocation == null) return;

    setState(() => _isBuffering = true);

    Future.delayed(const Duration(milliseconds: 300), () {
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
          "numericDistance": distance,
        };
      }).toList();

      if (_sortType == 'Rating') {
        results.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
      } else if (_sortType == 'Smart') {
        results.sort((a, b) {
          final aScore = (a['numericDistance'] as double) * 0.6 - (a['rating'] as double) * 0.4;
          final bScore = (b['numericDistance'] as double) * 0.6 - (b['rating'] as double) * 0.4;
          return aScore.compareTo(bScore);
        });
      } else {
        results.sort((a, b) => (a['numericDistance'] as double).compareTo(b['numericDistance'] as double));
      }

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
    if (_mapLocked) return;
    _centerLocation = position.target;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _filterProvidersByCenter);
  }

  void _handleBooking() async {
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
      'providerName': _selectedProvider!['name'],
      'serviceCategory': widget.serviceCategory,
      'status': 'pending',
      'timestamp': DateTime.now(),
      'location': {
        'lat': _centerLocation?.latitude,
        'lng': _centerLocation?.longitude,
      },
      'price': widget.price,
      'customerName': customerName,
      'phone': phone,
      'address': address,
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
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Booking?"),
        content: const Text("Are you sure you want to go back? Your selected location will be lost."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Stay"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Go Back"),
          ),
        ],
      ),
    ) ?? false;
  }

  void _toggleSheet() {
    final newSize = _sheetSize < 0.5 ? 0.85 : 0.35;
    _sheetController.animateTo(
      newSize,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutExpo,
    );
    setState(() {
      _sheetSize = newSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _userLocation == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: _userLocation!, zoom: 15),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _loadMapStyle();
                    },
                    onCameraMove: _mapLocked ? null : _onCameraMove,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _buildMarkers(),
                    scrollGesturesEnabled: !_mapLocked,
                    zoomGesturesEnabled: !_mapLocked,
                    rotateGesturesEnabled: !_mapLocked,
                    tiltGesturesEnabled: !_mapLocked,
                    gestureRecognizers: _mapLocked
                        ? <Factory<OneSequenceGestureRecognizer>>{}.toSet()
                        : {
                            Factory(() => EagerGestureRecognizer()),
                            Factory(() => ScaleGestureRecognizer()),
                            Factory(() => PanGestureRecognizer()),
                            Factory(() => VerticalDragGestureRecognizer()),
                            Factory(() => HorizontalDragGestureRecognizer()),
                          },
                  ),

                  // AppBar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AppBar(
                      backgroundColor: const Color(0xFF4B2EFF),
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () async {
                          final goBack = await _onWillPop();
                          if (goBack) Navigator.pop(context);
                        },
                      ),
                      title: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                          children: [
                            const TextSpan(text: 'Booking for '),
                            TextSpan(
                              text: "${widget.serviceCategory}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      centerTitle: true,
                    ),
                  ),

                  // Slightly lower pointer
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.34,
                    left: MediaQuery.of(context).size.width / 2 - 25,
                    child: const IgnorePointer(
                      child: Icon(Icons.location_on, size: 50, color: Color(0xFFF56D16)),
                    ),
                  ),

                  // Lock button moved down
                  Positioned(
                    top: 100,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() => _mapLocked = !_mapLocked);
                      },
                      backgroundColor: Colors.white,
                      child: Icon(
                        _mapLocked ? Icons.lock : Icons.lock_open,
                        color: const Color(0xFF4B2EFF),
                      ),
                    ),
                  ),
                // Provider sheet (unchanged)
                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: _sheetSize,
                  minChildSize: 0.2,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Nearby Providers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: const Color(0xFF4B2EFF).withOpacity(0.1),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _sortType,
                                        dropdownColor: Colors.white,
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                                        items: ['Nearest', 'Rating', 'Smart'].map((value) {
                                          return DropdownMenuItem(value: value, child: Text(value));
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _sortType = value!;
                                            _filterProvidersByCenter();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _isBuffering
                                    ? const Center(child: CircularProgressIndicator())
                                    : ListView.separated(
                                        controller: scrollController,
                                        itemCount: filteredProviders.length,
                                        separatorBuilder: (_, __) => const Divider(height: 16),
                                        itemBuilder: (context, index) {
                                          final p = filteredProviders[index];
                                          final isSelected = _selectedProvider == p;
                                          return InkWell(
                                            onTap: () => setState(() => _selectedProvider = p),
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
                                                      Text(p['name'], style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF4B2EFF) : Colors.black)),
                                                      Text("ETA: ${p['eta']} (${p['distance']} km)", style: const TextStyle(fontSize: 12)),
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
                                onPressed: _selectedProvider == null ? null : _handleBooking,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _selectedProvider == null ? Colors.grey : const Color(0xFF4B2EFF),
                                  minimumSize: const Size.fromHeight(45),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("Request Service", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 0,
                            left: MediaQuery.of(context).size.width / 2 - 40,
                            child: GestureDetector(
                              onTap: _toggleSheet,
                              behavior: HitTestBehavior.translucent,
                              child: Container(
                                width: 80,
                                height: 40,
                                alignment: Alignment.center,
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xDE4B2EFF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
      ),
    );
  }
}
