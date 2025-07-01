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

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    final uid = currentUser?.uid;
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': status,
      'providerId': uid,
      'providerAcceptedAt': Timestamp.now(),
    });
  }

  Widget _buildJobList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final jobs = snapshot.data!.docs;
        if (jobs.isEmpty) {
          return Center(child: Text("No new jobs", style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
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
              color: Color(0xFF3A22CC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$service – ₱${price.toStringAsFixed(2)}",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    FutureBuilder<String>(
                      future: customerId != null ? _getCustomerName(customerId) : Future.value('Unknown'),
                      builder: (_, snap) {
                        final name = snap.data ?? (snap.connectionState == ConnectionState.waiting ? '...' : 'Unknown');
                        return Text("Customer: $name",
                            style: TextStyle(color: Colors.white70));
                      },
                    ),
                    const SizedBox(height: 4),
                    Text("Location: $lat, $lng",
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _updateBookingStatus(bookingId, 'in_progress'),
                          child: Text("Accept"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _updateBookingStatus(bookingId, 'declined'),
                          child: Text("Decline"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF44336),
                          ),
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
          .where('status', isEqualTo: 'in_progress')
          .where('providerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final inProgress = snapshot.data!.docs;
        if (inProgress.isEmpty) {
          return Center(child: Text("No ongoing jobs", style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: inProgress.length,
          itemBuilder: (context, index) {
            final job = inProgress[index].data() as Map<String, dynamic>;
            final price = (job['price'] ?? 0).toDouble();
            final service = job['serviceCategory'] ?? 'Service';

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Color(0xFF3A22CC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Icon(Icons.timer, color: Colors.white),
                title: Text(
                  "$service – ₱${price.toStringAsFixed(2)}",
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  "In progress",
                  style: TextStyle(color: Colors.white70),
                ),
                trailing:
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                onTap: () {
                  // navigate to job detail if needed
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
      return Center(child: Text("Not signed in", style: TextStyle(color: Colors.white)));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final fullName = data['businessName'] != null
            ? data['businessName']
            : "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.engineering, size: 72, color: Colors.white70),
              const SizedBox(height: 16),
              Text(fullName,
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/');
                },
                child: Text("Sign Out", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF56D16),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
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
        backgroundColor: Color(0xFF4B2EFF),
        elevation: 0,
        title: Text("Provider Dashboard", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      backgroundColor: Color(0xFF4B2EFF),
      body: IndexedStack(index: _selectedTab, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF4B2EFF),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.timelapse), label: 'In Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
