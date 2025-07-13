import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animations/animations.dart';
import 'home_screen.dart';

class RatingScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? provider;
  final String serviceCategory;
  final double price;

  const RatingScreen({
    Key? key,
    required this.bookingId,
    required this.provider,
    required this.serviceCategory,
    required this.price,
  }) : super(key: key);

  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> with SingleTickerProviderStateMixin {
  int _rating = 0;
  bool _isSubmitting = false;
  final TextEditingController _feedbackController = TextEditingController();
  late AnimationController _animationController;

  final List<String> _reactions = ["😡", "😞", "😐", "😊", "😍"];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) return;

    setState(() => _isSubmitting = true);

    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);
    final providerId = widget.provider?['id'];

    try {
      await bookingRef.update({
        'rating': _rating,
        'feedback': _feedbackController.text.trim(),
        'ratedAt': DateTime.now(),
      });

      if (providerId != null) {
        final providerRef = FirebaseFirestore.instance.collection('users').doc(providerId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(providerRef);
          if (!snapshot.exists) return;

          final data = snapshot.data()!;
          final currentRating = (data['rating'] ?? 4.5).toDouble();
          final ratingCount = (data['ratingCount'] ?? 0) as int;

          final newRatingCount = ratingCount + 1;
          final newRating = ((currentRating * ratingCount) + _rating) / newRatingCount;

          transaction.update(providerRef, {
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
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => HomeScreen()),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit rating: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStar(int index) {
    return GestureDetector(
      onTap: () {
        setState(() => _rating = index);
      },
      child: AnimatedScale(
        scale: index == _rating ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Icon(
          Icons.star,
          size: 36,
          color: index <= _rating ? Colors.orange : Colors.grey[300],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerName = widget.provider?['name'] ?? "Provider";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Rate Your Provider"),
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
        child: FadeScaleTransition(
          animation: _animationController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 45,
                  backgroundColor: Color(0xFF4B2EFF),
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                providerName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                widget.serviceCategory,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              if (_rating > 0)
                Text(
                  _reactions[_rating - 1],
                  style: const TextStyle(fontSize: 32),
                ),

              const SizedBox(height: 12),
              const Text(
                "How was the service?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => _buildStar(index + 1)),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Service", style: TextStyle(color: Colors.grey[600])),
                        Text(widget.serviceCategory,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Amount", style: TextStyle(color: Colors.grey[600])),
                        Text("₱${widget.price.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
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
                  backgroundColor: (_rating == 0 || _isSubmitting)
                      ? Colors.grey
                      : const Color(0xFF4B2EFF),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text("Submitting...", style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      )
                    : const Text("Submit Rating",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
