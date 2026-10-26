
import 'package:flutter/material.dart';
import 'personal_records_screen.dart';
import '../database/database_service.dart';
import 'exercise_progress_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> workouts = [];

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  DateTime? workoutDate(Map<String, dynamic> workout) {
    final localDate = workout['localDate']?.toString();

    if (localDate != null && localDate.isNotEmpty) {
      final parsed = DateTime.tryParse(localDate);

      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    final date = workout['date']?.toString();

    if (date != null && date.isNotEmpty) {
      final parsed = DateTime.tryParse(date);

      if (parsed != null) {
        final local = parsed.toLocal();
        return DateTime(local.year, local.month, local.day);
      }
    }

    return null;
  }

  DateTime startOfWeek(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day - date.weekday + 1,
    );
  }

  Future<void> loadProgress() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final savedWorkouts =
      await DatabaseService.instance.getWorkouts();

      final sorted = List<Map<String, dynamic>>.from(savedWorkouts);

      sorted.sort((a, b) {
        final dateA = workoutDate(a);
        final dateB = workoutDate(b);

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      if (!mounted) return;

      setState(() {
        workouts = sorted;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Could not load workout history: $error';
      });
    }
  }

  List<int> get weeklyActivity {
    final today = DateTime.now();
    final start = startOfWeek(today);
    final counts = List<int>.filled(7, 0);

    for (final workout in workouts) {
      final date = workoutDate(workout);

      if (date == null) continue;

      final dayIndex = date.difference(start).inDays;

      if (dayIndex >= 0 && dayIndex < 7) {
        counts[dayIndex]++;
      }
    }

    return counts;
  }

  int get workoutsThisWeek =>
      weeklyActivity.fold(0, (total, count) => total + count);

  int get activeDaysThisWeek =>
      weeklyActivity.where((count) => count > 0).length;

  int get workoutsLast30Days {
    final today = DateTime.now();

    final cutoff = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 29));

    return workouts.where((workout) {
      final date = workoutDate(workout);
      return date != null && !date.isBefore(cutoff);
    }).length;
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String formatWeekday(int weekday) {
    const days = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return days[weekday - 1];
  }

  Widget statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWeeklyChart() {
    final activity = weeklyActivity;

    final maximum = activity.fold<int>(
      1,
          (current, count) => count > current ? count : current,
    );

    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly activity',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$workoutsThisWeek sessions across '
                '$activeDaysThisWeek active days',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final count = activity[index];
              final fraction = count / maximum;

              final double barHeight = count == 0
                  ? 0.0
                  : (74 * fraction).clamp(6.0, 74.0).toDouble();

              final dayDate = DateTime(
                today.year,
                today.month,
                today.day - today.weekday + 1 + index,
              );

              final isToday =
                  dayDate.day == today.day &&
                      dayDate.month == today.month &&
                      dayDate.year == today.year;

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: count > 0
                            ? Colors.orange
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 78,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 22,
                            height: 74,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          if (count > 0)
                            Container(
                              width: 22,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatWeekday(index + 1),
                      style: TextStyle(
                        color: isToday
                            ? Colors.orange
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget buildWorkoutHistory() {
    if (workouts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.fitness_center,
              size: 42,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No workouts recorded yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Complete a workout and it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: workouts.take(50).map((workout) {
        final split = workout['split']?.toString().trim();

        final title =
        split == null || split.isEmpty ? 'Workout' : split;

        final id = workout['id']?.toString();
        final date = workoutDate(workout);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D21),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatDate(date),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (id != null)
                Text(
                  '#$id',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void openExerciseProgression() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ExerciseProgressScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progress',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Personal records',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalRecordsScreen(),
                ),
              );
            },
          ),
          IconButton(
            onPressed: isLoading ? null : loadProgress,
            tooltip: 'Refresh progress',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: openExerciseProgression,
            tooltip: 'Exercise progression',
            icon: const Icon(Icons.query_stats),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.orange,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: loadProgress,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadProgress,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'YOUR TRAINING',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Every session counts.',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Build consistency and keep track of your '
                  'training history.',
              style: TextStyle(
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.18,
              children: [
                statCard(
                  title: 'Total workouts',
                  value: '${workouts.length}',
                  subtitle: 'All recorded sessions',
                  icon: Icons.fitness_center,
                ),
                statCard(
                  title: 'This week',
                  value: '$workoutsThisWeek',
                  subtitle: '$activeDaysThisWeek active days',
                  icon: Icons.calendar_today,
                ),
                statCard(
                  title: 'Last 30 days',
                  value: '$workoutsLast30Days',
                  subtitle: 'Recent sessions',
                  icon: Icons.trending_up,
                ),
                statCard(
                  title: 'Consistency',
                  value: '$activeDaysThisWeek/7',
                  subtitle: 'Days trained this week',
                  icon: Icons.bolt,
                ),
              ],
            ),
            const SizedBox(height: 22),
            buildWeeklyChart(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Workout history',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${workouts.length} sessions',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            buildWorkoutHistory(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
