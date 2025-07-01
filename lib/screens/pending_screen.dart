import 'package:flutter/material.dart';
import 'package:suyo_prototype/screens/home_screen.dart';

class PendingScreen extends StatelessWidget {
  final Map<String, dynamic>? provider;
  final String serviceCategory; 
  final double price;
  final String bookingId;

  const PendingScreen({
    Key? key,
    required this.provider,
    required this.serviceCategory,
    required this.price,
    required this.bookingId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen()), // Replace with your actual HomeScreen
          (Route<dynamic> route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pending Booking'),
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
                  Text(serviceCategory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Price:", style: TextStyle(fontSize: 16)),
                  Text("₱${price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Booking ID:", style: TextStyle(fontSize: 16)),
                  Text(bookingId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              const Text("👤 Provider Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              provider != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Name: ${provider!['name']}", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("Distance: ${provider!['distance']} km", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("ETA: ${provider!['eta']}", style: const TextStyle(fontSize: 16)),
                      ],
                    )
                  : const Text(
                      "Provider has not yet accepted the request.",
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
