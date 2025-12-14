import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/features/dashboard/providers.dart';

import 'dart:math' as math;

class MonthlyTrendChart extends ConsumerWidget {
  const MonthlyTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(monthlyNetTrendProvider);

    return trend.when(
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _CardWrap(
        child: Text('Error: $e'),
      ),
      data: (points) {
        if (points.isEmpty) {
          return const _CardWrap(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                  'Not enough data to show a trend yet. Add transactions to see your monthly trajectory.'),
            ),
          );
        }

        // With 1 point a "line" is boring – still draw, but show helper text.
        final onlyOne = points.length == 1;

        // Build spots (x = index, y = net)
        final spots = <FlSpot>[
          for (int i = 0; i < points.length; i++)
            FlSpot(i.toDouble(), points[i].net),
        ];

        // Compute y-range with padding, keep zero visible if range tiny.
        final values = points.map((p) => p.net).toList();
        double minY = values.reduce((a, b) => a < b ? a : b);
        double maxY = values.reduce((a, b) => a > b ? a : b);
        if (minY == maxY) {
          // Expand around a flat value so we see area/line
          minY -= 10;
          maxY += 10;
        }
        // Pad range
        final pad = (maxY - minY) * 0.15;
        minY -= pad;
        maxY += pad;

        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;

        return _CardWrap(
          child: SizedBox(
            height: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Net Trend', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (points.length - 1).toDouble(),
                      minY: minY,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _niceStep((maxY - minY) / 4),
                      ),
                      borderData: FlBorderData(show: false),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: 0,
                            color: theme.colorScheme.outlineVariant,
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                        ],
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 56,
                            getTitlesWidget: (v, _) => Text(_moneyCompact(v),
                                style: theme.textTheme.bodySmall),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= points.length) {
                                return const SizedBox.shrink();
                              }
                              // Show first, middle, last tick to reduce clutter
                              final isFirst = idx == 0;
                              final isLast = idx == points.length - 1;
                              final isMid = idx == (points.length / 2).floor();
                              if (!(isFirst || isMid || isLast)) {
                                return const SizedBox.shrink();
                              }
                              final m = points[idx].month;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('${m.month}/${m.year % 100}',
                                    style: theme.textTheme.bodySmall),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((ts) {
                              final idx = ts.spotIndex;
                              final month = points[idx].month;
                              final net = points[idx].net;
                              return LineTooltipItem(
                                '${_monthName(month.month)} ${month.year}\n'
                                '${_moneyFull(net)}',
                                theme.textTheme.bodyMedium!.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 3,
                          color: primary,
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                primary.withAlpha(20),
                                primary.withAlpha(5),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (s, _, __, ___) {
                              final isNeg = s.y < 0;
                              final c = isNeg
                                  ? theme.colorScheme.error
                                  : Colors.green;
                              return FlDotCirclePainter(
                                radius: 3.5,
                                strokeWidth: 1.5,
                                strokeColor: theme.colorScheme.surface,
                                color: c,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (onlyOne)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'You have data for only one month—add more transactions to see a clearer trend.',
                      style: theme.textTheme.bodySmall!
                          .copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Simple card wrapper to keep visuals consistent
class _CardWrap extends StatelessWidget {
  const _CardWrap({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

/// Format helpers -------------------------------------------------------------

String _moneyFull(double v) {
  final s = v.abs().toStringAsFixed(2);
  return v < 0 ? '-\$$s' : '+\$ $s';
}

String _moneyCompact(double v) {
  final abs = v.abs();
  String unit = '';
  double num = abs;

  if (abs >= 1e9) {
    num = abs / 1e9;
    unit = 'B';
  } else if (abs >= 1e6) {
    num = abs / 1e6;
    unit = 'M';
  } else if (abs >= 1e3) {
    num = abs / 1e3;
    unit = 'k';
  }
  String s = num.toStringAsFixed(num >= 100
      ? 0
      : num >= 10
          ? 1
          : 2);
  s += unit;
  return v < 0 ? '-\$$s' : '\$$s';
}

double _niceStep(double approx) {
  // rounds an approximate step to a "nice" value for grid intervals
  if (approx <= 0) return 1;
  final exponent = (math.log(approx) / math.ln10).floor(); // base-10 exponent
  final fraction = approx / math.pow(10, exponent);
  double niceFraction;
  if (fraction < 1.5) {
    niceFraction = 1;
  } else if (fraction < 3) {
    niceFraction = 2;
  } else if (fraction < 7) {
    niceFraction = 5;
  } else {
    niceFraction = 10;
  }
  return niceFraction * math.pow(10, exponent);
}

/// Minimal helper to avoid importing dart:math directly into the file.
class MathHelper {
  static double pow(double x, int p) {
    double r = 1;
    for (int i = 0; i < p.abs(); i++) {
      r *= x;
    }
    return p >= 0 ? r : 1 / r;
  }
}

String _monthName(int m) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  if (m < 1 || m > 12) return '$m';
  return names[m - 1];
}
