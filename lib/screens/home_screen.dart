import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/service_details_bottom_sheet.dart';
import '../widgets/service_list_card.dart';
import '../widgets/bottom_nav_bar.dart';
 

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
      "label": "Handyman",
      "icon": Icons.handyman,
      "image": "assets/images/handyman.png",
      "description": "Got repairs that need attention? Our trusted handymen are here to get it done quickly and reliably.",
      "price": 270.0,
      "firestoreCategory": "Handyman",
    },
    {
      "label": "Home Cleaning",
      "icon": Icons.cleaning_services,
      "image": "assets/images/home_cleaning.png",
      "description": "Need your space spotless and organized? Our home cleaning pros are ready to make your home shine.",
      "price": 450.0,
      "firestoreCategory": "Home Cleaning",
    },
    {
      "label": "Laundry Service",
      "icon": Icons.local_laundry_service,
      "image": "assets/images/laundry.png",
      "description": "Need fresh and clean laundry done? Our laundry experts are ready to help.",
      "price": 200.0,
      "firestoreCategory": "Laundry Service",
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
          _buildActivity(),
          _buildBookings(),
          _buildMessages(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _pages[_selectedTab],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _selectedTab, onTap: _onTabTapped),
    );
  }

  Widget _buildHomeContent() {
    final String welcomeTitle = 'Welcome to SUYO!';
    final String subtitle = 'Booking a service today?';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: const BoxDecoration(
              color: Color(0xFF422CC6), // Welcome to SUYO BG
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        welcomeTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                // profile icon (tap to open Profile route)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.grey[100],
                          appBar: AppBar(
                            backgroundColor: const Color(0xFF422CC6),
                            iconTheme: const IconThemeData(color: Colors.white),
                            title: const Text('Profile', style: TextStyle(color: Colors.white)),
                            centerTitle: true,
                            elevation: 1,
                          ),
                          body: _buildProfile(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFFDA834C), width: 3), // Orange ring
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person_outline, color: Color(0xFF4B2DFF)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text('Services Available', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),

          // Service list
          Column(
            children: services.take(3).map((service) {
              final disabled = service['disabled'] == true || _hasOngoingBooking;
              return Opacity(
                opacity: disabled ? 0.5 : 1,
                child: ServiceListCard(
                  title: service['label'],
                  description: service['description'] ?? '',
                  icon: service['icon'],
                  imageAsset: service['image'] as String?,
                  onSelect: disabled
                      ? null
                      : () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            backgroundColor: Colors.white,
                            builder: (_) => ServiceDetailsBottomSheet(service: service),
                          );
                        },
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 40),
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
        final totalBookings = data['completedJobs'] ?? data['completedBookings'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              // top profile card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    // avatar with orange ring
                    Container(
                      width: 92,
                      height: 92,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDA834C), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFF3F3F3),
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF202020)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName.isNotEmpty ? displayName : 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF202020))),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Customer', style: TextStyle(color: Color(0xFF4B2DFF), fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 8),
                          Text(email, style: const TextStyle(color: Color(0x8A202020))),
                        ],
                      ),
                    ),
                    // edit button
                    ElevatedButton(
                      onPressed: () {
                        // placeholder for edit profile
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit profile tapped')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B2DFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statCard('${totalBookings.toString()}', 'Bookings'),
                  _statCard('${rating.toStringAsFixed(1)}', 'Rating'),
                  _statCard('${ratingCount.toString()}', 'Reviews'),
                ],
              ),

              const SizedBox(height: 18),

              // actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) Navigator.pushReplacementNamed(context, '/');
                      },
                      icon: const Icon(Icons.logout, size: 18, color: Colors.white),
                      label: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B2DFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleteUserData,
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // settings list
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.payment, color: Color(0xFF4B2DFF)),
                      title: const Text('Payment Methods'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payments tapped'))),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Color(0xFF4B2DFF)),
                      title: const Text('Account Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings tapped'))),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help_outline, color: Color(0xFF4B2DFF)),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help tapped'))),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivity() {
    return const Center(child: Text('[Activity] here!', style: TextStyle(fontSize: 20)));
  }

  Widget _buildBookings() {
    return const Center(child: Text('[Bookings] here!', style: TextStyle(fontSize: 20)));
  }

  Widget _buildMessages() {
    return const Center(child: Text('[Messages] here!', style: TextStyle(fontSize: 20)));
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

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF202020))),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0x8A202020))),
          ],
        ),
      ),
    );
  }
}