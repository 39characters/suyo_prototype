import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({Key? key, required this.currentIndex, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const selectedColor = Color(0xFF4B2DFF); // Active icon/text
    const unselectedColor = Color(0xFF777777); // Inactive icon/text

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: selectedColor),
      unselectedLabelStyle: const TextStyle(fontSize: 14, color: unselectedColor),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: 28),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long, size: 28),
          label: 'Activity',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule, size: 28),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline, size: 28),
          label: 'Messages',
        ),
      ],
    );
  }
}
