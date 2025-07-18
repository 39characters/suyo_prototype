import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'rate_customer_screen.dart';

class ProviderInProgressScreen extends StatefulWidget {
  final String bookingId;

  const ProviderInProgressScreen({Key? key, required this.bookingId}) : super(key: key);

  @override
  State<ProviderInProgressScreen> createState() => _ProviderInProgressScreenState();
}

class _ProviderInProgressScreenState extends State<ProviderInProgressScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _elapsed = Duration.zero;
  late SharedPreferences _prefs;
  late AnimationController _animationController;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _initializeTimer();
  }

  Future<void> _initializeTimer() async {
    _prefs = await SharedPreferences.getInstance();
    final startMillis = _prefs.getInt('${widget.bookingId}_startTime');
    DateTime startTime;

    if (startMillis != null) {
      startTime = DateTime.fromMillisecondsSinceEpoch(startMillis);
    } else {
      startTime = DateTime.now();
      _prefs.setInt('${widget.bookingId}_startTime', startTime.millisecondsSinceEpoch);
    }

    _startTime = startTime;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(startTime);
      });
    });
  }

  Future<Map<String, dynamic>> _getCustomerData(String customerId) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(customerId);
    final snapshot = await doc.get();
    if (!snapshot.exists) return {};
    final data = snapshot.data()!;
    return {
      'id': customerId,
      'name': "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim(),
      'phone': data['phone'] ?? '',
      'address': data['address'] ?? '',
    };
  }

  Future<void> _handleMarkAsDone(
    BuildContext context,
    String customerId,
    String serviceCategory,
    double price,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Completion"),
        content: const Text("Are you sure the service is fully completed?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Complete")),
        ],
      ),
    );

    if (confirm != true) return;

    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);
    await bookingRef.update({
      'status': 'completed',
      'completedAt': Timestamp.now(),
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return [
      if (hours > 0) hours.toString().padLeft(2, '0'),
      minutes.toString().padLeft(2, '0'),
      seconds.toString().padLeft(2, '0'),
    ].join(':');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final booking = snapshot.data!.data() as Map<String, dynamic>?;
        if (booking == null) {
          return const Scaffold(body: Center(child: Text("Booking not found.")));
        }

        final status = booking['status'] ?? '';
        final serviceCategory = booking['serviceCategory'] ?? 'Unknown';
        final price = (booking['price'] ?? 0).toDouble();
        final lat = booking['location']?['lat'] ?? 0.0;
        final lng = booking['location']?['lng'] ?? 0.0;
        final customerId = booking['customerId'] ?? '';

        if (status == 'completed') {
          return FutureBuilder<Map<String, dynamic>>(
            future: _getCustomerData(customerId),
            builder: (context, customerSnapshot) {
              if (!customerSnapshot.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final customer = customerSnapshot.data ?? {};
              return RateCustomerScreen(
                bookingId: widget.bookingId,
                customer: customer,
                serviceCategory: serviceCategory,
                price: price,
              );
            },
          );
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: _getCustomerData(customerId),
          builder: (context, customerSnapshot) {
            final customer = customerSnapshot.data ?? {};
            final customerName = customer['name'] ?? 'Loading...';
            final customerPhone = customer['phone'] ?? '';
            final customerAddress = customer['address'] ?? '';

            final formattedStartTime = _startTime != null
                ? TimeOfDay.fromDateTime(_startTime!).format(context)
                : '--:--';
            final eta = _startTime != null ? _startTime!.add(const Duration(minutes: 45)) : null;
            final formattedETA = eta != null ? TimeOfDay.fromDateTime(eta).format(context) : '--:--';

            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text(
                  "Service In Progress",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: const Color(0xFF4B2EFF),
              ),
              backgroundColor: Colors.white,
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const CircleAvatar(
                            radius: 55,
                            backgroundColor: Color(0xFF4B2EFF), // Purple background
                            child: Icon(Icons.person, size: 40, color: Colors.white), // White icon
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white,
                              child: const Icon(Icons.person, size: 18, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(customerName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    Center(
                      child: Text(serviceCategory,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MiniInfoColumn(title: "Start Time", value: formattedStartTime),
                        _MiniInfoColumn(title: "ETA", value: formattedETA),
                        _MiniInfoColumn(title: "Timer", value: _formatDuration(_elapsed)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _InfoTile(title: "Booking ID", value: widget.bookingId),
                    _InfoTile(title: "Phone", value: customerPhone),
                    _InfoTile(title: "Address", value: customerAddress),
                    _InfoTile(
                        title: "Location",
                        value: "(${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})"),
                    _InfoTile(title: "Price", value: "₱${price.toStringAsFixed(2)}"),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.timer, color: Colors.black54),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "The service is currently in progress. Please wait until it's completed.",
                              style: TextStyle(fontSize: 15, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // TODO: Implement contact logic
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4B2EFF),
                              side: const BorderSide(color: Color(0xFF4B2EFF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Contact"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleMarkAsDone(
                              context,
                              customerId,
                              serviceCategory,
                              price,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4B2EFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Mark as Done"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Panic Alert"),
                                  content: const Text("Trigger emergency alert?"),
                                  actions: [
                                    TextButton(
                                      child: const Text("Cancel"),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    TextButton(
                                      child: const Text("Trigger"),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Emergency alert triggered."),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFb05a4f),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Panic", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$title:", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoColumn extends StatelessWidget {
  final String title;
  final String value;

  const _MiniInfoColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
