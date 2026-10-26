import 'package:flutter/material.dart';

/// Shows today's logged intake against the user's editable daily goals.
/// Default values are starter targets, not individualized medical advice.
class NutritionGoalsPanel extends StatelessWidget {
  const NutritionGoalsPanel({
    super.key,
    required this.totals,
    required this.goals,
    required this.onEdit,
  });

  final Map<String, dynamic> totals;
  final Map<String, dynamic> goals;
  final VoidCallback onEdit;

  double _number(Map<String, dynamic> values, String key) {
    final value = values[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final items = <_GoalItem>[
      _GoalItem('Calories', 'calories', 'kcal', Icons.local_fire_department,
          Colors.orange),
      _GoalItem('Protein', 'protein', 'g', Icons.fitness_center,
          Colors.greenAccent),
      _GoalItem('Carbs', 'carbs', 'g', Icons.bolt, Colors.lightBlueAccent),
      _GoalItem('Fat', 'fat', 'g', Icons.opacity, Colors.redAccent),
      _GoalItem('Fiber', 'fiber', 'g', Icons.grass, Colors.tealAccent),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DAILY GOALS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.tune, size: 17),
                label: const Text('Edit goals'),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Starter targets are editable. Intake depends on the foods and nutrition data logged.',
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 18),
          ...items.map((item) {
            final current = _number(totals, item.key);
            final target = _number(goals, item.key);
            final safeTarget = target > 0 ? target : 1.0;
            final progress = (current / safeTarget).clamp(0.0, 1.0).toDouble();
            final difference = (target - current).abs();
            final over = current > target;
            final unitText = item.unit;
            final currentText = item.key == 'calories'
                ? current.toStringAsFixed(0)
                : current.toStringAsFixed(1);
            final targetText = item.key == 'calories'
                ? target.toStringAsFixed(0)
                : target.toStringAsFixed(1);
            final differenceText = item.key == 'calories'
                ? difference.toStringAsFixed(0)
                : difference.toStringAsFixed(1);

            return Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(item.icon, color: item.color, size: 19),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '$currentText / $targetText $unitText',
                        style: TextStyle(
                          color: item.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF101114),
                      valueColor: AlwaysStoppedAnimation<Color>(item.color),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      over
                          ? '$differenceText $unitText over target'
                          : '$differenceText $unitText remaining',
                      style: TextStyle(
                        color: over ? Colors.orangeAccent : Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GoalItem {
  const _GoalItem(this.label, this.key, this.unit, this.icon, this.color);

  final String label;
  final String key;
  final String unit;
  final IconData icon;
  final Color color;
}
