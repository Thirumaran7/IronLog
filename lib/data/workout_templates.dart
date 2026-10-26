import '../models/exercise.dart';

final Map<String, List<Exercise>> workoutTemplates = {
  "Push": [
    Exercise(name: "Incline DB Press", targetSets: 3, targetReps: "8-12"),
    Exercise(name: "Chest Press", targetSets: 3, targetReps: "8-12"),
    Exercise(name: "Cable Fly", targetSets: 3, targetReps: "12-15"),
    Exercise(name: "Shoulder Press", targetSets: 3, targetReps: "8-12"),
    Exercise(name: "Cable Lateral Raise", targetSets: 3, targetReps: "12-15"),
    Exercise(name: "Triceps Pushdown", targetSets: 3, targetReps: "10-12"),
    Exercise(name: "Overhead Triceps Extension", targetSets: 3, targetReps: "10-12"),
  ],

  "Pull": [
    Exercise(name: "Lat Pulldown", targetSets: 3, targetReps: "10-12"),
    Exercise(name: "Chest Supported Row", targetSets: 3, targetReps: "8-12"),
    Exercise(name: "Seated Cable Row", targetSets: 3, targetReps: "10-12"),
    Exercise(name: "Straight Arm Pulldown", targetSets: 3, targetReps: "12-15"),
    Exercise(name: "Rear Delt Cable Fly", targetSets: 3, targetReps: "12-15"),
    Exercise(name: "Preacher Curl", targetSets: 3, targetReps: "10-12"),
    Exercise(name: "Hammer Curl", targetSets: 3, targetReps: "10-12"),
    Exercise(name: "EZ Bar Curl", targetSets: 3, targetReps: "8-10"),
  ],

  "Legs": [
    Exercise(name: "Squat", targetSets: 3, targetReps: "6-10"),
    Exercise(name: "Romanian Deadlift", targetSets: 3, targetReps: "8-10"),
    Exercise(name: "Leg Press", targetSets: 3, targetReps: "10-12"),
    Exercise(name: "Leg Extension", targetSets: 3, targetReps: "12-15"),
    Exercise(name: "Leg Curl", targetSets: 3, targetReps: "12-15"),
    Exercise(name: "Standing Calf Raise", targetSets: 4, targetReps: "12-20"),
  ],

  "Upper": [
    Exercise(name: "Incline DB Press", targetSets: 3, targetReps: "8-12"),
    Exercise(name: "Chest Press", targetSets: 3, targetReps: "8-12"),
    Exercise(name: "Lat Pulldown", targetSets: 3, targetReps: "10-12"),
    Exercise(name: "Seated Cable Row", targetSets: 3, targetReps: "10-12"),
    Exercise(name: "Cable Lateral Raise", targetSets: 3, targetReps: "12-15"),
    Exercise(name: "Preacher Curl", targetSets: 3, targetReps: "10-12"),
    Exercise(name: "Triceps Pushdown", targetSets: 3, targetReps: "10-12"),
  ],

  "Lower": [
    Exercise(name: "Front Squat", targetSets: 3, targetReps: "6-10"),
    Exercise(name: "Romanian Deadlift", targetSets: 3, targetReps: "8-10"),
    Exercise(name: "Bulgarian Split Squat", targetSets: 3, targetReps: "10-12"),
    Exercise(name: "Leg Curl", targetSets: 3, targetReps: "12-15"),
    Exercise(name: "Seated Calf Raise", targetSets: 4, targetReps: "12-20"),
  ],
};