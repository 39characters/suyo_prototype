import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_pending_screen.dart';
import 'home_screen.dart';
import 'package:suyo_prototype/widgets/location_preset_picker.dart';

class ErrandBookingScreen extends StatefulWidget {
  final String serviceCategory;
  final double price;

  const ErrandBookingScreen({
    required this.serviceCategory,
    required this.price,
    super.key, // Added super.key for consistency
  });

  @override
  State<ErrandBookingScreen> createState() => _ErrandBookingScreenState();
}

class _ErrandBookingScreenState extends State<ErrandBookingScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _centerLocation;
  LatLng? _userLocation;
  bool _mapLocked = false;
  bool isWaiting = false;
  String? bookingId;
  StreamSubscription<DocumentSnapshot>? bookingListener;

  late AnimationController _circleController;
  late Animation<double> _circleScale;
  late AnimationController _overlayFadeController;

  final _formKey = GlobalKey<FormState>();
  String customerName = '';
  String phone = '';
  String address = '';

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _circleScale = Tween<double>(begin: 1, end: 2).animate(CurvedAnimation(parent: _circleController, curve: Curves.easeOut));
    _overlayFadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    await Geolocator.requestPermission();
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(pos.latitude, pos.longitude);
      _centerLocation = _userLocation;
    });
    await _loadMapStyle();
    await _askPresetLocation(); // Replaced _askUserDetails with _askPresetLocation
  }

  Future<void> _loadMapStyle() async {
    final style = await rootBundle.loadString('assets/map_style.json');
    _mapController?.setMapStyle(style);
  }

  Future<void> _askPresetLocation() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final preset = await showPresetPickerModal(context);
    if (preset != null) {
      setState(() {
        customerName = preset['name'] ?? '';
        phone = preset['contactNumber'] ?? '';
        address = preset['address'] ?? '';
        _centerLocation = LatLng(preset['lat'] as double, preset['lng'] as double);
        _mapLocked = true; // Lock map to preset location
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_centerLocation!),
      );
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("No Location Selected"),
          content: const Text("You need to select a location preset to continue booking."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Try Again", style: TextStyle(color: Color(0xFF4B2EFF))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Go Home", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) {
        await Future.delayed(const Duration(milliseconds: 300));
        _askPresetLocation();
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      }
    }
  }

  void _onCameraMove(CameraPosition pos) {
    if (!_mapLocked) _centerLocation = pos.target;
  }

  Future<void> _submitLocation() async {
    _overlayFadeController.forward();
    setState(() => _mapLocked = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Save Booking Document using nested 'provider' structure
    final bookingDoc = await FirebaseFirestore.instance.collection('bookings').add({
      'customerId': uid,
      'provider': null, // initially no provider
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

    // Save updated user info
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fullName': customerName,
      'phone': phone,
      'address': address,
    });

    setState(() {
      bookingId = bookingDoc.id;
      isWaiting = true;
    });

    // --- AUTO-ACCEPT SIMULATION ---
    // change "auto_accept_provider" to "default" to disable
    const String appMode = "auto_accept_provider"; 
    if (appMode != "default") {
      Future.delayed(const Duration(seconds: 2), () async {
        final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);
        final providerData = {
          'id': 'auto_provider',
          'name': 'Auto-Assigned Provider',
          'photoUrl': null,
          'eta': '30 mins',
          'distance': '1.0',
        };

        await bookingRef.update({
          'status': 'accepted',
          'providerId': 'auto_provider',
          'providerAcceptedAt': Timestamp.now(),
          'provider': providerData,
        });
      });
    }

    // Wait for provider to accept
    bookingListener = FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId!)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      if (data != null && data['status'] == 'accepted') {
        _circleController.stop();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Booking Accepted"),
            content: const Text("A provider has accepted your booking."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerPendingScreen(
                        provider: data['provider'] ?? {
                          'id': data['providerId'],
                          'name': "Your Provider",
                        },
                        serviceCategory: widget.serviceCategory,
                        price: widget.price,
                        location: data['location'],
                        bookingId: bookingId!,
                        customerId: uid,
                      ),
                    ),
                  );
                },
                child: const Text("Continue"),
              ),
            ],
          ),
        );
      }
    });

  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Booking"),
        content: const Text("Are you sure you want to cancel?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );
    if (confirm == true && bookingId != null) {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
      bookingListener?.cancel();
      setState(() {
        isWaiting = false;
        bookingId = null;
        _mapLocked = false;
      });
      _circleController.repeat();
      _overlayFadeController.reverse();
    }
  }

  void _goBackHome() async {
    final shouldGo = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Go back?"),
        content: const Text("Are you sure you want to go back?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );
    if (shouldGo == true) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _circleController.dispose();
    _overlayFadeController.dispose();
    bookingListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async => !isWaiting,
      child: Scaffold(
        body: Stack(
          children: [
            if (_userLocation == null)
              const Center(child: CircularProgressIndicator())
            else
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _userLocation!, zoom: 15),
                onMapCreated: (c) => _mapController = c,
                onCameraMove: _onCameraMove,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                scrollGesturesEnabled: !_mapLocked,
                zoomGesturesEnabled: !_mapLocked,
                rotateGesturesEnabled: !_mapLocked,
                tiltGesturesEnabled: !_mapLocked,
                gestureRecognizers: !_mapLocked
                    ? {
                        Factory(() => EagerGestureRecognizer()),
                        Factory(() => ScaleGestureRecognizer()),
                        Factory(() => PanGestureRecognizer()),
                        Factory(() => VerticalDragGestureRecognizer()),
                        Factory(() => HorizontalDragGestureRecognizer()),
                      }
                    : <Factory<OneSequenceGestureRecognizer>>{}.toSet(),
              ),
            Positioned(
              top: screenHeight * 0.42,
              left: MediaQuery.of(context).size.width / 2 - 24,
              child: const Icon(Icons.location_on, size: 48, color: Color(0xFFF56D16)),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Color(0xFF4B2EFF),
                elevation: 2,
                leading: isWaiting
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white), // Fixed icon color to white for consistency
                        onPressed: _goBackHome,
                      ),
                title: const Text(
                  'Errand Booking',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Container(
                  height: screenHeight * 0.24,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 16, spreadRadius: 2, offset: Offset(0, -6)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 16),
                          children: [
                            const TextSpan(text: 'You are booking for '),
                            TextSpan(
                              text: widget.serviceCategory, // Use dynamic serviceCategory instead of hardcoded 'Pet Sitting'
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Click the button below once you’ve confirmed the exact location.',
                        style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 14),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: Icon(isWaiting ? Icons.cancel : Icons.send, color: Colors.white),
                        label: Text(
                          isWaiting ? "Cancel Booking" : "Submit Booking",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isWaiting ? Colors.red : const Color(0xFF4B2EFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: isWaiting ? _cancelBooking : _submitLocation,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isWaiting)
              Positioned(
                top: kToolbarHeight,
                bottom: screenHeight * 0.19 + 8,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _overlayFadeController.drive(CurveTween(curve: Curves.easeInOutCubic)),
                  child: Container(
                    alignment: Alignment.center,
                    color: const Color(0xE61a1a1a),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _circleController,
                              builder: (_, __) => Container(
                                width: 100 * _circleScale.value,
                                height: 100 * _circleScale.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange.withOpacity(1 - _circleScale.value / 2),
                                ),
                              ),
                            ),
                            const Icon(Icons.pets, size: 50, color: Colors.white),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text("Waiting for provider to accept…", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}