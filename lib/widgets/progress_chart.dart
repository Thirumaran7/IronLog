import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_service.dart';

class ProgressChart extends StatefulWidget {
  const ProgressChart({super.key});

  @override
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart> {
  List<int> weeklyCounts = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await DatabaseService.instance.getWeeklyWorkouts();

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    weeklyCounts = List.filled(7, 0);

    for (final row in data) {
      final day = DateTime.parse(row["day"]);
      final index = day.difference(monday).inDays;

      if (index >= 0 && index < 7) {
        weeklyCounts[index] = (row["count"] as num).toInt();
      }
    }

    if (mounted) setState(() {});
  }

  double get maxY {
    final highest = weeklyCounts.reduce((a, b) => a > b ? a : b);
    return highest < 4 ? 4 : highest.toDouble() + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Workouts",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          "Mon",
                          "Tue",
                          "Wed",
                          "Thu",
                          "Fri",
                          "Sat",
                          "Sun"
                        ];

                        if (value.toInt() < 0 || value.toInt() > 6) {
                          return const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  7,
                      (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weeklyCounts[i].toDouble(),
                        width: 22,
                        borderRadius: BorderRadius.circular(8),
                        color: weeklyCounts[i] == 0
                            ? Colors.grey.withOpacity(0.3)
                            : Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}