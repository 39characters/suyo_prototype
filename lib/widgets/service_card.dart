import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const ServiceCard({
    Key? key,
    required this.label,
    required this.icon,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Colors.white;
    final Color unselectedColor = Colors.white.withOpacity(0.2);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? selectedColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
