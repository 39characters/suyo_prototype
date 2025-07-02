import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'provider_home_screen.dart';

class RateCustomerScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? customer;
  final String serviceCategory;
  final double price;

  const RateCustomerScreen({
    Key? key,
    required this.bookingId,
    required this.customer,
    required this.serviceCategory,
    required this.price,
  }) : super(key: key);

  @override
  _RateCustomerScreenState createState() => _RateCustomerScreenState();
}

class _RateCustomerScreenState extends State<RateCustomerScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    if (_rating == 0) return;

    setState(() => _isSubmitting = true);

    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);
    final customerId = widget.customer?['id'];

    try {
      // Save rating & feedback to booking document
      await bookingRef.update({
        'customerRating': _rating,
        'customerFeedback': _feedbackController.text.trim(),
        'customerRatedAt': DateTime.now(),
      });

      if (customerId != null) {
        final customerRef = FirebaseFirestore.instance.collection('users').doc(customerId);

        // Update customer's average rating
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(customerRef);
          if (!snapshot.exists) return;

          final data = snapshot.data()!;
          final currentRating = (data['rating'] ?? 4.5).toDouble();
          final ratingCount = (data['ratingCount'] ?? 0) as int;

          final newRatingCount = ratingCount + 1;
          final newRating = ((currentRating * ratingCount) + _rating) / newRatingCount;

          transaction.update(customerRef, {
            'rating': newRating,
            'ratingCount': newRatingCount,
          });
        });
      }

      setState(() => _isSubmitting = false);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Thank you!"),
          content: const Text("Your feedback has been submitted."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => ProviderHomeScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error submitting rating: $e")));
    }
  }

  Widget buildStar(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _rating = index;
        });
      },
      child: Icon(
        Icons.star,
        size: 36,
        color: index <= _rating ? Colors.orange : Colors.grey[300],
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.customer?['name'] ?? "Customer";
    final customerPhoto = widget.customer?['photoUrl'] ?? "https://via.placeholder.com/150";
    final serviceCategory = widget.serviceCategory;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Rate Your Customer"),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundImage: NetworkImage(customerPhoto),
            ),
            const SizedBox(height: 12),
            Text(
              customerName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              serviceCategory,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            const Text(
              "How was the customer?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => buildStar(index + 1)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Leave a comment (optional)",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: (_rating == 0 || _isSubmitting) ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: (_rating == 0 || _isSubmitting) ? Colors.grey : const Color(0xFF4B2EFF),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Rating", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
    