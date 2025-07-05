import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class ProviderHomeScreen extends StatefulWidget {
  @override
  _ProviderHomeScreenState createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedTab = 0;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _updateLocationIfErrands();
  }

  Future<void> _updateLocationIfErrands() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final data = doc.data();
    if (data == null) return;

    if ((data['serviceCategory'] ?? '').toString().toLowerCase() == 'errands') {
      try {
        final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
          'location': {
            'lat': position.latitude,
            'lng': position.longitude,
          }
        });
        print("📍 Provider location updated for errands-type");
      } catch (e) {
        print("❌ Failed to get location: $e");
      }
    }
  }

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
                          child: const Text(
                            "Accept",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(bookingId)
                              .update({'status': 'declined'}),
                          child: const Text(
                            "Decline",
                            style: TextStyle(color: Colors.white),
                          ),
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

  Widget _buildInProgress() {
    final uid = currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'accepted')
          .where('providerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final inProgress = snapshot.data!.docs;
        if (inProgress.isEmpty) {
          return const Center(child: Text("No ongoing jobs", style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: inProgress.length,
          itemBuilder: (context, index) {
            final job = inProgress[index].data() as Map<String, dynamic>;
            final price = (job['price'] ?? 0).toDouble();
            final service = job['serviceCategory'] ?? 'Service';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF3A22CC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.timer, color: Colors.white),
                title: Text(
                  "$service – ₱${price.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: const Text("In progress", style: TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                onTap: () {
                  final bookingId = inProgress[index].id;
                  Navigator.pushNamed(
                    context,
                    '/providerInProgress',
                    arguments: {'bookingId': bookingId},
                  );
                },
              ),
            );
          },
        );
      },
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

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.engineering, size: 72, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                fullName,
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/');
                },
                child: const Text("Sign Out", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF56D16),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildJobList(), _buildInProgress(), _buildProfile()];

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
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
          BottomNavigationBarItem(icon: Icon(Icons.timelapse), label: 'In Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
