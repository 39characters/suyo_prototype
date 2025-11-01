import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

Future<Map<String, dynamic>?> showPresetPickerModal(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final presetsRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('location_presets');

  return await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    barrierColor: Colors.black.withOpacity(0.6),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    backgroundColor: Colors.white,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Select a Location Preset",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: presetsRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No saved locations yet.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.place, color: Color(0xFF4B2EFF), size: 28),
                        title: Text(
                          data['label'] ?? 'Unnamed Location',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "Lat: ${data['lat']}, Lng: ${data['lng']}\n${data['address'] ?? 'No address'}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            try {
                              await docs[index].reference.delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Location deleted")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Failed to delete location: $e")),
                              );
                            }
                          },
                        ),
                        onTap: () => Navigator.pop(context, data),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final position = await Geolocator.getCurrentPosition();
                        final result = await _promptDetails(context);
                        if (result != null) {
                          await presetsRef.add({
                            'label': result['label'],
                            'name': result['name'],
                            'contactNumber': result['contactNumber'],
                            'address': result['address'],
                            'lat': position.latitude,
                            'lng': position.longitude,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Location '${result['label']}' added"),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to add location: $e")),
                        );
                      }
                    },
                    icon: const Icon(Icons.my_location, size: 20),
                    label: const Text("Add Current Location"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4B2EFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final picked = await _pickLocationOnMap(context);
                        if (picked != null) {
                          final result = await _promptDetails(context);
                          if (result != null) {
                            await presetsRef.add({
                              'label': result['label'],
                              'name': result['name'],
                              'contactNumber': result['contactNumber'],
                              'address': result['address'],
                              'lat': picked.latitude,
                              'lng': picked.longitude,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Location '${result['label']}' added"),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to add location: $e")),
                        );
                      }
                    },
                    icon: const Icon(Icons.map, size: 20),
                    label: const Text("Pick on Map"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4B2EFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<Map<String, String>?> _promptDetails(BuildContext context) async {
  final labelController = TextEditingController();
  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final addressController = TextEditingController();

  return await showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Enter Location Details",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: "Location Label",
                hintText: "e.g., Home, Office",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                hintText: "e.g., John Doe",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(
                labelText: "Contact Number",
                hintText: "e.g., +1234567890",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: "Address",
                hintText: "e.g., 123 Main St, City",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (labelController.text.trim().isEmpty ||
                nameController.text.trim().isEmpty ||
                contactController.text.trim().isEmpty ||
                addressController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please fill in all fields")),
              );
              return;
            }
            Navigator.pop(context, {
              'label': labelController.text.trim(),
              'name': nameController.text.trim(),
              'contactNumber': contactController.text.trim(),
              'address': addressController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4B2EFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Save", style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
  );
}

Future<LatLng?> _pickLocationOnMap(BuildContext context) async {
  const LatLng defaultCenter = LatLng(14.5995, 120.9842);
  LatLng tempSelected = defaultCenter;

  return await showDialog<LatLng>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Pick Location on Map",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (controller) async {
                try {
                  final style = await DefaultAssetBundle.of(context).loadString('assets/map_style.json');
                  controller.setMapStyle(style);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to load map style: $e")),
                  );
                }
              },
              initialCameraPosition: const CameraPosition(target: defaultCenter, zoom: 15),
              onCameraMove: (position) => tempSelected = position.target,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              padding: const EdgeInsets.all(8),
            ),
            const Align(
              alignment: Alignment.center,
              child: Icon(Icons.location_on, size: 48, color: Color(0xFFF56D16)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, tempSelected),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4B2EFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Confirm", style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
  );
}