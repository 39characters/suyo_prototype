import 'package:flutter/material.dart';

class JobInProgressScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final providerName = provider?['name'] ?? "Unknown Provider";
    final providerPhoto = provider?['photoUrl'] ?? "https://via.placeholder.com/150";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Service In Progress",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4B2EFF),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(providerPhoto),
              ),
            ),
            const SizedBox(height: 16),

            // Provider Name
            Center(
              child: Text(
                providerName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 6),

            // Job Type
            Center(
              child: Text(
                serviceCategory,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const Divider(height: 32, thickness: 1),

            // ETA and Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoTile(title: "Started At", value: startedAt),
                _InfoTile(title: "ETA", value: eta),
              ],
            ),

            const SizedBox(height: 16),

            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Price:", style: TextStyle(fontSize: 16)),
                Text(
                  "₱${price.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Booking ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Booking ID:", style: TextStyle(fontSize: 16)),
                Text(
                  bookingId,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Location info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Location:", style: TextStyle(fontSize: 16)),
                Text(
                  "(${location['lat'].toStringAsFixed(4)}, ${location['lng'].toStringAsFixed(4)})",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Info Card
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

            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Add real contact provider logic
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Contact"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/rate");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Done"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
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

                                // Mock support alert
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Panic"),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
