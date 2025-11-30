import 'package:flutter/material.dart';

class ProviderCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  final bool highlighted;
  final void Function()? onSelect;
  final void Function()? onViewRatings;

  const ProviderCard({Key? key, required this.provider, this.highlighted = false, this.onSelect, this.onViewRatings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = provider['name'] ?? 'Unnamed Provider';
    final rating = (provider['rating'] ?? 0.0).toDouble();
    final distance = provider['distance'] ?? '';
    final city = provider['city'] ?? '';
    final priceText = provider['priceText'] ?? '';
    final ratingCount = provider['ratingCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name + Badge + Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Avatar with initial
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8E8FF),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() : '').take(1).join() : '?',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Badge on same line
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: Color(0xFFF56D16), size: 18),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Stars + Rating Count
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final fill = i < rating.round();
                          return Icon(Icons.star, size: 15, color: fill ? const Color(0xFFF4B740) : Colors.grey.shade300);
                        }),
                        const SizedBox(width: 6),
                        Text(
                          '$ratingCount ratings',
                          style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Location
          if (city.isNotEmpty || distance.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                city.isNotEmpty && distance.isNotEmpty ? '$city, $distance km away' : city,
                style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
            ),
          // Price
          if (priceText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(priceText, style: const TextStyle(color: Color(0xFF4B2DFF), fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          // Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B2DFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Choose Provider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.1)),
            ),
          ),
          const SizedBox(height: 8),
          // View Ratings Link
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: onViewRatings,
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8)),
              child: Text(
                'View ${name.split(' ').first}\'s Ratings',
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  color: Color(0xFF4B2DFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  decorationColor: Color(0xFF4B2DFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
