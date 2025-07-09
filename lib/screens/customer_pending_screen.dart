import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suyo_prototype/screens/home_screen.dart';
import 'package:suyo_prototype/screens/job_in_progress_screen.dart';

class CustomerPendingScreen extends StatefulWidget {
  final Map<String, dynamic>? provider;
  final String serviceCategory;
  final double price;
  final Map<String, dynamic> location;
  final String bookingId;
  final String customerId;

  const CustomerPendingScreen({
    Key? key,
    required this.provider,
    required this.serviceCategory,
    required this.price,
    required this.location,
    required this.bookingId,
    required this.customerId,
  }) : super(key: key);

  @override
  State<CustomerPendingScreen> createState() => _CustomerPendingScreenState();
}

class _CustomerPendingScreenState extends State<CustomerPendingScreen> {
  StreamSubscription<DocumentSnapshot>? _bookingSubscription;

  @override
  void initState() {
    super.initState();
    _listenToBookingStatus();
  }

  void _listenToBookingStatus() {
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);

    _bookingSubscription = bookingRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['status'];

        if (status == 'accepted') {
          _bookingSubscription?.cancel();

          final String startedAt = DateFormat('h:mm a').format(DateTime.now());
          final String eta = widget.provider?['eta'] ?? "30 mins";

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => JobInProgressScreen(
                bookingId: widget.bookingId,
                provider: widget.provider,
                serviceCategory: widget.serviceCategory,
                price: widget.price,
                location: data['location'],
                startedAt: startedAt,
                eta: eta,
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _cancelBooking() async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'status': 'cancelled',
        'cancelledAt': Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("❌ Error cancelling booking: $e");
    }
  }

  @override
  void dispose() {
    _bookingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen()),
          (Route<dynamic> route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Pending Booking',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF4B2EFF),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => HomeScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("📦 Booking Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Service:", style: TextStyle(fontSize: 16)),
                  Text(widget.serviceCategory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Price:", style: TextStyle(fontSize: 16)),
                  Text("₱${widget.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Booking ID:", style: TextStyle(fontSize: 16)),
                  Text(widget.bookingId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              const Text("👤 Provider Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              widget.provider != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Name: ${widget.provider!['name']}", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("Distance: ${widget.provider!['distance']} km", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("ETA: ${widget.provider!['eta']}", style: const TextStyle(fontSize: 16)),
                      ],
                    )
                  : const Text(
                      "Provider has not yet accepted the request.",
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
            ],
          ),
        ),

        /// 👇 Cancel Button Placed at Bottom
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: ElevatedButton.icon(
              onPressed: _cancelBooking,
              icon: const Icon(Icons.cancel, color: Colors.white),
              label: const Text("Cancel Booking", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
