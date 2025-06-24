import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/service_card.dart';
import '../widgets/service_details_bottom_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                                  service: service,
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

  Widget _buildReceipts() => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Receipts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF3A22CC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Icon(Icons.receipt_long, color: Colors.white),
                title: Text("Laundry Service - ₱500", style: TextStyle(color: Colors.white)),
                subtitle: Text("June 15, 2025 - Completed", style: TextStyle(color: Colors.white70)),
                trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                onTap: () {},
              ),
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF3A22CC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Icon(Icons.receipt_long, color: Colors.white),
                title: Text("Pet Sitting - ₱300", style: TextStyle(color: Colors.white)),
                subtitle: Text("June 10, 2025 - Completed", style: TextStyle(color: Colors.white70)),
                trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                onTap: () {},
              ),
            ),
          ],
        ),
      );

  Widget _buildChatLogs() => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Chats", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF3A22CC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text("Anna's Cleaners", style: TextStyle(color: Colors.white)),
                subtitle: Text("Thanks again for booking with us!", style: TextStyle(color: Colors.white70)),
                trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                onTap: () {},
              ),
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF3A22CC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text("Kuya Jon's Service", style: TextStyle(color: Colors.white)),
                subtitle: Text("On the way now.", style: TextStyle(color: Colors.white70)),
                trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                onTap: () {},
              ),
            ),
          ],
        ),
      );

  Widget _buildProfile() {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text("User data not found", style: TextStyle(color: Colors.white)));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final fullName = "${data['firstName']} ${data['lastName']}";

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 72, color: Colors.white70),
              SizedBox(height: 16),
              Text(
                fullName,
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF56D16),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text("Sign Out", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }


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
      backgroundColor: Color(0xFF4B2EFF),
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
