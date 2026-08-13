import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:n8ntrial/models/app_state.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_updateScreen);
  }

  @override
  void dispose() {
    appState.removeListener(_updateScreen);
    super.dispose();
  }

  void _updateScreen() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Simulated dynamic stats based on selected time period
    String checks = "256";
    String fakes = "84";
    String reals = "172";
    double realRatio = 0.67;
    double fakeRatio = 0.26;
    double suspRatio = 0.07;

    if (appState.timePeriod == "This Month") {
      checks = "1,204";
      fakes = "340";
      reals = "864";
      realRatio = 0.72;
      fakeRatio = 0.23;
      suspRatio = 0.05;
    } else if (appState.timePeriod == "Yearly") {
      checks = "14,350";
      fakes = "4,120";
      reals = "10,230";
      realRatio = 0.71;
      fakeRatio = 0.25;
      suspRatio = 0.04;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter dropdown selector matching screenshot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Performance Timeline",
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white70 : Colors.black87
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: appState.timePeriod,
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white70 : Colors.black87
                    ),
                    items: const [
                      DropdownMenuItem(value: "This Week", child: Text("This Week")),
                      DropdownMenuItem(value: "This Month", child: Text("This Month")),
                      DropdownMenuItem(value: "Yearly", child: Text("Yearly")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        appState.setTimePeriod(val);
                      }
                    },
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),

          // Stat cards row
          Row(
            children: [
              Expanded(
                child: _buildStatTile("Total Checks", checks, Colors.blue[300]!, theme.colorScheme.surface),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile("Fake Detected", fakes, const Color(0xFFFF2A54), theme.colorScheme.surface),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatTile("Real Verified", reals, const Color(0xFF2EC4B6), theme.colorScheme.surface),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Donut chart representation card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Detection Overview",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Custom paint donut chart
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CustomPaint(
                        painter: DonutChartPainter(
                          realRatio: realRatio,
                          fakeRatio: fakeRatio,
                          suspRatio: suspRatio,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Legend details
                    Expanded(
                      child: Column(
                        children: [
                          _buildLegendRow("Real", "${(realRatio * 100).round()}%", const Color(0xFF2EC4B6)),
                          const SizedBox(height: 8),
                          _buildLegendRow("Fake", "${(fakeRatio * 100).round()}%", const Color(0xFFFF2A54)),
                          const SizedBox(height: 8),
                          _buildLegendRow("Suspicious", "${(suspRatio * 100).round()}%", const Color(0xFFFFC400)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Categories Progress bar card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Most Checked Categories",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 16),
                _buildCategoryProgress("Politics", 0.45, const Color(0xFF2EC4B6)),
                _buildCategoryProgress("Health", 0.25, const Color(0xFF007AFF)),
                _buildCategoryProgress("Entertainment", 0.15, const Color(0xFFFF9500)),
                _buildCategoryProgress("Finance", 0.10, const Color(0xFF5E5BF6)),
                _buildCategoryProgress("Others", 0.05, Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color accentColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, String percent, Color dotColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.circle, color: dotColor, size: 10),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        Text(
          percent,
          style: TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryProgress(String name, double value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: isDark ? const Color(0xFF080C16) : const Color(0xFFF1F3F6),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "${(value * 100).round()}%",
            style: TextStyle(
              fontSize: 11, 
              fontFamily: 'monospace', 
              color: isDark ? Colors.white70 : Colors.black87
            ),
          )
        ],
      ),
    );
  }
}

// Dynamic Donut Painter
class DonutChartPainter extends CustomPainter {
  final double realRatio;
  final double fakeRatio;
  final double suspRatio;

  DonutChartPainter({
    required this.realRatio,
    required this.fakeRatio,
    required this.suspRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double strokeWidth = 14.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromCircle(center: center, radius: radius - strokeWidth);

    double startAngle = -math.pi / 2;

    // Real
    paint.color = const Color(0xFF2EC4B6);
    double sweepAngle = realRatio * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    startAngle += sweepAngle;

    // Fake
    paint.color = const Color(0xFFFF2A54);
    sweepAngle = fakeRatio * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    startAngle += sweepAngle;

    // Suspicious
    paint.color = const Color(0xFFFFC400);
    sweepAngle = suspRatio * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
