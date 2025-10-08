import 'package:flutter/material.dart';

class ExpansionCard extends StatelessWidget {
  const ExpansionCard({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              child: Row(
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            AnimatedCrossFade(
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 220),
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: child,
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
