import 'package:flutter/material.dart';

class ServiceListCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? imageAsset;
  final VoidCallback? onSelect;

  const ServiceListCard({Key? key, required this.title, required this.description, required this.icon, this.imageAsset, this.onSelect}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFF4B2DFF); // Purple outline for cards and buttons
    const descriptionColor = Color(0xBF202020); // #202020 at 75% opacity

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 250,
            height: 250,
            padding: const EdgeInsets.all(12),
            child: imageAsset != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imageAsset!,
                      fit: BoxFit.cover,
                      width: 226,
                      height: 226,
                    ),
                  )
                : Icon(icon, size: 140, color: borderColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF202020)),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: descriptionColor),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: onSelect,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: borderColor,
                      side: const BorderSide(color: borderColor, width: 1.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Select Service', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
