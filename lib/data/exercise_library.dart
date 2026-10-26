class ExerciseInfo {
  final String name;
  final String muscle;
  final List<String> secondaryMuscles;
  final String equipment;
  final String difficulty;
  final int targetSets;
  final String targetReps;

  const ExerciseInfo({
    required this.name,
    required this.muscle,
    this.secondaryMuscles = const [],
    required this.equipment,
    this.difficulty = 'Intermediate',
    this.targetSets = 3,
    this.targetReps = '8-12',
  });
}

class ExerciseLibrary {
  static const List<String> muscles = [
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Forearms',
    'Traps',
    'Quads',
    'Hamstrings',
    'Glutes',
    'Calves',
    'Abs',
  ];

  static const List<ExerciseInfo> all = [
    // =====================================================
    // CHEST
    // =====================================================
    ExerciseInfo(
      name: 'Barbell Bench Press',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Shoulders'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Incline Barbell Bench Press',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Shoulders'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Decline Barbell Bench Press',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Dumbbell Bench Press',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Shoulders'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Incline Dumbbell Press',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Shoulders'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Decline Dumbbell Press',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Dumbbell Chest Fly',
      muscle: 'Chest',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Incline Dumbbell Fly',
      muscle: 'Chest',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Pec Deck Fly',
      muscle: 'Chest',
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Cable Chest Fly',
      muscle: 'Chest',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'High-to-Low Cable Fly',
      muscle: 'Chest',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Low-to-High Cable Fly',
      muscle: 'Chest',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Chest Press Machine',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Shoulders'],
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Incline Chest Press Machine',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Shoulders'],
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Smith Machine Bench Press',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps'],
      equipment: 'Smith Machine',
    ),
    ExerciseInfo(
      name: 'Push-Up',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Shoulders'],
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
    ),
    ExerciseInfo(
      name: 'Decline Push-Up',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Shoulders'],
      equipment: 'Bodyweight',
    ),
    ExerciseInfo(
      name: 'Weighted Push-Up',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Shoulders'],
      equipment: 'Bodyweight',
    ),
    ExerciseInfo(
      name: 'Chest-Focused Dips',
      muscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Shoulders'],
      equipment: 'Bodyweight',
    ),

    // =====================================================
    // BACK
    // =====================================================
    ExerciseInfo(
      name: 'Pull-Up',
      muscle: 'Back',
      secondaryMuscles: ['Biceps', 'Forearms'],
      equipment: 'Pull-Up Bar',
    ),
    ExerciseInfo(
      name: 'Assisted Pull-Up',
      muscle: 'Back',
      secondaryMuscles: ['Biceps'],
      equipment: 'Machine',
      difficulty: 'Beginner',
    ),
    ExerciseInfo(
      name: 'Lat Pulldown',
      muscle: 'Back',
      secondaryMuscles: ['Biceps'],
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Close-Grip Lat Pulldown',
      muscle: 'Back',
      secondaryMuscles: ['Biceps'],
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Neutral-Grip Lat Pulldown',
      muscle: 'Back',
      secondaryMuscles: ['Biceps'],
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Single-Arm Lat Pulldown',
      muscle: 'Back',
      secondaryMuscles: ['Biceps'],
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Barbell Bent-Over Row',
      muscle: 'Back',
      secondaryMuscles: ['Biceps', 'Traps'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Pendlay Row',
      muscle: 'Back',
      secondaryMuscles: ['Biceps', 'Traps'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'T-Bar Row',
      muscle: 'Back',
      secondaryMuscles: ['Biceps', 'Traps'],
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Chest-Supported Row',
      muscle: 'Back',
      secondaryMuscles: ['Biceps', 'Traps'],
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Seated Cable Row',
      muscle: 'Back',
      secondaryMuscles: ['Biceps', 'Traps'],
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'V-Grip Cable Row',
      muscle: 'Back',
      secondaryMuscles: ['Biceps'],
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Single-Arm Dumbbell Row',
      muscle: 'Back',
      secondaryMuscles: ['Biceps'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Meadows Row',
      muscle: 'Back',
      secondaryMuscles: ['Biceps'],
      equipment: 'Landmine',
    ),
    ExerciseInfo(
      name: 'Straight-Arm Pulldown',
      muscle: 'Back',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Machine High Row',
      muscle: 'Back',
      secondaryMuscles: ['Biceps', 'Traps'],
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Inverted Row',
      muscle: 'Back',
      secondaryMuscles: ['Biceps'],
      equipment: 'Bodyweight',
    ),
    ExerciseInfo(
      name: 'Machine Pullover',
      muscle: 'Back',
      equipment: 'Machine',
    ),

    // =====================================================
    // SHOULDERS
    // =====================================================
    ExerciseInfo(
      name: 'Barbell Overhead Press',
      muscle: 'Shoulders',
      secondaryMuscles: ['Triceps'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Seated Dumbbell Shoulder Press',
      muscle: 'Shoulders',
      secondaryMuscles: ['Triceps'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Arnold Press',
      muscle: 'Shoulders',
      secondaryMuscles: ['Triceps'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Machine Shoulder Press',
      muscle: 'Shoulders',
      secondaryMuscles: ['Triceps'],
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Dumbbell Lateral Raise',
      muscle: 'Shoulders',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Cable Lateral Raise',
      muscle: 'Shoulders',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Machine Lateral Raise',
      muscle: 'Shoulders',
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Dumbbell Front Raise',
      muscle: 'Shoulders',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Plate Front Raise',
      muscle: 'Shoulders',
      equipment: 'Plate',
    ),
    ExerciseInfo(
      name: 'Dumbbell Rear Delt Fly',
      muscle: 'Shoulders',
      secondaryMuscles: ['Back'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Reverse Pec Deck',
      muscle: 'Shoulders',
      secondaryMuscles: ['Back'],
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Cable Rear Delt Fly',
      muscle: 'Shoulders',
      secondaryMuscles: ['Back'],
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Face Pull',
      muscle: 'Shoulders',
      secondaryMuscles: ['Back', 'Traps'],
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Upright Row',
      muscle: 'Shoulders',
      secondaryMuscles: ['Traps'],
      equipment: 'Barbell',
    ),

    // =====================================================
    // BICEPS
    // =====================================================
    ExerciseInfo(
      name: 'Barbell Curl',
      muscle: 'Biceps',
      secondaryMuscles: ['Forearms'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'EZ-Bar Curl',
      muscle: 'Biceps',
      secondaryMuscles: ['Forearms'],
      equipment: 'EZ Bar',
    ),
    ExerciseInfo(
      name: 'Alternating Dumbbell Curl',
      muscle: 'Biceps',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Incline Dumbbell Curl',
      muscle: 'Biceps',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Bayesian Cable Curl',
      muscle: 'Biceps',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Preacher Curl',
      muscle: 'Biceps',
      equipment: 'EZ Bar',
    ),
    ExerciseInfo(
      name: 'Preacher Curl Machine',
      muscle: 'Biceps',
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Spider Curl',
      muscle: 'Biceps',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Concentration Curl',
      muscle: 'Biceps',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Hammer Curl',
      muscle: 'Biceps',
      secondaryMuscles: ['Forearms'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Cross-Body Hammer Curl',
      muscle: 'Biceps',
      secondaryMuscles: ['Forearms'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Cable Curl',
      muscle: 'Biceps',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'High Cable Curl',
      muscle: 'Biceps',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Reverse Curl',
      muscle: 'Biceps',
      secondaryMuscles: ['Forearms'],
      equipment: 'EZ Bar',
    ),

    // =====================================================
    // TRICEPS
    // =====================================================
    ExerciseInfo(
      name: 'Rope Triceps Pushdown',
      muscle: 'Triceps',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Straight-Bar Pushdown',
      muscle: 'Triceps',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Reverse-Grip Pushdown',
      muscle: 'Triceps',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Overhead Cable Extension',
      muscle: 'Triceps',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Single-Arm Overhead Extension',
      muscle: 'Triceps',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'EZ-Bar Skullcrusher',
      muscle: 'Triceps',
      equipment: 'EZ Bar',
    ),
    ExerciseInfo(
      name: 'Dumbbell Skullcrusher',
      muscle: 'Triceps',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Close-Grip Bench Press',
      muscle: 'Triceps',
      secondaryMuscles: ['Chest', 'Shoulders'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Triceps Dips',
      muscle: 'Triceps',
      secondaryMuscles: ['Chest', 'Shoulders'],
      equipment: 'Bodyweight',
    ),
    ExerciseInfo(
      name: 'Triceps Kickback',
      muscle: 'Triceps',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Diamond Push-Up',
      muscle: 'Triceps',
      secondaryMuscles: ['Chest', 'Shoulders'],
      equipment: 'Bodyweight',
    ),
    ExerciseInfo(
      name: 'Machine Triceps Extension',
      muscle: 'Triceps',
      equipment: 'Machine',
    ),

    // =====================================================
    // FOREARMS
    // =====================================================
    ExerciseInfo(
      name: 'Seated Wrist Curl',
      muscle: 'Forearms',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Reverse Wrist Curl',
      muscle: 'Forearms',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Behind-the-Back Wrist Curl',
      muscle: 'Forearms',
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Cable Wrist Curl',
      muscle: 'Forearms',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Farmer Carry',
      muscle: 'Forearms',
      secondaryMuscles: ['Traps'],
      equipment: 'Dumbbells',
      targetReps: '30-60 sec',
    ),
    ExerciseInfo(
      name: 'Dead Hang',
      muscle: 'Forearms',
      equipment: 'Pull-Up Bar',
      targetReps: '20-60 sec',
    ),

    // =====================================================
    // TRAPS
    // =====================================================
    ExerciseInfo(
      name: 'Dumbbell Shrug',
      muscle: 'Traps',
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Barbell Shrug',
      muscle: 'Traps',
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Smith Machine Shrug',
      muscle: 'Traps',
      equipment: 'Smith Machine',
    ),
    ExerciseInfo(
      name: 'Cable Shrug',
      muscle: 'Traps',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Trap Bar Carry',
      muscle: 'Traps',
      secondaryMuscles: ['Forearms'],
      equipment: 'Trap Bar',
      targetReps: '30-60 sec',
    ),

    // =====================================================
    // QUADS
    // =====================================================
    ExerciseInfo(
      name: 'Barbell Back Squat',
      muscle: 'Quads',
      secondaryMuscles: ['Glutes'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Front Squat',
      muscle: 'Quads',
      secondaryMuscles: ['Glutes'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Hack Squat',
      muscle: 'Quads',
      secondaryMuscles: ['Glutes'],
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Leg Press',
      muscle: 'Quads',
      secondaryMuscles: ['Glutes'],
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Bulgarian Split Squat',
      muscle: 'Quads',
      secondaryMuscles: ['Glutes'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Goblet Squat',
      muscle: 'Quads',
      secondaryMuscles: ['Glutes'],
      equipment: 'Dumbbells',
      difficulty: 'Beginner',
    ),
    ExerciseInfo(
      name: 'Smith Machine Squat',
      muscle: 'Quads',
      secondaryMuscles: ['Glutes'],
      equipment: 'Smith Machine',
    ),
    ExerciseInfo(
      name: 'Leg Extension',
      muscle: 'Quads',
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Walking Lunge',
      muscle: 'Quads',
      secondaryMuscles: ['Glutes'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Reverse Lunge',
      muscle: 'Quads',
      secondaryMuscles: ['Glutes'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Step-Up',
      muscle: 'Quads',
      secondaryMuscles: ['Glutes'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Sissy Squat',
      muscle: 'Quads',
      equipment: 'Bodyweight',
    ),

    // =====================================================
    // HAMSTRINGS
    // =====================================================
    ExerciseInfo(
      name: 'Romanian Deadlift',
      muscle: 'Hamstrings',
      secondaryMuscles: ['Glutes', 'Back'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Dumbbell Romanian Deadlift',
      muscle: 'Hamstrings',
      secondaryMuscles: ['Glutes'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Stiff-Leg Deadlift',
      muscle: 'Hamstrings',
      secondaryMuscles: ['Glutes', 'Back'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Seated Leg Curl',
      muscle: 'Hamstrings',
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Lying Leg Curl',
      muscle: 'Hamstrings',
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Standing Single-Leg Curl',
      muscle: 'Hamstrings',
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Nordic Hamstring Curl',
      muscle: 'Hamstrings',
      equipment: 'Bodyweight',
      difficulty: 'Advanced',
    ),
    ExerciseInfo(
      name: 'Good Morning',
      muscle: 'Hamstrings',
      secondaryMuscles: ['Glutes', 'Back'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Glute-Ham Raise',
      muscle: 'Hamstrings',
      secondaryMuscles: ['Glutes'],
      equipment: 'Machine',
    ),

    // =====================================================
    // GLUTES
    // =====================================================
    ExerciseInfo(
      name: 'Barbell Hip Thrust',
      muscle: 'Glutes',
      secondaryMuscles: ['Hamstrings'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Dumbbell Hip Thrust',
      muscle: 'Glutes',
      secondaryMuscles: ['Hamstrings'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Glute Bridge',
      muscle: 'Glutes',
      secondaryMuscles: ['Hamstrings'],
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
    ),
    ExerciseInfo(
      name: 'Cable Glute Kickback',
      muscle: 'Glutes',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: '45-Degree Back Extension',
      muscle: 'Glutes',
      secondaryMuscles: ['Hamstrings', 'Back'],
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Sumo Deadlift',
      muscle: 'Glutes',
      secondaryMuscles: ['Quads', 'Hamstrings'],
      equipment: 'Barbell',
    ),
    ExerciseInfo(
      name: 'Glute-Focused Bulgarian Split Squat',
      muscle: 'Glutes',
      secondaryMuscles: ['Quads'],
      equipment: 'Dumbbells',
    ),
    ExerciseInfo(
      name: 'Hip Abduction Machine',
      muscle: 'Glutes',
      equipment: 'Machine',
    ),

    // =====================================================
    // CALVES
    // =====================================================
    ExerciseInfo(
      name: 'Standing Calf Raise',
      muscle: 'Calves',
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Seated Calf Raise',
      muscle: 'Calves',
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Leg Press Calf Raise',
      muscle: 'Calves',
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Smith Machine Calf Raise',
      muscle: 'Calves',
      equipment: 'Smith Machine',
    ),
    ExerciseInfo(
      name: 'Donkey Calf Raise',
      muscle: 'Calves',
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Single-Leg Calf Raise',
      muscle: 'Calves',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
    ),

    // =====================================================
    // ABS
    // =====================================================
    ExerciseInfo(
      name: 'Cable Crunch',
      muscle: 'Abs',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Abdominal Crunch Machine',
      muscle: 'Abs',
      equipment: 'Machine',
    ),
    ExerciseInfo(
      name: 'Decline Sit-Up',
      muscle: 'Abs',
      equipment: 'Bench',
    ),
    ExerciseInfo(
      name: 'Reverse Crunch',
      muscle: 'Abs',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
    ),
    ExerciseInfo(
      name: 'Hanging Knee Raise',
      muscle: 'Abs',
      equipment: 'Pull-Up Bar',
    ),
    ExerciseInfo(
      name: 'Hanging Leg Raise',
      muscle: 'Abs',
      equipment: 'Pull-Up Bar',
    ),
    ExerciseInfo(
      name: 'Ab Wheel Rollout',
      muscle: 'Abs',
      equipment: 'Ab Wheel',
    ),
    ExerciseInfo(
      name: 'Plank',
      muscle: 'Abs',
      equipment: 'Bodyweight',
      targetReps: '30-60 sec',
      difficulty: 'Beginner',
    ),
    ExerciseInfo(
      name: 'Side Plank',
      muscle: 'Abs',
      equipment: 'Bodyweight',
      targetReps: '20-45 sec',
      difficulty: 'Beginner',
    ),
    ExerciseInfo(
      name: 'Bicycle Crunch',
      muscle: 'Abs',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
    ),
    ExerciseInfo(
      name: 'Dead Bug',
      muscle: 'Abs',
      equipment: 'Bodyweight',
      difficulty: 'Beginner',
    ),
    ExerciseInfo(
      name: 'Pallof Press',
      muscle: 'Abs',
      equipment: 'Cable',
    ),
    ExerciseInfo(
      name: 'Weighted Sit-Up',
      muscle: 'Abs',
      equipment: 'Plate',
    ),
  ];

  /// Returns exercises for a selected primary muscle.
  static List<ExerciseInfo> forMuscle(
      String muscle, {
        String query = '',
        String equipment = 'All',
        String difficulty = 'All',
      }) {
    final normalizedQuery = query.trim().toLowerCase();

    return all.where((exercise) {
      final matchesMuscle =
          exercise.muscle.toLowerCase() == muscle.toLowerCase();

      final matchesName = normalizedQuery.isEmpty ||
          exercise.name.toLowerCase().contains(normalizedQuery);

      final matchesEquipment = equipment == 'All' ||
          exercise.equipment == equipment;

      final matchesDifficulty = difficulty == 'All' ||
          exercise.difficulty == difficulty;

      return matchesMuscle &&
          matchesName &&
          matchesEquipment &&
          matchesDifficulty;
    }).toList();
  }

  /// Returns all exercises that use the selected equipment.
  static List<ExerciseInfo> forEquipment(String equipment) {
    if (equipment == 'All') return all;

    return all
        .where((exercise) => exercise.equipment == equipment)
        .toList();
  }

  /// Returns a list of available equipment names.
  static List<String> get equipmentTypes {
    return all.map((exercise) => exercise.equipment).toSet().toList()
      ..sort();
  }
}