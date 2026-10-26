
import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../data/exercise_library.dart';
import 'workout_session_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final TextEditingController searchController =
  TextEditingController();

  String selectedMuscle = 'Chest';
  String selectedEquipment = 'All';
  String selectedDifficulty = 'All';

  final List<String> selectedExerciseNames = [];

  List<Map<String, dynamic>> cycles = [];
  int? activeCycleId;
  bool cyclesLoading = true;
  String? cycleError;

  @override
  void initState() {
    super.initState();
    loadCycles();
  }

  List<ExerciseInfo> get filteredExercises {
    return ExerciseLibrary.forMuscle(
      selectedMuscle,
      query: searchController.text,
      equipment: selectedEquipment,
      difficulty: selectedDifficulty,
    );
  }

  Future<void> loadCycles() async {
    if (!mounted) return;

    setState(() {
      cyclesLoading = true;
      cycleError = null;
    });

    try {
      final db = DatabaseService.instance;

      // These methods also initialize the cycle tables if needed.
      final active = await db.getActiveTrainingCycle();
      final savedCycles = await db.getTrainingCycles();

      if (!mounted) return;

      setState(() {
        cycles = savedCycles;
        activeCycleId = (active['id'] as num).toInt();
        cyclesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        cyclesLoading = false;
        cycleError = error.toString();
      });
    }
  }

  Future<void> activateCycle(int cycleId) async {
    try {
      await DatabaseService.instance.setActiveTrainingCycle(cycleId);
      await loadCycles();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not switch workout cycle: $error'),
        ),
      );
    }
  }

  Future<void> createNewCycle() async {
    // The dialog owns its TextEditingController and disposes it only
    // when the dialog widget itself is removed from the widget tree.
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewCycleDialog(),
    );

    if (name == null || name.trim().isEmpty || !mounted) {
      return;
    }

    try {
      await DatabaseService.instance.createTrainingCycle(name.trim());

      if (!mounted) return;

      await loadCycles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${name.trim()}" is now your active cycle.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create cycle: $error'),
        ),
      );
    }
  }

  String formatCycleDate(dynamic rawDate) {
    final date = DateTime.tryParse(rawDate?.toString() ?? '');

    if (date == null) return 'Start date unavailable';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget buildCycleCard() {
    if (cyclesLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 14),
            Text('Loading workout cycles...'),
          ],
        ),
      );
    }

    if (cycleError != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(height: 10),
            const Text(
              'Could not load workout cycles',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              cycleError!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: loadCycles,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final activeCycle = cycles.cast<Map<String, dynamic>?>().firstWhere(
          (cycle) => (cycle?['id'] as num?)?.toInt() == activeCycleId,
      orElse: () => null,
    );

    final activeName = activeCycle?['name']?.toString() ?? 'Active Cycle';
    final workoutCount =
        (activeCycle?['workoutCount'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.autorenew,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WORKOUT CYCLE',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$workoutCount saved workout${workoutCount == 1 ? '' : 's'}'
                '${activeCycle == null ? '' : ' • Started ${formatCycleDate(activeCycle['startedAt'])}'}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            key: ValueKey<int?>(activeCycleId),
            value: activeCycleId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Active cycle',
              prefixIcon: const Icon(Icons.layers_outlined),
              filled: true,
              fillColor: const Color(0xFF101114),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: cycles.map((cycle) {
              final id = (cycle['id'] as num).toInt();
              final name = cycle['name']?.toString() ?? 'Cycle';
              final count =
                  (cycle['workoutCount'] as num?)?.toInt() ?? 0;

              return DropdownMenuItem<int>(
                value: id,
                child: Text(
                  '$name ($count)',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null && value != activeCycleId) {
                activateCycle(value);
              }
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: createNewCycle,
              icon: const Icon(Icons.add),
              label: const Text('New Workout Cycle'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void toggleExercise(ExerciseInfo exercise) {
    setState(() {
      if (selectedExerciseNames.contains(exercise.name)) {
        selectedExerciseNames.remove(exercise.name);
      } else {
        selectedExerciseNames.add(exercise.name);
      }
    });
  }

  void changeMuscle(String muscle) {
    setState(() {
      selectedMuscle = muscle;
      selectedEquipment = 'All';
      selectedDifficulty = 'All';
      searchController.clear();
      selectedExerciseNames.clear();
    });
  }

  Future<void> startWorkout() async {
    final exercises = ExerciseLibrary.forMuscle(selectedMuscle)
        .where(
          (exercise) => selectedExerciseNames.contains(exercise.name),
    )
        .toList();

    if (exercises.isEmpty) return;

    if (activeCycleId == null || cyclesLoading || cycleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Load a workout cycle before starting.'),
        ),
      );
      return;
    }

    final cycleId = activeCycleId!;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSessionScreen(
          split: selectedMuscle,
          selectedExercises: exercises,
          cycleId: cycleId,
        ),
      ),
    );

    if (!mounted) return;

    await loadCycles();

    setState(() {
      selectedExerciseNames.clear();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = filteredExercises;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Your Workout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh cycles',
            onPressed: loadCycles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildCycleCard(),

          const Text(
            'SELECT A MUSCLE',
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExerciseLibrary.muscles.map((muscle) {
              final selected = selectedMuscle == muscle;

              return ChoiceChip(
                label: Text(muscle),
                selected: selected,
                selectedColor: Colors.orange,
                labelStyle: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => changeMuscle(muscle),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: Text(
                  '$selectedMuscle Exercises',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${exercises.length} available',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                onPressed: () {
                  searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
              filled: true,
              fillColor: const Color(0xFF1A1D21),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedEquipment,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Equipment',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    'All',
                    ...ExerciseLibrary.equipmentTypes,
                  ].map((equipment) {
                    return DropdownMenuItem(
                      value: equipment,
                      child: Text(
                        equipment,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedEquipment = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedDifficulty,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    'All',
                    'Beginner',
                    'Intermediate',
                    'Advanced',
                  ].map((difficulty) {
                    return DropdownMenuItem(
                      value: difficulty,
                      child: Text(difficulty),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedDifficulty = value;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (selectedExerciseNames.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${selectedExerciseNames.length} exercises selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedExerciseNames.clear();
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          if (exercises.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text('No matching exercises found.'),
                  SizedBox(height: 4),
                  Text(
                    'Try another search or filter.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

          ...exercises.map((exercise) {
            final selected =
            selectedExerciseNames.contains(exercise.name);

            return Card(
              color: const Color(0xFF1A1D21),
              margin: const EdgeInsets.only(bottom: 10),
              child: CheckboxListTile(
                value: selected,
                activeColor: Colors.orange,
                checkColor: Colors.black,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (_) => toggleExercise(exercise),
                title: Text(
                  exercise.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${exercise.equipment} • '
                            '${exercise.targetSets} sets × '
                            '${exercise.targetReps}',
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${exercise.difficulty}'
                            '${exercise.secondaryMuscles.isNotEmpty ? ' • Also: ${exercise.secondaryMuscles.join(', ')}' : ''}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          onPressed: selectedExerciseNames.isEmpty ||
              activeCycleId == null ||
              cyclesLoading ||
              cycleError != null
              ? null
              : startWorkout,
          icon: const Icon(Icons.play_arrow),
          label: Text(
            'Start Workout (${selectedExerciseNames.length})',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.grey.shade800,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewCycleDialog extends StatefulWidget {
  const _NewCycleDialog();

  @override
  State<_NewCycleDialog> createState() => _NewCycleDialogState();
}

class _NewCycleDialogState extends State<_NewCycleDialog> {
  final TextEditingController controller = TextEditingController();

  void submit() {
    final name = controller.text.trim();
    if (name.isEmpty) return;

    Navigator.of(context).pop(name);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Workout Cycle'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Cycle name',
          hintText: 'e.g. Lean Bulk - Cycle 2',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: submit,
          child: const Text('Create Cycle'),
        ),
      ],
    );
  }
}

