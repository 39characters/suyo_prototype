import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  Map<String, dynamic>? _selectedProvider;

  final List<Map<String, dynamic>> nearbyProviders = [
    {
      "name": "Anna's Cleaners",
      "lat": 14.5995,
      "lng": 120.9842,
      "eta": "15 min",
      "rating": 4.8,
    },
    {
      "name": "Kuya Jon's Service",
      "lat": 14.6002,
      "lng": 120.9835,
      "eta": "10 min",
      "rating": 4.5,
    },
    {
      "name": "Criselda Home Care",
      "lat": 14.5989,
      "lng": 120.9857,
      "eta": "12 min",
      "rating": 4.7,
    },
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final hasPermission = await Geolocator.requestPermission();
    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _userLocation = LatLng(pos.latitude, pos.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userLocation == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Map placeholder (you can replace with GoogleMap if API key is set)
                Container(
                  height: 300,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: Text(
                    "Map Placeholder",
                    style: TextStyle(color: Colors.black54),
                  ),
                ),

                // Bottom panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(16),
                    height: 260,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Nearby Providers",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: ListView.separated(
                            itemCount: nearbyProviders.length,
                            separatorBuilder: (_, __) => Divider(height: 16),
                            itemBuilder: (context, index) {
                              final p = nearbyProviders[index];
                              final isSelected = _selectedProvider == p;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedProvider = p;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Color(0xFFEDEBFF)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Color(0xFF4B2EFF)
                                                  : Colors.black,
                                            ),
                                          ),
                                          Text(
                                            "ETA: ${p['eta']}",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.star,
                                              size: 16,
                                              color: Colors.orange),
                                          SizedBox(width: 4),
                                          Text("${p['rating']}")
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _selectedProvider == null
                              ? null
                              : () async {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => AlertDialog(
                                      content: Row(
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(width: 16),
                                          Text("Finding available provider..."),
                                        ],
                                      ),
                                    ),
                                  );

                                  await Future.delayed(Duration(seconds: 2));
                                  Navigator.pop(context); // Close loader

                                  Navigator.pushNamed(context, "/inprogress");
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedProvider == null
                                ? Colors.grey
                                : Color(0xFF4B2EFF),
                            minimumSize: Size.fromHeight(45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Request Service",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
