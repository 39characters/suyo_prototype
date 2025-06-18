import 'package:flutter/material.dart';
import '../widgets/service_card.dart';
import '../widgets/service_details_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedService = 1; // Index of selected service

  final List<Map<String, dynamic>> services = [
    {"label": "Laundry Service", "icon": Icons.local_laundry_service},
    {"label": "House Cleaning", "icon": Icons.cleaning_services},
    {"label": "Grocery Shopping", "icon": Icons.shopping_cart},
    {"label": "Delivery Service", "icon": Icons.local_shipping},
    {"label": "Gardening", "icon": Icons.grass},
    {"label": "Pet Sitting", "icon": Icons.pets},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4B2EFF),
        elevation: 0,
        title: Text(
          'Book a service!',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          Icon(Icons.notifications_none, color: Colors.white),
          SizedBox(width: 12),
          Icon(Icons.share, color: Colors.white),
          SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: services.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final service = services[index];
            final isSelected = index == selectedService;

            return GestureDetector(
                onTap: () {
                    setState(() {
                        selectedService = index;
                    });
                    showModalBottomSheet(
                        context: context,
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        backgroundColor: Color(0xFF4B2EFF),
                        builder: (_) {
                        return ServiceDetailsBottomSheet(service: services[index]);
                        },
                    );
                    },
                child: ServiceCard(
                    label: service['label'],
                    icon: service['icon'],
                    isSelected: isSelected,
                ),
            );
          },
        ),
      ),
    );
  }
}
