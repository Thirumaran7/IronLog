
import 'package:flutter/material.dart';

import '../widgets/rest_timer.dart';
import '../database/database_service.dart';
import '../data/workout_templates.dart';
import '../data/exercise_library.dart';
import '../widgets/exercise_set_card.dart';
import 'workout_summary_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final String split;
  final List<ExerciseInfo>? selectedExercises;

  // The cycle selected before starting this workout.
  final int? cycleId;

  const WorkoutSessionScreen({
    super.key,
    required this.split,
    this.selectedExercises,
    this.cycleId,
  });

  @override
  State<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final Map<String, List<Map<String, dynamic>>> workoutData = {};

  bool saving = false;
  bool isRestTimerOpen = false;

  void startRestTimerAfterSet() {
    if (isRestTimerOpen || !mounted) return;

    isRestTimerOpen = true;

    showDialog<void>(
      context: context,
      builder: (_) => const RestTimerDialog(
        autoStart: true,
      ),
    ).whenComplete(() {
      isRestTimerOpen = false;
    });
  }

  Future<void> finishWorkout() async {
    if (saving) return;

    final completedSets = workoutData.values
        .expand((sets) => sets)
        .where((set) => set['completed'] == true)
        .toList();

    if (completedSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete at least one set before finishing.',
          ),
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final db = DatabaseService.instance;

      // Create the workout without changing older workout records.
      final workoutId = await db.insertWorkout(widget.split);

      // Assign this session to the cycle selected on the
      // Workout screen. Use the active cycle for older routes
      // that don't pass a cycleId.
      final selectedCycleId = widget.cycleId ??
          ((await db.getActiveTrainingCycle())['id'] as num).toInt();

      await db.assignWorkoutToCycle(
        workoutId: workoutId,
        cycleId: selectedCycleId,
      );

      double totalVolume = 0;
      final Set<String> newPRExercises = {};

      for (final entry in workoutData.entries) {
        for (final set in entry.value) {
          final exerciseName =
          (set['exercise'] ?? entry.key).toString();

          final weight =
              (set['weight'] as num?)?.toDouble() ?? 0.0;

          final amount =
              (set['reps'] as num?)?.toInt() ?? 0;

          final setNumber =
              (set['setNumber'] as num?)?.toInt() ?? 1;

          final completed = set['completed'] == true;

          final isTimed = set['isTimed'] == true;
          final isBodyweight = set['isBodyweight'] == true;

          final recordType = isTimed
              ? 'duration_seconds'
              : isBodyweight
              ? 'bodyweight_reps'
              : 'load_reps';

          await db.insertExerciseSet(
            workoutId: workoutId,
            exercise: exerciseName,
            setNumber: setNumber,
            weight: weight,
            reps: amount,
            completed: completed,
            recordType: recordType,
          );

          if (!completed || amount <= 0) continue;

          // Only weighted movements contribute to kg × reps volume.
          if (recordType == 'load_reps' && weight > 0) {
            totalVolume += weight * amount;
          }

          final currentPR = await db.getPR(exerciseName);

          final previousType =
              currentPR?['recordType']?.toString() ?? 'load_reps';

          final previousWeight =
              (currentPR?['weight'] as num?)?.toDouble() ?? 0.0;

          final previousAmount =
              (currentPR?['reps'] as num?)?.toInt() ?? 0;

          if (currentPR == null) {
            await db.savePR(
              exercise: exerciseName,
              weight: weight,
              reps: amount,
              recordType: recordType,
            );

            newPRExercises.add(exerciseName);
            continue;
          }

          // Different measurement types cannot be compared fairly.
          if (previousType != recordType) {
            await db.savePR(
              exercise: exerciseName,
              weight: weight,
              reps: amount,
              recordType: recordType,
            );
            continue;
          }

          final improved = switch (recordType) {
            'duration_seconds' || 'bodyweight_reps' =>
            amount > previousAmount,
            _ =>
            weight > previousWeight ||
                (weight == previousWeight &&
                    amount > previousAmount),
          };

          if (improved) {
            await db.savePR(
              exercise: exerciseName,
              weight: weight,
              reps: amount,
              recordType: recordType,
            );

            newPRExercises.add(exerciseName);
          }
        }
      }

      final workoutCount = await db.getWorkoutCount();

      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutSummaryScreen(
            split: widget.split,
            volume: totalVolume,
            prs: newPRExercises.length,
            workouts: workoutCount,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save workout: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> exercisesToShow =
        widget.selectedExercises ??
            (workoutTemplates[widget.split] ?? <dynamic>[]);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.split} Workout'),
        actions: const [
          RestTimerButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D21),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0x33FF9800),
                  child: Icon(
                    Icons.fitness_center,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.split} Workout',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exercisesToShow.length} exercises',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (exercisesToShow.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No exercises selected.'),
              ),
            ),

          ...exercisesToShow.map(
                (exercise) => ExerciseSetCard(
              exerciseName: exercise.name,
              sets: exercise.targetSets,
              repRange: exercise.targetReps,
              onChanged: (sets) {
                workoutData[exercise.name] = sets;
              },
              onSetCompleted: startRestTimerAfterSet,
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: saving ? null : finishWorkout,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.black,
        icon: saving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.black,
          ),
        )
            : const Icon(Icons.check),
        label: Text(
          saving ? 'Saving Workout...' : 'Finish Workout',
        ),
      ),
    );
  }
}
