
class WorkoutSet {
  double weight;
  int reps;
  bool completed;

  WorkoutSet({
    this.weight = 0,
    this.reps = 0,
    this.completed = false,
  });

  double get volume => weight * reps;
}