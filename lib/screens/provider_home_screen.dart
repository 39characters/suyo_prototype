import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderHomeScreen extends StatefulWidget {
  @override
  _ProviderHomeScreenState createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedTab = 0;

  void _onTabTapped(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  Widget _buildJobList() {
    final dummyJobs = [
      {
        "title": "Laundry Request - ₱400",
        "customer": "Angela Reyes",
        "location": "Pasig City",
        "time": "Requested 5 mins ago",
      },
      {
        "title": "Pet Sitting - ₱300",
        "customer": "Kuya John",
        "location": "Quezon City",
        "time": "Requested 10 mins ago",
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: dummyJobs.length,
      itemBuilder: (context, index) {
        final job = dummyJobs[index];
        return Card(
          color: Color(0xFF3A22CC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: Icon(Icons.work_outline, color: Colors.white),
            title: Text(job['title']!, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("${job['customer']} • ${job['location']}\n${job['time']}",
                style: TextStyle(color: Colors.white70)),
            isThreeLine: true,
            trailing: ElevatedButton(
              onPressed: () {
                // Accept job logic
              },
              child: Text("Accept"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF56D16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInProgress() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Jobs In Progress",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF3A22CC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: Icon(Icons.timer, color: Colors.white),
              title: Text("House Cleaning - ₱600", style: TextStyle(color: Colors.white)),
              subtitle: Text("Ongoing... Estimated 1 hour", style: TextStyle(color: Colors.white70)),
              trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

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
              Icon(Icons.engineering, size: 72, color: Colors.white70),
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
      _buildJobList(),
      _buildInProgress(),
      _buildProfile(),
    ];

    return Scaffold(
      backgroundColor: Color(0xFF4B2EFF),
      appBar: AppBar(
        backgroundColor: Color(0xFF4B2EFF),
        elevation: 0,
        title: Text("Provider Dashboard", style: TextStyle(color: Colors.white)),
        centerTitle: true,
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
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.timelapse), label: 'In Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
