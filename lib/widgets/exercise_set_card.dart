
import 'package:flutter/material.dart';

import '../data/exercise_library.dart';

class ExerciseSetCard extends StatefulWidget {
  final String exerciseName;
  final int sets;
  final String repRange;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  // Starts the rest timer when a set is marked complete.
  final VoidCallback? onSetCompleted;

  const ExerciseSetCard({
    super.key,
    required this.exerciseName,
    required this.sets,
    required this.repRange,
    required this.onChanged,
    this.onSetCompleted,
  });

  @override
  State<ExerciseSetCard> createState() => _ExerciseSetCardState();
}

class _ExerciseSetCardState extends State<ExerciseSetCard> {
  final List<_ExerciseSetEntry> entries = [];

  late bool isTimed;
  late bool isBodyweight;
  late bool requiresWeight;

  int get targetAmount {
    final match = RegExp(r'\d+').firstMatch(widget.repRange);

    return match == null
        ? 8
        : int.tryParse(match.group(0)!) ?? 8;
  }

  @override
  void initState() {
    super.initState();

    final lowerName = widget.exerciseName.toLowerCase();
    final range = widget.repRange.toLowerCase();

    isTimed = range.contains('sec') || range.contains('second');

    ExerciseInfo? info;

    for (final exercise in ExerciseLibrary.all) {
      if (exercise.name == widget.exerciseName) {
        info = exercise;
        break;
      }
    }

    final equipment = info?.equipment ?? '';

    final isBodyweightEquipment = [
      'Bodyweight',
      'Pull-Up Bar',
    ].contains(equipment);

    final isWeightedVariation = lowerName.contains('weighted');

    isBodyweight = isBodyweightEquipment && !isWeightedVariation;

    // Weighted exercises need a load field.
    // Bodyweight exercises track reps or time without requiring kg.
    requiresWeight = !isBodyweight;

    final initialSets = widget.sets < 1 ? 1 : widget.sets;

    for (int i = 1; i <= initialSets; i++) {
      entries.add(
        _ExerciseSetEntry(
          setNumber: i,
          initialAmount: targetAmount,
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _notifyParent();
      }
    });
  }

  List<Map<String, dynamic>> get setData {
    return entries.map((entry) {
      final weight = requiresWeight
          ? double.tryParse(entry.weightController.text.trim()) ?? 0
          : 0.0;

      final amount =
          int.tryParse(entry.amountController.text.trim()) ?? 0;

      return <String, dynamic>{
        'exercise': widget.exerciseName,
        'setNumber': entry.setNumber,
        'weight': weight,

        // Timed exercise duration is stored in the reps field.
        'reps': amount,
        'completed': entry.completed,
        'isTimed': isTimed,
        'isBodyweight': isBodyweight,
      };
    }).toList();
  }

  void _notifyParent() {
    widget.onChanged(setData);
  }

  void _addSet() {
    setState(() {
      entries.add(
        _ExerciseSetEntry(
          setNumber: entries.length + 1,
          initialAmount: targetAmount,
        ),
      );
    });

    _notifyParent();
  }

  void _removeSet() {
    if (entries.length <= 1) return;

    setState(() {
      entries.removeLast();
    });

    _notifyParent();
  }

  @override
  void dispose() {
    for (final entry in entries) {
      entry.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = isTimed
        ? 'Timed'
        : isBodyweight
        ? 'Bodyweight'
        : 'Weighted';

    return Card(
      color: const Color(0xFF1A1D21),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0x33FF9800),
                  child: Icon(
                    Icons.fitness_center,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.exerciseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$typeLabel • ${widget.repRange}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Column headings.
            Row(
              children: [
                const SizedBox(
                  width: 42,
                  child: Text(
                    'Set',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                if (requiresWeight) ...[
                  const Expanded(
                    child: Text(
                      'Weight (kg)',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    isTimed ? 'Seconds' : 'Reps',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 48,
                  child: Text(
                    'Done',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ...entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${entry.setNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    if (requiresWeight) ...[
                      Expanded(
                        child: TextField(
                          controller: entry.weightController,
                          keyboardType:
                          const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => _notifyParent(),
                          decoration: const InputDecoration(
                            hintText: '0',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    Expanded(
                      child: TextField(
                        controller: entry.amountController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _notifyParent(),
                        decoration: InputDecoration(
                          hintText: isTimed ? '30' : '8',
                          isDense: true,
                          contentPadding:
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    SizedBox(
                      width: 48,
                      child: Checkbox(
                        value: entry.completed,
                        activeColor: Colors.orange,
                        checkColor: Colors.black,
                        onChanged: (value) {
                          final isCompleted = value ?? false;

                          setState(() {
                            entry.completed = isCompleted;
                          });

                          // Update the session's set data.
                          _notifyParent();

                          // Start rest only when checking the set,
                          // not when unchecking it.
                          if (isCompleted) {
                            widget.onSetCompleted?.call();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 24),

            Row(
              children: [
                Expanded(
                  child: Text(
                    isTimed
                        ? 'Record the duration in seconds.'
                        : isBodyweight
                        ? 'No weight entry required.'
                        : 'Enter the load used for each set.',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove last set',
                  onPressed:
                  entries.length > 1 ? _removeSet : null,
                  icon: const Icon(
                    Icons.remove_circle_outline,
                  ),
                ),
                IconButton(
                  tooltip: 'Add set',
                  onPressed: _addSet,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseSetEntry {
  final int setNumber;
  final TextEditingController weightController;
  final TextEditingController amountController;

  bool completed = false;

  _ExerciseSetEntry({
    required this.setNumber,
    required int initialAmount,
  })  : weightController = TextEditingController(),
        amountController = TextEditingController(
          text: '$initialAmount',
        );

  void dispose() {
    weightController.dispose();
    amountController.dispose();
  }
}
