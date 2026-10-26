
import 'exercise.dart';

class Workout {
  final String split;
  final DateTime date;
  final List<Exercise> exercises;

  Workout({
    required this.split,
    required this.date,
    required this.exercises,
  });

  double get totalVolume {
    return exercises.fold(
      0,
          (total, exercise) => total + exercise.totalVolume,
    );
  }
}