import 'package:flutter/material.dart';
import '../widgets/service_card.dart';
import '../widgets/service_details_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedService = -1;
  int _selectedTab = 0;

  final List<Map<String, dynamic>> services = [
    {
      "label": "Laundry Service",
      "icon": Icons.local_laundry_service,
      "description": "Need fresh and clean laundry done? Our laundry experts are ready to help."
    },
    {
      "label": "House Cleaning",
      "icon": Icons.cleaning_services,
      "description": "Need top-rated home cleaners? We’ve got professionals near you."
    },
    {
      "label": "Pet Sitting",
      "icon": Icons.pets,
      "description": "Need someone to care for your pets while you’re away? Trusted sitters nearby."
    },
    {
      "label": "Coming soon",
      "icon": Icons.construction,
      "disabled": true,
      "description": "Exciting new services will be available soon. Stay tuned!"
    },
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  Widget _buildHomeContent() {
    return Container(
      color: Color(0xFF4B2EFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            color: Colors.white,
          ),
          SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
          SizedBox(height: 32),
          Expanded(
            child: Padding(
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
                    onTap: service['disabled'] == true
                        ? null
                        : () {
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
                                return ServiceDetailsBottomSheet(
                                  service: services[index],
                                );
                              },
                            );
                          },
                    child: Opacity(
                      opacity: service['disabled'] == true ? 0.4 : 1,
                      child: ServiceCard(
                        label: service['label'],
                        icon: service['icon'],
                        isSelected: isSelected,
                        iconSize: 48,
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        backgroundColor: Color(0xFF3A22CC),
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

  Widget _buildReceipts() => Center(child: Text("📟 Receipts screen (mock)", style: TextStyle(fontSize: 16)));
  Widget _buildChatLogs() => Center(child: Text("💬 Chat logs screen (mock)", style: TextStyle(fontSize: 16)));
  Widget _buildProfile() => Center(child: Text("👤 Profile screen (mock)", style: TextStyle(fontSize: 16)));

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomeContent(),
      _buildReceipts(),
      _buildChatLogs(),
      _buildProfile(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF4B2EFF),
        elevation: 0,
        toolbarHeight: 56,
        actions: [
          IconButton(icon: Icon(Icons.notifications_none), onPressed: () {}, color: Colors.white),
          IconButton(icon: Icon(Icons.share), onPressed: () {}, color: Colors.white),
        ],
      ),
      body: IndexedStack(index: _selectedTab, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF4B2EFF),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Receipts'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
