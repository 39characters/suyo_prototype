import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/service_card.dart';
import '../widgets/service_details_bottom_sheet.dart';
import 'customer_pending_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int selectedService = -1;
  int _selectedTab = 0;
  Map<String, dynamic>? _pendingBooking;
  String? _pendingBookingId;
  bool _hasOngoingBooking = false;
  String? _displayName; // New field to store the user's name

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkPendingOrInProgressBooking();
    debugBookings();
    _fetchUserName(); // Fetch the user's name from Firestore

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final displayName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
      setState(() {
        _displayName = displayName.isEmpty ? 'User' : displayName;
      });
    }
  }

  Future<void> _deleteUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Confirm Data Deletion",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            "Are you sure you want to delete your account and all associated data? This action cannot be undone.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4B2EFF),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(fontSize: 16, color: Color(0xFF4B2EFF)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                await FirebaseAuth.instance.currentUser?.delete();
                if (mounted) Navigator.pushReplacementNamed(context, '/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4B2EFF),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text(
                "Delete",
                style: TextStyle(fontSize: 16, color: Color(0xFF4B2EFF)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Error deleting data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error deleting data. Please try again.")),
        );
      }
    }
  }

  final List<Map<String, dynamic>> services = [
    {
      "label": "Laundry Service",
      "icon": Icons.local_laundry_service,
      "description": "Need fresh and clean laundry done? Our laundry experts are ready to help.",
      "price": 200.0,
      "firestoreCategory": "Laundry Service",
    },
    {
      "label": "Home Cleaning",
      "icon": Icons.cleaning_services,
      "description": "Need top-rated home cleaners? We’ve got professionals near you.",
      "price": 450.0,
      "firestoreCategory": "Home Cleaning",
    },
    {
      "label": "Pet Sitting",
      "icon": Icons.pets,
      "description": "Need someone to care for your pets while you’re away? Trusted sitters nearby.",
      "price": 270.0,
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
      _fadeController.reset();
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomeContent(),
      _buildReceipts(),
      _buildProfile(),
    ];

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF4B2EFF),
          elevation: 1,
          title: Text(
            _selectedTab == 0
                ? "Book a Service!"
                : _selectedTab == 1
                    ? "Your Receipts"
                    : "Your Profile",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        backgroundColor: Colors.grey[200],
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: _pages[_selectedTab],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4B2EFF),
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedTab,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long, size: 28),
              label: 'Receipts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 28),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final String greeting = _displayName != null && _displayName!.isNotEmpty
        ? "Hello, $_displayName!"
        : "Hello, User!"; // Fallback if name isn't fetched yet

    return SingleChildScrollView(
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
                color: const Color(0xFFF56D16),
                padding: const EdgeInsets.all(16),
                child: const Text(
                  "⏳ You have a pending request — tap to view",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              greeting,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                          setState(() {
                            if (selectedService == index) {
                              selectedService = -1;
                            } else {
                              selectedService = index;
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                backgroundColor: Colors.white,
                                builder: (_) => ServiceDetailsBottomSheet(service: service),
                              ).whenComplete(() {
                                setState(() {
                                  selectedService = -1;
                                });
                              });
                            }
                          });
                        },
                  child: Opacity(
                    opacity: service['disabled'] == true || _hasOngoingBooking ? 0.4 : 1,
                    child: ServiceCard(
                      label: service['label'],
                      icon: service['icon'],
                      isSelected: isSelected,
                      iconSize: 80,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B2EFF),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4B2EFF)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No completed bookings yet.",
              style: TextStyle(color: Colors.black87, fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

            final service = data['serviceCategory'] ?? 'Unknown Service';
            final price = data['price'] ?? 0;
            String provider = "Unknown Provider";
            if (data.containsKey('provider') && data['provider'] is Map) {
              provider = data['provider']['name'] ?? "Unknown Provider";
            } else if (data.containsKey('providerName')) {
              provider = data['providerName'];
            }

            final completedAt = data['completedAt']?.toDate();
            final formattedDate = completedAt != null
                ? DateFormat('MM/dd/yyyy').format(completedAt)
                : "Date unknown";

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: Color(0xFF4B2EFF), size: 30),
                title: Text(
                  "$service - ₱$price",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "$provider • $formattedDate",
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF4B2EFF)),
                onTap: () => _showReceiptDetailsPopup(data),
              ),
            );
          },
        );
      },
    );
  }

  void _showReceiptDetailsPopup(Map<String, dynamic> data) {
    final completedAt = data['completedAt']?.toDate();
    final dateStr = completedAt != null
        ? DateFormat('MM/dd/yyyy HH:mm').format(completedAt)
        : "Unknown";

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Booking Summary",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow("Service", data['serviceCategory'] ?? 'N/A'),
              _infoRow(
                "Provider",
                data['provider'] is Map && data['provider']?['name'] != null
                    ? data['provider']['name']
                    : (data['providerName'] ?? 'Unknown Provider'),
              ),
              _infoRow("Price", "₱${data['price'] ?? 0}"),
              _infoRow("Completed At", dateStr),
              _infoRow("Rating", "${data['customerRating'] ?? 'N/A'} / 5"),
              _infoRow("Feedback", data['customerFeedback']?.isNotEmpty == true ? data['customerFeedback'] : "No feedback"),
              _infoRow("Location", "${data['location']['lat'] ?? 'N/A'}, ${data['location']['lng'] ?? 'N/A'}"),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4B2EFF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text(
              "Close",
              style: TextStyle(fontSize: 16, color: Color(0xFF4B2EFF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4B2EFF)));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          Future.delayed(Duration.zero, () {
            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black.withOpacity(0.6),
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text(
                  "Session Expired",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                content: const Text(
                  "Your user session has expired. Please log in again.",
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(fontSize: 16, color: Color(0xFF4B2EFF)),
                    ),
                  ),
                ],
              ),
            );
          });
          return const Center(
            child: Text(
              "User data not found",
              style: TextStyle(color: Colors.black87, fontSize: 18),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final displayName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
        final email = data['email'] ?? user?.email ?? 'No email';
        final rating = (data['rating'] ?? 0).toDouble();
        final ratingCount = data['ratingCount'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.person, size: 60, color: Color(0xFF4B2EFF)),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Customer",
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      _buildRatingStars(rating),
                      const SizedBox(height: 8),
                      Text(
                        "${rating.toStringAsFixed(1)} / 5 from $ratingCount ratings",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.pushReplacementNamed(context, '/');
                },
                icon: const Icon(Icons.logout, size: 20, color: Colors.white),
                label: const Text(
                  "Sign Out",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B2EFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _deleteUserData,
                icon: const Icon(Icons.delete_forever, size: 20, color: Colors.red),
                label: const Text(
                  "Delete Account",
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.star_border,
              color: Colors.black,
              size: 30,
            ),
            Icon(
              index < rating.round()
                  ? Icons.star
                  : index < rating ? Icons.star_half : Icons.star_border,
              color: Colors.amber,
              size: 28,
            ),
          ],
        );
      }),
    );
  }
}