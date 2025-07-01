import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderInProgressScreen extends StatelessWidget {
  final String bookingId;

  const ProviderInProgressScreen({Key? key, required this.bookingId}) : super(key: key);

  Future<Map<String, dynamic>> _getBookingData() async {
    final doc = await FirebaseFirestore.instance.collection('bookings').doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking not found');
    return doc.data()!;
  }

  Future<String> _getCustomerName(String customerId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(customerId).get();
    if (!doc.exists) return 'Unknown';
    final data = doc.data()!;
    return '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Job In Progress",
          style: TextStyle(color: Colors.white),
          ),
        backgroundColor: const Color(0xFF4B2EFF),
        elevation: 1,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.warning, color: Colors.white),
        tooltip: "Emergency Panic Button",
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Emergency"),
              content: const Text("Are you sure you want to trigger the panic alert?"),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text("Yes, Trigger"),
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Alert Sent"),
                        content: const Text("Support has been notified. Stay safe."),
                        actions: [
                          TextButton(
                            child: const Text("OK"),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                    print("🚨 Panic button triggered for booking $bookingId");
                  },
                ),
              ],
            ),
          );
        },
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getBookingData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("❌ Error: ${snapshot.error}"));
          }

          final booking = snapshot.data!;
          final lat = booking['location']?['lat'] ?? 0.0;
          final lng = booking['location']?['lng'] ?? 0.0;
          final serviceCategory = booking['serviceCategory'] ?? 'Unknown';
          final price = (booking['price'] ?? 0).toDouble();
          final customerId = booking['customerId'];

          return FutureBuilder<String>(
            future: _getCustomerName(customerId),
            builder: (context, customerSnapshot) {
              final customerName = customerSnapshot.data ?? 'Loading...';

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _InfoRow(label: "🛠️ Service", value: serviceCategory),
                    const SizedBox(height: 12),
                    _InfoRow(label: "💰 Price", value: "₱${price.toStringAsFixed(2)}"),
                    const SizedBox(height: 12),
                    _InfoRow(label: "📍 Location", value: "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}"),
                    const SizedBox(height: 12),
                    _InfoRow(label: "👤 Customer", value: customerName),
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
                              // TODO: Add contact logic
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Contact Customer"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .doc(bookingId)
                                  .update({
                                'status': 'completed',
                                'completedAt': Timestamp.now(),
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Mark as Done"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
