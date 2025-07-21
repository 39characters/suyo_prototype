import 'package:flutter/material.dart';
import '../screens/booking_screen.dart';
import '../screens/errand_booking_screen.dart';

class ServiceDetailsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> service;

  const ServiceDetailsBottomSheet({Key? key, required this.service}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String label = service['label'] ?? 'Service';
    final String description = service['description'] ?? 'No description available.';
    final double? price = service['price'] != null ? (service['price'] as num).toDouble() : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            price != null
                ? 'Starts at ₱${price.toStringAsFixed(2)}'
                : 'Price not available',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B2EFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () {
                final category = service['firestoreCategory'];
                final price = service['price'];

                if (category == "Errands") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ErrandBookingScreen(
                        serviceCategory: category,
                        price: price,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(
                        serviceCategory: category,
                        price: price,
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Proceed',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}