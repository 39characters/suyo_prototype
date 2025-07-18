import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animations/animations.dart';
import 'package:suyo_prototype/screens/rating_screen.dart';

class JobInProgressScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? provider;
  final String serviceCategory;
  final double price;
  final String startedAt;
  final String eta;
  final Map<String, dynamic> location;

  const JobInProgressScreen({
    Key? key,
    required this.bookingId,
    required this.provider,
    required this.serviceCategory,
    required this.price,
    required this.startedAt,
    required this.eta,
    required this.location,
  }) : super(key: key);

  @override
  State<JobInProgressScreen> createState() => _JobInProgressScreenState();
}

class _JobInProgressScreenState extends State<JobInProgressScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _elapsed = Duration.zero;
  late SharedPreferences _prefs;
  late AnimationController _animationController;

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

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(startTime);
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _markAsDone(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Completion"),
        content: const Text("Are you sure the service is completed?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Complete")),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({'status': 'completed', 'completedAt': Timestamp.now()});
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return [
      if (hours > 0) hours.toString().padLeft(2, '0'),
      minutes.toString().padLeft(2, '0'),
      seconds.toString().padLeft(2, '0')
    ].join(':');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final bookingData = snapshot.data!.data() as Map<String, dynamic>?;
        if (bookingData == null) {
          return const Scaffold(
            body: Center(child: Text("Booking not found.")),
          );
        }

        final startMillis = _prefs.getInt('${widget.bookingId}_startTime');
        final startTime = startMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(startMillis)
            : DateTime.now();

        final formattedStartTime = TimeOfDay.fromDateTime(startTime).format(context);
        final eta = startTime.add(const Duration(minutes: 45));
        final formattedETA = TimeOfDay.fromDateTime(eta).format(context);

        final rawProvider = bookingData['provider'] ?? widget.provider ?? {};
        final providerData = (rawProvider is Map)
            ? Map<String, dynamic>.from(rawProvider)
            : <String, dynamic>{};

        if (bookingData['status'] == 'completed') {
          return RatingScreen(
            bookingId: widget.bookingId,
            provider: providerData,
            serviceCategory: widget.serviceCategory,
            price: widget.price,
          );
        }

        final providerType = providerData['serviceCategory'] ?? "";
        final providerName = providerType == "Errands"
            ? "${providerData['firstName'] ?? ''} ${providerData['lastName'] ?? ''}".trim()
            : providerData['name'] ?? "Unknown Provider";

        final customerName = bookingData['customerName'] ?? 'N/A';
        final customerPhone = bookingData['phone'] ?? 'N/A';
        final customerAddress = bookingData['address'] ?? 'N/A';

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text("Service In Progress",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF4B2EFF),
          ),
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: FadeScaleTransition(
              animation: _animationController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 55,
                          backgroundColor: Color(0xFF4B2EFF),
                          child: Icon(Icons.person, size: 40, color: Colors.white),
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
                    child: Text(providerName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  Center(
                    child: Text(widget.serviceCategory,
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
                  _InfoTile(title: "Price", value: "₱${widget.price.toStringAsFixed(2)}"),
                  _InfoTile(title: "Booking ID", value: widget.bookingId),
                  _InfoTile(
                      title: "Location",
                      value:
                          "(${widget.location['lat'].toStringAsFixed(4)}, ${widget.location['lng'].toStringAsFixed(4)})"),
                  _InfoTile(title: "Customer Name", value: customerName),
                  _InfoTile(title: "Phone", value: customerPhone),
                  _InfoTile(title: "Address", value: customerAddress),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.black54),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "The service is currently in progress. You’ll be notified when it's completed.",
                            style: TextStyle(fontSize: 15),
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
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF4B2EFF)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Contact",
                              style: TextStyle(color: Color(0xFF4B2EFF))),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _markAsDone(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B2EFF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Mark as Done",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                                      onPressed: () => Navigator.pop(context)),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Panic", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          Text("$title:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
