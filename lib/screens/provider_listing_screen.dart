import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/provider_card.dart';

class ProviderListingScreen extends StatefulWidget {
  final String serviceCategory;
  final double? price;

  const ProviderListingScreen({Key? key, required this.serviceCategory, this.price}) : super(key: key);

  @override
  State<ProviderListingScreen> createState() => _ProviderListingScreenState();
}

class _ProviderListingScreenState extends State<ProviderListingScreen> {
  List<Map<String, dynamic>> allProviders = [];
  List<Map<String, dynamic>> filteredProviders = [];
  bool loading = true;
  String _sortType = 'Distance';
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      await Geolocator.requestPermission();
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      await _fetchProviders();
    } catch (e) {
      debugPrint('Error getting location: $e');
      await _fetchProviders();
    }
  }

  double _degToRad(double deg) => deg * (pi / 180);

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> _fetchProviders() async {
    setState(() => loading = true);
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'Service Provider')
        .where('serviceCategory', isEqualTo: widget.serviceCategory)
        .get();

    final results = snapshot.docs.map((doc) {
      final data = doc.data();
      final location = data['location'];
      double? lat, lng;
      if (location != null && location['lat'] != null && location['lng'] != null) {
        lat = (location['lat'] as num).toDouble();
        lng = (location['lng'] as num).toDouble();
      }

      return {
        'id': doc.id,
        'name': data['businessName'] ?? '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
        'rating': data['rating'] != null ? (data['rating'] as num).toDouble() : 0.0,
        'ratingCount': data['ratingCount'] ?? 0,
        'lat': lat,
        'lng': lng,
        'city': data['city'] ?? '',
        'priceText': data['priceText'] ?? '',
      };
    }).toList();

    setState(() {
      allProviders = results.cast<Map<String, dynamic>>();
      _applySorting();
      loading = false;
    });
  }

  void _applySorting() {
    if (_userLocation == null) {
      filteredProviders = List.from(allProviders);
      return;
    }

    final sorted = allProviders.map((p) {
      double distance = 0;
      if (p['lat'] != null && p['lng'] != null) {
        distance = _calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          p['lat'] as double,
          p['lng'] as double,
        );
      }
      return {
        ...p,
        'distance': distance.toStringAsFixed(1),
        'numericDistance': distance,
      };
    }).toList();

    if (_sortType == 'Rating') {
      sorted.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
    } else if (_sortType == 'Smart') {
      sorted.sort((a, b) {
        final aScore = (a['numericDistance'] as double) * 0.6 - (a['rating'] as double) * 0.4;
        final bScore = (b['numericDistance'] as double) * 0.6 - (b['rating'] as double) * 0.4;
        return aScore.compareTo(bScore);
      });
    } else {
      sorted.sort((a, b) => (a['numericDistance'] as double).compareTo(b['numericDistance'] as double));
    }

    setState(() => filteredProviders = sorted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B2EFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Service Providers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.4)),
            Text(widget.serviceCategory, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0.3)),
          ],
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortType = value;
                _applySorting();
              });
            },
            itemBuilder: (BuildContext context) => ['Distance', 'Rating', 'Smart'].map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              );
            }).toList(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Icon(Icons.sort, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4B2DFF)))
          : Column(
              children: [
                Container(
                  color: Colors.grey.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sorted by: ${_sortType == 'Distance' ? 'Distance' : _sortType == 'Rating' ? 'Rating' : 'Smart'}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87, letterSpacing: 0.2),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchProviders,
                    color: const Color(0xFF4B2DFF),
                    child: filteredProviders.isEmpty
                        ? const Center(child: Text('No providers found', style: TextStyle(fontSize: 15, color: Colors.black54)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            itemCount: filteredProviders.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 0),
                            itemBuilder: (context, index) {
                              final p = filteredProviders[index];
                              return ProviderCard(
                                provider: p,
                                highlighted: false,
                                onSelect: () {
                                  Navigator.pop(context, p);
                                },
                                onViewRatings: () => _showRatings(context, p),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showRatings(BuildContext context, Map<String, dynamic> provider) {
    final providerId = provider['id'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('ratings')
              .where('providerId', isEqualTo: providerId)
              .orderBy('timestamp', descending: true)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            final docs = snapshot.data?.docs ?? [];
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              builder: (context, sc) => Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${provider['name'] ?? 'Provider'} Ratings', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: docs.isEmpty
                          ? const Center(child: Text('No ratings yet'))
                          : ListView.separated(
                              controller: sc,
                              itemCount: docs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final r = docs[i].data() as Map<String, dynamic>;
                                final reviewer = r['reviewerName'] ?? 'Anonymous';
                                final text = r['text'] ?? '';
                                final stars = (r['stars'] ?? 5).toInt();
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(reviewer, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black)),
                                      const SizedBox(height: 8),
                                      Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
                                      const SizedBox(height: 8),
                                      Row(children: List.generate(5, (j) => Icon(Icons.star, size: 14, color: j < stars ? const Color(0xFFF4B740) : Colors.grey.shade300))),
                                    ],
                                  ),
                                );
                              },
                            ),
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
}