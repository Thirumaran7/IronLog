import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../widgets/nutrition_micronutrients_panel.dart';
import '../widgets/nutrition_goals_panel.dart';
import '../database/database_service.dart';
import '../services/nutrition_ai_service.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final TextEditingController controller = TextEditingController();
  final NutritionAIService ai = NutritionAIService();
  final DatabaseService db = DatabaseService.instance;

  late final stt.SpeechToText speech;

  bool isListening = false;
  bool isAnalyzing = false;
  bool isSavingMeal = false;
  bool loadingMeals = true;

  String selectedMealType = 'Meal';

  NutritionResult? result;
  List<Map<String, dynamic>> todayMeals = [];

  // Editable starter targets; persisted in SQLite by DatabaseService.
  Map<String, dynamic> nutritionGoals = {
    'calories': 2500.0,
    'protein': 150.0,
    'carbs': 300.0,
    'fat': 70.0,
    'fiber': 30.0,
  };

  Map<String, dynamic> dailyTotals = {
    'mealCount': 0,
    'calories': 0.0,
    'protein': 0.0,
    'carbs': 0.0,
    'fat': 0.0,
    'calcium': 0.0,
    'fiber': 0.0,
    'sodium': 0.0,
    'potassium': 0.0,
    'iron': 0.0,
    'magnesium': 0.0,
    'zinc': 0.0,
    'phosphorus': 0.0,
    'vitaminC': 0.0,
    'vitaminA': 0.0,
    'folate': 0.0,
    'vitaminE': 0.0,
    'vitaminB1': 0.0,
    'vitaminB2': 0.0,
    'vitaminB3': 0.0,
    'vitaminB6': 0.0,
  };

  static const List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Meal',
  ];

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    loadTodayMeals();
  }

  // --------------------------------------------
  // LOAD TODAY'S SAVED MEALS AND TOTALS
  // --------------------------------------------

  Future<void> loadTodayMeals() async {
    if (mounted) {
      setState(() => loadingMeals = true);
    }

    try {
      final today = DateTime.now();

      final meals = await db.getMealsForDate(today);
      final totals = await db.getDailyNutrition(today);
      final goals = await db.getNutritionGoals();

      if (!mounted) return;

      setState(() {
        todayMeals = meals;
        dailyTotals = totals;
        nutritionGoals = goals;
        loadingMeals = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => loadingMeals = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load meal history: $error'),
        ),
      );
    }
  }


  // --------------------------------------------
  // EDIT DAILY NUTRITION TARGETS
  // --------------------------------------------

  Future<void> editNutritionGoals() async {
    const fields = <String, String>{
      'calories': 'Calories (kcal)',
      'protein': 'Protein (g)',
      'carbs': 'Carbs (g)',
      'fat': 'Fat (g)',
      'fiber': 'Fiber (g)',
    };

    final controllers = <String, TextEditingController>{
      for (final entry in fields.entries)
        entry.key: TextEditingController(
          text: numberValue(nutritionGoals[entry.key]).toStringAsFixed(
            entry.key == 'calories' ? 0 : 1,
          ),
        ),
    };
    final formKey = GlobalKey<FormState>();

    try {
      final updatedGoals = await showDialog<Map<String, double>>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Edit daily goals'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: fields.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: controllers[entry.key],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: entry.value,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (raw) {
                            final value = double.tryParse(raw?.trim() ?? '');
                            if (value == null ||
                                !value.isFinite ||
                                value <= 0) {
                              return 'Enter a number greater than zero';
                            }
                            if (entry.key == 'calories' && value > 20000) {
                              return 'Enter a realistic daily target';
                            }
                            if (entry.key != 'calories' && value > 2000) {
                              return 'Enter a realistic daily target';
                            }
                            return null;
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  Navigator.pop(
                    dialogContext,
                    {
                      for (final entry in controllers.entries)
                        entry.key: double.parse(entry.value.text.trim()),
                    },
                  );
                },
                child: const Text('Save goals'),
              ),
            ],
          );
        },
      );

      if (updatedGoals == null) return;

      await db.updateNutritionGoals(
        calories: updatedGoals['calories']!,
        protein: updatedGoals['protein']!,
        carbs: updatedGoals['carbs']!,
        fat: updatedGoals['fat']!,
        fiber: updatedGoals['fiber']!,
      );

      if (!mounted) return;
      setState(() => nutritionGoals = updatedGoals);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily goals updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update daily goals: $error')),
      );
    } finally {
      for (final textController in controllers.values) {
        textController.dispose();
      }
    }
  }

  // --------------------------------------------
  // ANALYZE A MEAL USING THE OFFLINE CALCULATOR
  // --------------------------------------------

  Future<void> analyzeMeal() async {
    final input = controller.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a food or meal first.'),
        ),
      );
      return;
    }

    setState(() {
      isAnalyzing = true;
      result = null;
    });

    try {
      final nutrition = await ai.analyze(input);

      if (!mounted) return;

      setState(() {
        result = nutrition;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not analyze this meal: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isAnalyzing = false);
      }
    }
  }

  // --------------------------------------------
  // SAVE THE ANALYZED MEAL TO SQLITE
  // --------------------------------------------

  Future<void> saveMeal() async {
    final nutrition = result;
    final foodText = controller.text.trim();

    if (nutrition == null || foodText.isEmpty || isSavingMeal) {
      return;
    }

    setState(() => isSavingMeal = true);

    try {
      await db.insertMealLog(
        foodText: foodText,
        mealType: selectedMealType,
        calories: nutrition.calories,
        protein: nutrition.protein,
        carbs: nutrition.carbs,
        fat: nutrition.fat,
        calcium: nutrition.calcium,
        fiber: nutrition.fiber,
        sodium: nutrition.sodium,
        potassium: nutrition.potassium,
        iron: nutrition.iron,
        magnesium: nutrition.magnesium,
        zinc: nutrition.zinc,
        phosphorus: nutrition.phosphorus,
        vitaminC: nutrition.vitaminC,
        vitaminA: nutrition.vitaminA,
        folate: nutrition.folate,
        vitaminE: nutrition.vitaminE,
        vitaminB1: nutrition.vitaminB1,
        vitaminB2: nutrition.vitaminB2,
        vitaminB3: nutrition.vitaminB3,
        vitaminB6: nutrition.vitaminB6,
        detectedFoods: nutrition.detectedFoods,
      );

      if (!mounted) return;

      setState(() {
        result = null;
        controller.clear();
        selectedMealType = 'Meal';
      });

      await loadTodayMeals();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal saved successfully!'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save meal: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSavingMeal = false);
      }
    }
  }

  // --------------------------------------------
  // DELETE A SAVED MEAL
  // --------------------------------------------

  Future<void> deleteMeal(Map<String, dynamic> meal) async {
    final id = (meal['id'] as num?)?.toInt();

    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete meal?'),
          content: const Text(
            'This meal will be removed from your daily nutrition totals.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await db.deleteMealLog(id);
      await loadTodayMeals();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal deleted.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete meal: $error')),
      );
    }
  }

  // --------------------------------------------
  // VOICE INPUT
  // --------------------------------------------

  Future<void> toggleListening() async {
    if (isListening) {
      await speech.stop();

      if (mounted) {
        setState(() => isListening = false);
      }

      return;
    }

    try {
      final available = await speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' && mounted) {
            setState(() => isListening = false);
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() => isListening = false);
          }
        },
      );

      if (!mounted) return;

      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition is unavailable on this device.',
            ),
          ),
        );
        return;
      }

      setState(() => isListening = true);

      await speech.listen(
        onResult: (speechResult) {
          if (!mounted) return;

          setState(() {
            controller.text = speechResult.recognizedWords;
            controller.selection = TextSelection.collapsed(
              offset: controller.text.length,
            );

            // New text invalidates previously calculated results.
            result = null;
          });
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => isListening = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice input failed: $error'),
        ),
      );
    }
  }

  @override
  void dispose() {
    speech.stop();
    controller.dispose();
    super.dispose();
  }

  // --------------------------------------------
  // FORMAT HELPERS
  // --------------------------------------------

  double numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String formatNumber(dynamic value) {
    return numberValue(value).toStringAsFixed(0);
  }

  String get todayLabel {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String mealTime(dynamic value) {
    if (value is! String) return '';

    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // --------------------------------------------
  // REUSABLE MACRO CARD
  // --------------------------------------------

  Widget macroCard({
    required String title,
    required double value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------
  // DAILY TOTAL CARD
  // --------------------------------------------

  Widget dailyMacroRow({
    required String title,
    required double value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------
  // SAVED MEAL CARD
  // --------------------------------------------

  Widget mealCard(Map<String, dynamic> meal) {
    final calories = numberValue(meal['calories']);
    final protein = numberValue(meal['protein']);
    final carbs = numberValue(meal['carbs']);
    final fat = numberValue(meal['fat']);

    final category = meal['mealType']?.toString() ?? 'Meal';
    final time = mealTime(meal['date']);
    final foodText = meal['foodText']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  time,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Delete meal',
                visualDensity: VisualDensity.compact,
                onPressed: () => deleteMeal(meal),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            foodText,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${calories.toStringAsFixed(0)} kcal',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 13,
            runSpacing: 6,
            children: [
              Text(
                'P ${protein.toStringAsFixed(1)} g',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                ),
              ),
              Text(
                'C ${carbs.toStringAsFixed(1)} g',
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 12,
                ),
              ),
              Text(
                'F ${fat.toStringAsFixed(1)} g',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------
  // SCREEN
  // --------------------------------------------

  @override
  Widget build(BuildContext context) {
    final calories = numberValue(dailyTotals['calories']);
    final protein = numberValue(dailyTotals['protein']);
    final carbs = numberValue(dailyTotals['carbs']);
    final fat = numberValue(dailyTotals['fat']);
    final calcium = numberValue(dailyTotals['calcium']);

    final mealCount =
        (dailyTotals['mealCount'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nutrition Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh daily totals',
            onPressed: loadTodayMeals,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadTodayMeals,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            // TODAY'S SUMMARY
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D21),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: Colors.greenAccent,
                        size: 27,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Today's Nutrition",
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$todayLabel • $mealCount saved meals',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 23),
                  const Text(
                    'CALORIES CONSUMED',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        calories.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 39,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(
                          left: 8,
                          bottom: 7,
                        ),
                        child: Text(
                          'kcal',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  dailyMacroRow(
                    title: 'Protein',
                    value: protein,
                    unit: 'g',
                    color: Colors.greenAccent,
                    icon: Icons.fitness_center,
                  ),
                  const SizedBox(height: 9),
                  dailyMacroRow(
                    title: 'Carbs',
                    value: carbs,
                    unit: 'g',
                    color: Colors.lightBlueAccent,
                    icon: Icons.bolt,
                  ),
                  const SizedBox(height: 9),
                  dailyMacroRow(
                    title: 'Fat',
                    value: fat,
                    unit: 'g',
                    color: Colors.redAccent,
                    icon: Icons.opacity,
                  ),
                  const SizedBox(height: 9),
                  dailyMacroRow(
                    title: 'Calcium',
                    value: calcium,
                    unit: 'mg',
                    color: Colors.orange,
                    icon: Icons.health_and_safety,
                  ),
                ],
              ),
            ),

            // Daily intake compared with the user's editable targets.
            NutritionGoalsPanel(
              totals: dailyTotals,
              goals: nutritionGoals,
              onEdit: editNutritionGoals,
            ),

            // Total fiber and micronutrients accumulated from saved meals.
            DailyMicronutrientsPanel(totals: dailyTotals),

            const SizedBox(height: 27),

            // MEAL ENTRY
            const Text(
              'LOG A MEAL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D21),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedMealType,
                    decoration: const InputDecoration(
                      labelText: 'Meal category',
                      border: OutlineInputBorder(),
                    ),
                    items: mealTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedMealType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) {
                      // Rebuild on each edit so the clear button appears only
                      // when the input contains text, and stale results vanish.
                      setState(() {
                        if (result != null) result = null;
                      });
                    },
                    decoration: InputDecoration(
                      hintText:
                      'Example:\n'
                          '3 eggs\n'
                          '200g chicken breast\n'
                          '150g cooked rice\n'
                          '1 banana',
                      filled: true,
                      fillColor: const Color(0xFF101114),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.text.trim().isNotEmpty)
                            IconButton(
                              tooltip: 'Clear entered foods',
                              onPressed: () async {
                                // Stop active speech first so an interim speech
                                // callback cannot restore the cleared text.
                                if (isListening) {
                                  await speech.stop();
                                }
                                if (!mounted) return;
                                controller.clear();
                                setState(() {
                                  result = null;
                                  isListening = false;
                                });
                              },
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Colors.redAccent,
                              ),
                            ),
                          IconButton(
                            tooltip: isListening
                                ? 'Stop voice input'
                                : 'Speak your meal',
                            onPressed: toggleListening,
                            icon: Icon(
                              isListening ? Icons.mic : Icons.mic_none,
                              color: isListening
                                  ? Colors.redAccent
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isListening) ...[
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(
                          Icons.graphic_eq,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Listening...',
                          style: TextStyle(
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isAnalyzing ? null : analyzeMeal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      icon: isAnalyzing
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                          : const Icon(Icons.calculate),
                      label: Text(
                        isAnalyzing
                            ? 'Calculating...'
                            : 'Calculate Nutrition',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // CALCULATED MEAL RESULTS
            if (result != null) ...[
              const SizedBox(height: 24),
              const Text(
                'MEAL ESTIMATE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Review the estimated values before saving.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  macroCard(
                    title: 'Calories',
                    value: result!.calories,
                    unit: 'kcal',
                    color: Colors.orange,
                    icon: Icons.local_fire_department,
                  ),
                  macroCard(
                    title: 'Protein',
                    value: result!.protein,
                    unit: 'grams',
                    color: Colors.greenAccent,
                    icon: Icons.fitness_center,
                  ),
                  macroCard(
                    title: 'Carbs',
                    value: result!.carbs,
                    unit: 'grams',
                    color: Colors.lightBlueAccent,
                    icon: Icons.bolt,
                  ),
                  macroCard(
                    title: 'Fat',
                    value: result!.fat,
                    unit: 'grams',
                    color: Colors.redAccent,
                    icon: Icons.opacity,
                  ),
                ],
              ),

              // Fiber and micronutrient totals for the analyzed meal.
              NutritionMicronutrientsPanel(result: result!),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D21),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Foods identified',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...result!.detectedFoods.map(
                          (food) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.circle,
                              color: Colors.orange,
                              size: 8,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(food)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSavingMeal ? null : saveMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                  icon: isSavingMeal
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    isSavingMeal
                        ? 'Saving Meal...'
                        : 'Save Meal to Today',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Estimates depend on portions, ingredients and cooking methods.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            // TODAY'S SAVED MEALS
            const SizedBox(height: 30),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Today's Meals",
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh meals',
                  onPressed: loadTodayMeals,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (loadingMeals)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (todayMeals.isEmpty)
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D21),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.no_food_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No meals saved today yet.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Calculate a meal, review it and tap Save Meal.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...todayMeals.map(mealCard),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
