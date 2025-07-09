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
    this.iconSize = 100,
    this.textStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    this.backgroundColor = const Color(0xFF3A22CC),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color selectedBgColor = Colors.white;
    final Color selectedIconColor = const Color(0xFF4B2EFF);
    final Color selectedTextColor = const Color(0xFF4B2EFF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? selectedBgColor : backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: isSelected ? selectedIconColor : Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textStyle.copyWith(
              color: isSelected ? selectedTextColor : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
