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
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _listenToBookingStatus();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _listenToBookingStatus() {
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);

    _bookingSubscription = bookingRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final status = data['status'];
      final serviceType = data['serviceCategory'];
      List<dynamic> eligibleProviders = data['eligibleProviders'] ?? [];

      // --- Booking accepted ---
      if (status == 'accepted') {
        _bookingSubscription?.cancel();
        _timer?.cancel();

        final startedAt = DateFormat('h:mm a').format(DateTime.now());
        final eta = widget.provider?['eta'] ?? "30 mins";

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 A provider has accepted your booking!')),
        );

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
        return;
      }

      // --- Booking declined ---
      if (status == 'declined') {
        if (serviceType.toLowerCase() == 'business') {
          // Cancel immediately for business bookings
          await bookingRef.update({
            'status': 'cancelled',
            'cancelledAt': Timestamp.now(),
          });
        } else {
          // Errands: remove this provider from eligible list
          eligibleProviders.remove(widget.provider?['uid']);
          if (eligibleProviders.isEmpty) {
            await bookingRef.update({
              'status': 'cancelled',
              'cancelledAt': Timestamp.now(),
            });
          } else {
            await bookingRef.update({'eligibleProviders': eligibleProviders});
          }
        }
      }

      // --- Booking cancelled (any type) ---
      if (status == 'cancelled') {
        _bookingSubscription?.cancel();
        _timer?.cancel();

        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Booking Cancelled"),
            content: const Text(
                "Your booking was cancelled by all available service providers. Please try again."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
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
    _timer?.cancel();
    super.dispose();
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatElapsed(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
          title: const Text('Pending Booking', style: TextStyle(color: Colors.white)),
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
          child: ListView(
            children: [
              Center(
                child: Column(
                  children: [
                    const Text("⏳ Waiting for a provider...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Elapsed: ${_formatElapsed(_elapsedSeconds)}", style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B2EFF)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("📦 Booking Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _infoRow("Service", widget.serviceCategory),
                      _infoRow("Price", "₱${widget.price.toStringAsFixed(2)}"),
                      _infoRow("Booking ID", widget.bookingId),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                color: const Color(0xFFF1F3FF),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: widget.provider != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("👤 Provider Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text("Name: ${widget.provider!['name']}", style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text("Distance: ${widget.provider!['distance']} km", style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text("ETA: ${widget.provider!['eta']}", style: const TextStyle(fontSize: 16)),
                          ],
                        )
                      : Column(
                          children: const [
                            Text("No provider has accepted yet.",
                                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Cancel Booking"),
                    content: const Text("Are you sure you want to cancel this booking?"),
                    actions: [
                      TextButton(
                        child: const Text("No"),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      ElevatedButton(
                        child: const Text("Yes"),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  _cancelBooking();
                }
              },
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
