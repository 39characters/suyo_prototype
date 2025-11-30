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
    this.iconSize = 80,
    this.textStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color iconColor = const Color(0xFF4B2DFF);
    final Color textColor = const Color(0xFF202020);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF4B2DFF) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textStyle.copyWith(
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}