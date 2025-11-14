import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:suyo_prototype/widgets/location_preset_picker.dart';
import 'package:suyo_prototype/screens/provider_in_progress_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  _ProviderHomeScreenState createState() => _ProviderHomeScreenState();
}

class FakeBooking {
  static Map<String, dynamic> sample() {
    return {
      'serviceCategory': 'survey',
      'price': 150.0,
      'customerId': 'sample_customer_id',
      'location': {
        'lat': 14.5995,
        'lng': 120.9842,
        'label': 'Sample Location',
        'name': 'John Doe',
        'contactNumber': '09171234567',
        'address': '123 Sample St, Manila',
      },
      'status': 'pending',
      'description': 'Sample survey booking for testing',
      'fake': true, // optional flag to identify it
    };
  }
}


class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedTab = 0;
  final currentUser = FirebaseAuth.instance.currentUser;
  bool locationReady = false;
  String? displayName;
  static Map<String, dynamic>? _cachedReceiptsData; // Cache for receipts data
  static Map<String, dynamic>? _cachedAnalyticsData; // Cache for analytics
  double? _selectedLat; // State variable for latitude
  double? _selectedLng; // State variable for longitude

  bool _isTesting = true; // Set true to inject a fake booking for testing

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkIfErrandProviderAndRequestLocation();
  }

  Future<void> _loadUserData() async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return;

    setState(() {
      displayName = data['businessName']?.toString() ??
          "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
    });
  }

  Future<void> _checkIfErrandProviderAndRequestLocation() async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return;

    final isErrands = (data['serviceCategory'] ?? '').toString().toLowerCase() == 'errands';

    if (!isErrands) {
      setState(() => locationReady = true);
      return;
    }

    while (!locationReady && mounted) {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.6), // Dark tint background
        builder: (_) => AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          title: const Text(
            "📍 Location Access Required",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            "To provide errand services, please enable location access. This is essential for matching you with jobs in your coverage area.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'allow'),
              child: const Text(
                "Allow Location",
                style: TextStyle(fontSize: 16, color: Color(0xFF4B2EFF)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'sign_out'),
              child: const Text(
                "Sign Out",
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (result == 'sign_out') {
        await FirebaseAuth.instance.signOut();
        if (mounted) Navigator.pushReplacementNamed(context, '/');
        return;
      }

      if (result == 'allow') {
        final preset = await showPresetPickerModal(context);
        if (preset != null) {
          final selectedLat = preset['lat'] as double;
          final selectedLng = preset['lng'] as double;

          print("📍 Selected Location: ${preset['label']} ($selectedLat, $selectedLng)");
          print("Details: Name: ${preset['name']}, Contact: ${preset['contactNumber']}, Address: ${preset['address']}");

          setState(() {
            locationReady = true;
            _selectedLat = selectedLat;
            _selectedLng = selectedLng;
          });

          // Save to Firestore
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'location': {
              'lat': selectedLat,
              'lng': selectedLng,
              'label': preset['label'],
              'name': preset['name'],
              'contactNumber': preset['contactNumber'],
              'address': preset['address'],
            },
          });
        } else {
          print("❌ No preset selected.");
          // Continue the loop to prompt again
        }
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        setState(() => locationReady = true);
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

  void _acceptBooking(String bookingId, Map<String, dynamic> job) {
    final uid = currentUser?.uid;
    if (job.containsKey('fake')) {
      // Navigate directly for the fake job
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderInProgressScreen(
            bookingId: 'fake_booking_001', // can be any string
          ),
        ),
      );
      return;
    }

    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'providerId': uid, 'status': 'in_progress'}).then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderInProgressScreen(bookingId: bookingId),
        ),
      );
    });
  }

  Future<void> _deleteUserData() async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    try {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Confirm Data Deletion"),
          content: const Text(
            "Are you sure you want to delete your account and all associated data? This action cannot be undone.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(fontSize: 16)),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                await FirebaseAuth.instance.currentUser?.delete();
                if (mounted) Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text(
                "Delete",
                style: TextStyle(fontSize: 16, color: Colors.red),
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

  Widget _buildJobList() {
    final uid = currentUser?.uid;
    if (uid == null) {
      return const Center(
          child: Text("User not signed in", style: TextStyle(fontSize: 18)));
    }

    // Load provider category once
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, providerSnapshot) {
        if (!providerSnapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4B2EFF)));
        }

        final providerData =
            providerSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final providerCategory = providerData['serviceCategory'] ?? '';

        // StreamBuilder for bookings
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4B2EFF)));
            }

            // Filter jobs for this provider
            final jobs = snapshot.data!.docs.where((doc) {
              final job = doc.data() as Map<String, dynamic>;
              final jobCategory = (job['serviceCategory'] ?? '').toString();
              final assignedProvider = job['providerId'] as String?;
              return (assignedProvider == null && jobCategory == providerCategory) ||
                  assignedProvider == uid;
            }).toList();

            // --- Add a sample fake booking for testing ---
            final fakeJob = {
              'serviceCategory': 'Survey',
              'price': 0.0,
              'customerId': 'sample_customer_id',
              'location': {'lat': 14.5995, 'lng': 120.9842},
              'fake': true, // optional flag
            };

            final allJobs = [
              ...jobs,
              {
                'serviceCategory': 'Survey',
                'price': 0.0,
                'customerId': 'sample_customer_id',
                'location': {'lat': 14.5995, 'lng': 120.9842},
                'fake': true, // optional flag
              }
            ];

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allJobs.length,
              itemBuilder: (context, index) {
                final doc = allJobs[index];
                Map<String, dynamic> job;

                if (doc is QueryDocumentSnapshot) {
                  job = doc.data() as Map<String, dynamic>;
                } else if (doc is Map<String, dynamic>) {
                  job = doc;
                } else {
                  // fallback for safety
                  job = {};
                }

                final bookingId = doc is QueryDocumentSnapshot ? doc.id : 'FAKE_JOB';
                final price = (job['price'] ?? 0).toDouble();
                final loc = job['location'] as Map<String, dynamic>?;
                final lat = loc?['lat']?.toStringAsFixed(6) ?? 'N/A';
                final lng = loc?['lng']?.toStringAsFixed(6) ?? 'N/A';
                final service = job['serviceCategory'] ?? 'Service';
                final customerId = job['customerId'] as String?;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$service – ₱${price.toStringAsFixed(2)}",
                          style:
                              const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<String>(
                          future: customerId != null
                              ? _getCustomerName(customerId)
                              : Future.value('Unknown'),
                          builder: (_, snap) {
                            final name = snap.data ?? '...';
                            return Text("Customer: $name",
                                style: const TextStyle(fontSize: 16));
                          },
                        ),
                        const SizedBox(height: 8),
                        Text("Location: $lat, $lng",
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _acceptBooking(bookingId, job),
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: const Text("Accept", style: TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4B2EFF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                if (job.containsKey('fake')) return; // skip DB update
                                FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(bookingId)
                                    .update({'status': 'declined'});
                              },
                              icon: const Icon(Icons.cancel, size: 20),
                              label: const Text("Decline", style: TextStyle(fontSize: 16)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
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
      },
    );
  }



  Widget _buildReceipts() {
    final uid = currentUser?.uid;
    return FutureBuilder<QuerySnapshot>(
      future: uid != null
          ? FirebaseFirestore.instance
              .collection('bookings')
              .where('providerId', isEqualTo: uid)
              .where('status', isEqualTo: 'completed')
              .get()
          : Future.value(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4B2EFF)));
        }

        final bookings = snapshot.data!.docs;
        if (bookings.isEmpty) {
          return const Center(child: Text("No completed jobs", style: TextStyle(fontSize: 18)));
        }

        _cachedReceiptsData = {'bookings': bookings.map((doc) => doc.data()).toList()};

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final data = bookings[index].data() as Map<String, dynamic>;
            final completedAt = data['completedAt']?.toDate();
            final dateStr = completedAt != null
                ? DateFormat('MM/dd/yyyy').format(completedAt)
                : "Date unknown";
            final price = data['price'] ?? 0;
            final service = data['serviceCategory'] ?? 'Service';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: Color(0xFF4B2EFF), size: 30),
                title: Text(
                  "$service – ₱$price",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "Completed on $dateStr",
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF4B2EFF)),
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
        ? DateFormat('MM/dd/yyyy HH:mm').format(completedAt)
        : "Unknown";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Booking Details",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _receiptRow("Service:", data['serviceCategory'] ?? 'N/A'),
            _receiptRow("Price:", "₱${data['price'] ?? 0}"),
            _receiptRow("Completed At:", dateStr),
            _receiptRow("Customer Rating:", "${data['customerRating'] ?? 'N/A'} / 5"),
            _receiptRow("Feedback:", data['customerFeedback'] ?? "No feedback"),
            _receiptRow("Location:", "${data['location']?['lat'] ?? 'N/A'}, ${data['location']?['lng'] ?? 'N/A'}"),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Close", style: TextStyle(fontSize: 16, color: Color(0xFF4B2EFF))),
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
          style: const TextStyle(fontSize: 16, color: Colors.black),
          children: [
            TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateAnalytics(List<Map<String, dynamic>> bookings) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    final yearStart = DateTime(now.year, 1, 1);

    Map<String, dynamic> analytics = {
      'today': {'count': 0, 'revenue': 0.0, 'avgRating': 0.0},
      'week': {'count': 0, 'revenue': 0.0, 'avgRating': 0.0},
      'month': {'count': 0, 'revenue': 0.0, 'avgRating': 0.0},
      'year': {'count': 0, 'revenue': 0.0, 'avgRating': 0.0},
    };

    for (var booking in bookings) {
      final completedAt = booking['completedAt']?.toDate();
      if (completedAt == null) continue;

      final price = booking['price'] is num ? booking['price'].toDouble() : 0.0;
      final rating = booking['customerRating'] is num ? booking['customerRating'].toDouble() : 0.0;

      if (completedAt.isAfter(todayStart)) {
        analytics['today']['count']++;
        analytics['today']['revenue'] += price;
        if (rating > 0) {
          analytics['today']['avgRating'] = (analytics['today']['avgRating'] * (analytics['today']['count'] - 1) + rating) / analytics['today']['count'];
        }
      }
      if (completedAt.isAfter(weekStart)) {
        analytics['week']['count']++;
        analytics['week']['revenue'] += price;
        if (rating > 0) {
          analytics['week']['avgRating'] = (analytics['week']['avgRating'] * (analytics['week']['count'] - 1) + rating) / analytics['week']['count'];
        }
      }
      if (completedAt.isAfter(monthStart)) {
        analytics['month']['count']++;
        analytics['month']['revenue'] += price;
        if (rating > 0) {
          analytics['month']['avgRating'] = (analytics['month']['avgRating'] * (analytics['month']['count'] - 1) + rating) / analytics['month']['count'];
        }
      }
      if (completedAt.isAfter(yearStart)) {
        analytics['year']['count']++;
        analytics['year']['revenue'] += price;
        if (rating > 0) {
          analytics['year']['avgRating'] = (analytics['year']['avgRating'] * (analytics['year']['count'] - 1) + rating) / analytics['year']['count'];
        }
      }
    }

    return analytics;
  }

  Widget _buildAnalytics() {
    final uid = currentUser?.uid;
    return FutureBuilder<QuerySnapshot>(
      future: uid != null
          ? FirebaseFirestore.instance
              .collection('bookings')
              .where('providerId', isEqualTo: uid)
              .where('status', isEqualTo: 'completed')
              .get()
          : Future.value(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF4B2EFF)),
                const SizedBox(height: 16),
                const Text(
                  "Loading your performance stats...",
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        _cachedReceiptsData = {'bookings': bookings};
        _cachedAnalyticsData = _calculateAnalytics(bookings);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Your Performance Snapshot",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B2EFF),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatCard('Today', _cachedAnalyticsData?['today']),
                      _buildStatCard('This Week', _cachedAnalyticsData?['week']),
                      _buildStatCard('This Month', _cachedAnalyticsData?['month']),
                      _buildStatCard('This Year', _cachedAnalyticsData?['year']),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String period, Map<String, dynamic>? stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.trending_up, color: Color(0xFF4B2EFF), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4B2EFF)),
                ),
                Text("Jobs: ${stats?['count'] ?? 0}", style: const TextStyle(fontSize: 14)),
                Text("Earnings: ₱${(stats?['revenue'] ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontSize: 14)),
                Text("Avg Rating: ${(stats?['avgRating'] ?? 0.0).toStringAsFixed(1)}/5", style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final user = currentUser;
    if (user == null) {
      return const Center(child: Text("Not signed in", style: TextStyle(fontSize: 18)));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4B2EFF)));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final fullName = data['businessName'] != null
            ? data['businessName']
            : "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
        final profession = data['serviceCategory'] ?? "No profession listed";
        final rating = (data['rating'] ?? 0).toDouble();
        final ratingCount = data['ratingCount'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                "Hello, $fullName!",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.engineering, size: 60, color: Color(0xFF4B2EFF)),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profession,
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.pushReplacementNamed(context, '/');
                },
                icon: const Icon(Icons.logout, size: 20),
                label: const Text("Sign Out", style: TextStyle(fontSize: 16)),
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
            Icon(
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildJobList(),
      _buildReceipts(),
      _buildAnalytics(),
      _buildProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF4B2EFF),
        elevation: 1,
        title: Text(
          displayName != null ? "Welcome, $displayName!" : "Provider Dashboard",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: locationReady
          ? IndexedStack(index: _selectedTab, children: pages)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF4B2EFF)),
                  const SizedBox(height: 16),
                  Text(
                    displayName != null
                        ? "Setting up for you, $displayName..."
                        : "Loading your dashboard...",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4B2EFF),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment, size: 28),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long, size: 28),
            label: 'Receipts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart, size: 28),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}