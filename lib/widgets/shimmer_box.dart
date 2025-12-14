import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A lightweight shimmer/skeleton box you can reuse anywhere.
/// Customize width/height/borderRadius, and optional child overlay.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1200),
    this.child,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final Widget? child;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = widget.baseColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? scheme.surfaceContainerHighest.withAlpha(28)
            : scheme.surfaceContainerHighest.withAlpha(52));
    final hi = widget.highlightColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? scheme.surfaceTint.withAlpha(35)
            : scheme.primary.withAlpha(18));

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // Slide a diagonal gradient across the box.
        final t = _ctrl.value;
        final dx = (t * 2 - 1) * 1.2; // -1.2 → 1.2
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: CustomPaint(
            painter: _ShimmerPainter(
              baseColor: base,
              highlightColor: hi,
              offset: dx,
            ),
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.baseColor,
    required this.highlightColor,
    required this.offset,
  });

  final Color baseColor;
  final Color highlightColor;
  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Background
    final bgPaint = Paint()..color = baseColor;
    canvas.drawRect(rect, bgPaint);

    // Diagonal highlight gradient band
    final width = size.width;
    final height = size.height;
    final diag = math.sqrt(width * width + height * height);
    final band = diag * 0.35;

    final centerX = width * (offset * 0.5 + 0.5);
    final shader = LinearGradient(
      colors: [
        baseColor,
        highlightColor,
        baseColor,
      ],
      stops: const [0.35, 0.5, 0.65],
      begin: Alignment(-1, -1),
      end: Alignment(1, 1),
      transform: GradientRotation(math.pi / 6), // slight diagonal
    ).createShader(Rect.fromCenter(
      center: Offset(centerX, height / 2),
      width: diag + band,
      height: band,
    ));

    final paint = Paint()..shader = shader;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.offset != offset ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor;
}
