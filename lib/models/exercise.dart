
import 'workout_set.dart';

class Exercise {
  final String name;
  final int targetSets;
  final String targetReps;
  final List<WorkoutSet> sets;

  Exercise({
    required this.name,
    required this.targetSets,
    required this.targetReps,
  }) : sets = List.generate(
    targetSets,
        (_) => WorkoutSet(),
  );

  double get totalVolume {
    return sets.fold(
      0,
          (total, set) => total + set.volume,
    );
  }
}