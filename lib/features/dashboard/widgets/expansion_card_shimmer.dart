import 'package:flutter/material.dart';
import 'package:mini_finan/widgets/shimmer_box.dart';

class ExpansionCardShimmer extends StatelessWidget {
  const ExpansionCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          // Left title shimmer (mimic title text)
          ShimmerBox(width: 140, height: 18, borderRadius: 8),
          Spacer(),
          // Right side shimmer (e.g. icon, total, or toggle arrow)
          ShimmerBox(width: 24, height: 24, borderRadius: 8),
        ],
      ),
    );
  }
}
