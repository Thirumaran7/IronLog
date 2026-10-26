import 'package:flutter/material.dart';
import '../services/nutrition_ai_service.dart';

/// A reusable panel showing fiber and micronutrients calculated by
/// NutritionAIService. Values only appear when the result contains a positive
/// value, because some food records do not provide every micronutrient.
class NutritionMicronutrientsPanel extends StatelessWidget {
  const NutritionMicronutrientsPanel({
    super.key,
    required this.result,
  });

  final NutritionResult result;

  @override
  Widget build(BuildContext context) {
    final items = <_NutrientItem>[
      _NutrientItem('Fiber', result.fiber, 'g', Icons.grass),
      _NutrientItem('Calcium${result.incompleteNutrients.contains('calcium') ? '*' : ''}', result.calcium, 'mg', Icons.health_and_safety),
      _NutrientItem('Potassium${result.incompleteNutrients.contains('potassium') ? '*' : ''}', result.potassium, 'mg', Icons.bolt),
      _NutrientItem('Sodium${result.incompleteNutrients.contains('sodium') ? '*' : ''}', result.sodium, 'mg', Icons.water_drop),
      _NutrientItem('Iron${result.incompleteNutrients.contains('iron') ? '*' : ''}', result.iron, 'mg', Icons.bloodtype),
      _NutrientItem('Magnesium${result.incompleteNutrients.contains('magnesium') ? '*' : ''}', result.magnesium, 'mg', Icons.spa),
      _NutrientItem('Zinc${result.incompleteNutrients.contains('zinc') ? '*' : ''}', result.zinc, 'mg', Icons.shield),
      _NutrientItem('Phosphorus${result.incompleteNutrients.contains('phosphorus') ? '*' : ''}', result.phosphorus, 'mg', Icons.science),
      _NutrientItem('Vitamin C${result.incompleteNutrients.contains('vitaminC') ? '*' : ''}', result.vitaminC, 'mg', Icons.local_florist),
      _NutrientItem('Vitamin A${result.incompleteNutrients.contains('vitaminA') ? '*' : ''}', result.vitaminA, 'µg', Icons.visibility),
      _NutrientItem('Folate${result.incompleteNutrients.contains('folate') ? '*' : ''}', result.folate, 'µg', Icons.eco),
      _NutrientItem('Vitamin E${result.incompleteNutrients.contains('vitaminE') ? '*' : ''}', result.vitaminE, 'mg', Icons.spa_outlined),
      _NutrientItem('Vitamin B1${result.incompleteNutrients.contains('vitaminB1') ? '*' : ''}', result.vitaminB1, 'mg', Icons.bubble_chart),
      _NutrientItem('Vitamin B2${result.incompleteNutrients.contains('vitaminB2') ? '*' : ''}', result.vitaminB2, 'mg', Icons.bubble_chart),
      _NutrientItem('Vitamin B3${result.incompleteNutrients.contains('vitaminB3') ? '*' : ''}', result.vitaminB3, 'mg', Icons.bubble_chart),
      _NutrientItem('Vitamin B6${result.incompleteNutrients.contains('vitaminB6') ? '*' : ''}', result.vitaminB6, 'mg', Icons.bubble_chart),
    ].where((item) => item.value > 0).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FIBER & MICRONUTRIENTS',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'An asterisk (*) and ~ mean the total is partial because at least one food lacks that nutrient value.',
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF101114),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.label.endsWith('*') ? '~' : ''}${_format(item.value)} ${item.unit}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _format(double value) {
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}

/// Displays the sum of fiber and micronutrients from meals saved today.
/// Calcium remains in the main daily summary to avoid displaying it twice.
class DailyMicronutrientsPanel extends StatelessWidget {
  const DailyMicronutrientsPanel({
    super.key,
    required this.totals,
  });

  final Map<String, dynamic> totals;

  double _number(String key) {
    final value = totals[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final items = <_NutrientItem>[
      _NutrientItem('Fiber', _number('fiber'), 'g', Icons.grass),
      _NutrientItem('Potassium', _number('potassium'), 'mg', Icons.bolt),
      _NutrientItem('Sodium', _number('sodium'), 'mg', Icons.water_drop),
      _NutrientItem('Iron', _number('iron'), 'mg', Icons.bloodtype),
      _NutrientItem('Magnesium', _number('magnesium'), 'mg', Icons.spa),
      _NutrientItem('Zinc', _number('zinc'), 'mg', Icons.shield),
      _NutrientItem('Phosphorus', _number('phosphorus'), 'mg', Icons.science),
      _NutrientItem('Vitamin C', _number('vitaminC'), 'mg', Icons.local_florist),
      _NutrientItem('Vitamin A', _number('vitaminA'), 'µg', Icons.visibility),
      _NutrientItem('Folate', _number('folate'), 'µg', Icons.eco),
      _NutrientItem('Vitamin E', _number('vitaminE'), 'mg', Icons.spa_outlined),
      _NutrientItem('Vitamin B1', _number('vitaminB1'), 'mg', Icons.bubble_chart),
      _NutrientItem('Vitamin B2', _number('vitaminB2'), 'mg', Icons.bubble_chart),
      _NutrientItem('Vitamin B3', _number('vitaminB3'), 'mg', Icons.bubble_chart),
      _NutrientItem('Vitamin B6', _number('vitaminB6'), 'mg', Icons.bubble_chart),
    ].where((item) => item.value > 0).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TODAY\'S FIBER & MICRONUTRIENTS',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Totals from saved meals. Nutrients not provided by a food record are not included.',
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF101114),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_format(item.value)} ${item.unit}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _format(double value) {
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _NutrientItem {
  const _NutrientItem(this.label, this.value, this.unit, this.icon);
  final String label;
  final double value;
  final String unit;
  final IconData icon;
}
