import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/service_card.dart';
import '../widgets/service_details_bottom_sheet.dart';
import 'customer_pending_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedService = -1;
  int _selectedTab = 0;
  Map<String, dynamic>? _pendingBooking;
  String? _pendingBookingId;
  bool _hasOngoingBooking = false;

  @override
  void initState() {
    super.initState();
    _checkPendingOrInProgressBooking();
    debugBookings();
  }

  void debugBookings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: uid)
        .get();

    print("📦 Found ${snap.docs.length} bookings for $uid");
    for (var doc in snap.docs) {
      print(doc.data());
    }
  }

  Future<void> _checkPendingOrInProgressBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: user.uid)
        .where('status', whereIn: ['pending', 'accepted'])
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _pendingBooking = snapshot.docs.first.data();
        _pendingBookingId = snapshot.docs.first.id;
        _hasOngoingBooking = true;
      });
    }
  }

  final List<Map<String, dynamic>> services = [
    {
      "label": "Laundry Service",
      "icon": Icons.local_laundry_service,
      "description": "Need fresh and clean laundry done? Our laundry experts are ready to help.",
      "price": 150.0,
      "firestoreCategory": "Laundry Service",
    },
    {
      "label": "Home Cleaning",
      "icon": Icons.cleaning_services,
      "description": "Need top-rated home cleaners? We’ve got professionals near you.",
      "price": 250.0,
      "firestoreCategory": "Home Cleaning",
    },
    {
      "label": "Pet Sitting",
      "icon": Icons.pets,
      "description": "Need someone to care for your pets while you’re away? Trusted sitters nearby.",
      "price": 300.0,
      "firestoreCategory": "Errands",
    },
    {
      "label": "Coming soon",
      "icon": Icons.construction,
      "disabled": true,
      "description": "Exciting new services will be available soon. Stay tuned!",
    },
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  Widget _buildHomeContent() {
    return Container(
      color: const Color(0xFF4B2EFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_pendingBooking != null && _pendingBookingId != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerPendingScreen(
                      provider: null,
                      serviceCategory: _pendingBooking!['serviceCategory'] ?? 'Service',
                      price: (_pendingBooking!['price'] ?? 0).toDouble(),
                      location: _pendingBooking!['location'],
                      bookingId: _pendingBookingId!,
                      customerId: _pendingBooking!['customerId'],
                    ),
                  ),
                ).then((_) {
                  _checkPendingOrInProgressBooking();
                });
              },
              child: Container(
                width: double.infinity,
                color: Colors.amber,
                padding: const EdgeInsets.all(12),
                child: const Text(
                  "⏳ You have a pending request — tap to view",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'Book a service!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Arial',
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                itemCount: services.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final service = services[index];
                  final isSelected = index == selectedService;

                  return GestureDetector(
                    onTap: service['disabled'] == true || _hasOngoingBooking
                        ? null
                        : () {
                            setState(() => selectedService = index);
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              backgroundColor: const Color(0xFF4B2EFF),
                              builder: (_) => ServiceDetailsBottomSheet(service: service),
                            );
                          },
                    child: Opacity(
                      opacity: service['disabled'] == true || _hasOngoingBooking ? 0.4 : 1,
                      child: ServiceCard(
                        label: service['label'],
                        icon: service['icon'],
                        isSelected: isSelected,
                        iconSize: 48,
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        backgroundColor: const Color(0xFF3A22CC),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceipts() {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: user?.uid)
          .where('status', isEqualTo: 'completed')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No completed bookings yet.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final service = data['serviceCategory'];
            final provider = data['providerName'];
            final price = data['price'];
            final completedAt = data['completedAt']?.toDate();
            final formattedDate = completedAt != null
                ? "${completedAt.month}/${completedAt.day}/${completedAt.year}"
                : "Date unknown";

            return Column(
              children: [
                _buildReceiptTile("$service - ₱$price", "$provider • $formattedDate", data),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReceiptTile(String title, String subtitle, Map<String, dynamic> bookingData) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A22CC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
        onTap: () => _showReceiptDetailsPopup(bookingData),
      ),
    );
  }

  void _showReceiptDetailsPopup(Map<String, dynamic> data) {
    final completedAt = data['completedAt']?.toDate();
    final dateStr = completedAt != null
        ? "${completedAt.month}/${completedAt.day}/${completedAt.year} ${completedAt.hour}:${completedAt.minute.toString().padLeft(2, '0')}"
        : "Unknown";

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Booking Summary",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _infoRow("Service", data['serviceCategory']),
                _infoRow("Provider", data['providerName']),
                _infoRow("Price", "₱${data['price']}"),
                _infoRow("Completed At", dateStr),
                _infoRow("Rating", "${data['customerRating'] ?? 'N/A'} / 5"),
                _infoRow("Feedback", data['customerFeedback']?.isNotEmpty == true ? data['customerFeedback'] : "No feedback"),
                _infoRow("Location", "${data['location']['lat']}, ${data['location']['lng']}"),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B2EFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text("Close", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }

  Widget _buildChatTile(String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A22CC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
        onTap: () {},
      ),
    );
  }

  Widget _buildProfile() {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("User data not found", style: TextStyle(color: Colors.white)));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final displayName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
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
                    color: const Color(0xFF3420B3),
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4B2EFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Customer",
                        style: TextStyle(
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
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
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
    final List<Widget> _pages = [
      _buildHomeContent(),
      _buildReceipts(),
      _buildProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF4B2EFF),
        elevation: 0,
        toolbarHeight: 56,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}, color: Colors.white),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}, color: Colors.white),
        ],
      ),
      backgroundColor: const Color(0xFF4B2EFF),
      body: IndexedStack(index: _selectedTab, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4B2EFF),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Receipts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
