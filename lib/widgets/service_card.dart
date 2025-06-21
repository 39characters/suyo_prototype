import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final double iconSize;
  final TextStyle textStyle;
  final Color backgroundColor;

  const ServiceCard({
    Key? key,
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.iconSize = 40,
    this.textStyle = const TextStyle(fontSize: 16),
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: Colors.white),
            SizedBox(height: 12),
            Text(label, style: textStyle.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
