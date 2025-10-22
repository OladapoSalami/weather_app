import 'package:flutter/material.dart';

class AdditionalInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AdditionalInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blueAccent),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
