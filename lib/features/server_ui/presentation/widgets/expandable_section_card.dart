import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/server_ui/providers/section_expand_providers.dart';

class ExpandableSectionCard extends ConsumerWidget {
  const ExpandableSectionCard({
    super.key,
    required this.sectionKey,
    required this.title,
    required this.child,
    this.defaultCollapsed = false,
    this.trailing,
  });

  final String sectionKey;
  final String title;
  final Widget child;
  final bool defaultCollapsed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = SectionExpandArgs(
      key: sectionKey,
      defaultExpanded:
          !defaultCollapsed, // server says "collapsed" -> defaultExpanded=false
    );

    final expandedAsync = ref.watch(sectionExpandedProvider(args));

    return expandedAsync.when(
      loading: () => _CardShell(
        title: title,
        trailing: trailing,
        expanded: !defaultCollapsed,
        onToggle: null,
        child: const SizedBox(
          height: 84,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (e, _) => _CardShell(
        title: title,
        trailing: trailing,
        expanded: !defaultCollapsed,
        onToggle: null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Failed to load section state: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      data: (expanded) => _CardShell(
        title: title,
        trailing: trailing,
        expanded: expanded,
        onToggle: () =>
            ref.read(sectionExpandedProvider(args).notifier).toggle(),
        child: child,
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.title,
    required this.expanded,
    required this.child,
    required this.onToggle,
    this.trailing,
  });

  final String title;
  final bool expanded;
  final Widget child;
  final VoidCallback? onToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onToggle,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (trailing != null) ...[
                    trailing!,
                    const SizedBox(width: 8),
                  ],
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: expanded ? 0 : -0.5,
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: child,
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
