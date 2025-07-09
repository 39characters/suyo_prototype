import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderHomeScreen extends StatefulWidget {
  @override
  _ProviderHomeScreenState createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedTab = 0;
  final currentUser = FirebaseAuth.instance.currentUser;

  void _onTabTapped(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  Future<String> _getCustomerName(String customerId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(customerId).get();
    if (!doc.exists) return 'Unknown';
    final data = doc.data()!;
    return '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
  }

  Future<void> _acceptBooking(String bookingId, Map<String, dynamic> job) async {
    final uid = currentUser?.uid;

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'accepted',
        'providerId': uid,
        'providerAcceptedAt': Timestamp.now(),
      });

      print("✔️ Booking $bookingId status updated to accepted by provider $uid");

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/providerInProgress',
        arguments: {
          'bookingId': bookingId,
        },
      );
    } catch (e) {
      print("❌ Error accepting job: $e");
    }
  }

  Widget _buildJobList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final jobs = snapshot.data!.docs;
        if (jobs.isEmpty) {
          return const Center(child: Text("No new jobs", style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final doc = jobs[index];
            final job = doc.data() as Map<String, dynamic>;
            final bookingId = doc.id;
            final price = (job['price'] ?? 0).toDouble();
            final loc = job['location'] as Map<String, dynamic>?;
            final lat = loc?['lat']?.toStringAsFixed(6) ?? 'N/A';
            final lng = loc?['lng']?.toStringAsFixed(6) ?? 'N/A';
            final service = job['serviceCategory'] ?? 'Service';
            final customerId = job['customerId'] as String?;

            return Card(
              color: const Color(0xFF3A22CC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$service – ₱${price.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<String>(
                      future: customerId != null ? _getCustomerName(customerId) : Future.value('Unknown'),
                      builder: (_, snap) {
                        final name = snap.data ?? (snap.connectionState == ConnectionState.waiting ? '...' : 'Unknown');
                        return Text("Customer: $name", style: const TextStyle(color: Colors.white70));
                      },
                    ),
                    const SizedBox(height: 4),
                    Text("Location: $lat, $lng", style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _acceptBooking(bookingId, job),
                          child: const Text("Accept", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(bookingId)
                              .update({'status': 'declined'}),
                          child: const Text("Decline", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336)),
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


  Widget _buildReceipts() {
    final uid = currentUser?.uid;
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final bookings = snapshot.data!.docs;

        if (bookings.isEmpty) {
          return const Center(child: Text("No completed jobs", style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final data = bookings[index].data() as Map<String, dynamic>;
            final completedAt = data['completedAt']?.toDate();
            final dateStr = completedAt != null
                ? "${completedAt.month}/${completedAt.day}/${completedAt.year}"
                : "Date unknown";
            final price = data['price'] ?? 0;
            final service = data['serviceCategory'] ?? 'Service';
            final customer = data['customerId'];

            return Card(
              color: const Color(0xFF3A22CC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.white),
                title: Text("$service – ₱$price", style: const TextStyle(color: Colors.white)),
                subtitle: Text("Completed on $dateStr", style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                onTap: () => _showReceiptPopup(data),
              ),
            );
          },
        );
      },
    );
  }

  void _showReceiptPopup(Map<String, dynamic> data) {
    final completedAt = data['completedAt']?.toDate();
    final dateStr = completedAt != null
        ? "${completedAt.month}/${completedAt.day}/${completedAt.year} ${completedAt.hour}:${completedAt.minute.toString().padLeft(2, '0')}"
        : "Unknown";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Booking Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _receiptRow("Service:", data['serviceCategory']),
            _receiptRow("Price:", "₱${data['price']}"),
            _receiptRow("Completed At:", dateStr),
            _receiptRow("Customer Rating:", "${data['customerRating'] ?? 'N/A'} / 5"),
            _receiptRow("Feedback:", data['customerFeedback'] ?? "No feedback"),
            _receiptRow("Location:", "${data['location']['lat']}, ${data['location']['lng']}"),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Close", style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black),
          children: [
            TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final user = currentUser;
    if (user == null) {
      return const Center(child: Text("Not signed in", style: TextStyle(color: Colors.white)));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final fullName = data['businessName'] != null
            ? data['businessName']
            : "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
        final profession = data['serviceCategory'] ?? "No profession listed";
        final rating = (data['rating'] ?? 0).toDouble();
        final ratingCount = data['ratingCount'] ?? 0;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3420B3), // 🔵 darker purple card
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // 🎯 Profile icon with matching theme background
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF7c76a3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.engineering, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profession,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRatingStars(rating),
                      const SizedBox(height: 4),
                      Text(
                        "${rating.toStringAsFixed(1)} / 5 from $ratingCount ratings",
                        style: const TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text("Sign Out", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF56D16),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ],
              ),
            ),
          );
        },
      );
  }


  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round()
              ? Icons.star
              : index < rating ? Icons.star_half : Icons.star_border,
          color: Colors.amber,
          size: 28,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildJobList(),
      _buildReceipts(),
      _buildProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF4B2EFF),
        elevation: 0,
        title: const Text("Provider Dashboard", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF4B2EFF),
      body: IndexedStack(index: _selectedTab, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4B2EFF),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Receipts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
