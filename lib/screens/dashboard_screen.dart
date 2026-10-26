import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../widgets/progress_chart.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onBuildWorkout;
  final VoidCallback? onOpenNutrition;

  const DashboardScreen({
    super.key,
    this.onBuildWorkout,
    this.onOpenNutrition,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const List<String> weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static const List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  late DateTime weekStart;

  bool loading = true;

  int totalWorkouts = 0;
  int totalPRs = 0;
  int workoutsThisWeek = 0;
  int mealsToday = 0;

  double weeklyVolume = 0;
  double todayCalories = 0;
  double todayProtein = 0;
  double todayCarbs = 0;
  double todayFat = 0;

  List<Map<String, dynamic>> weeklySessions = [];
  int? selectedWeekday;

  @override
  void initState() {
    super.initState();
    weekStart = _startOfWeek(DateTime.now());
    loadDashboard();
  }

  DateTime _startOfWeek(DateTime date) {
    final today = DateTime(date.year, date.month, date.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _workoutDate(Map<String, dynamic> workout) {
    final storedDate = workout['localDate'];

    if (storedDate is String) {
      final parsed = DateTime.tryParse(storedDate);

      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    final rawDate = workout['date'];
    if (rawDate is! String) return null;

    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return null;

    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _formatDate(DateTime date) {
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatWeekRange() {
    final end = weekStart.add(const Duration(days: 6));

    if (weekStart.month == end.month &&
        weekStart.year == end.year) {
      return '${months[weekStart.month - 1]} '
          '${weekStart.day}–${end.day}, ${end.year}';
    }

    return '${_formatDate(weekStart)} – '
        '${_formatDate(end)}, ${end.year}';
  }

  String _sessionDate(DateTime date) {
    return '${weekdays[date.weekday - 1]}, ${_formatDate(date)}';
  }

  Future<void> loadDashboard() async {
    try {
      final db = DatabaseService.instance;
      final now = DateTime.now();
      final start = _startOfWeek(now);
      final end = start.add(const Duration(days: 7));

      final allWorkouts = await db.getWorkouts();
      final workoutCount = await db.getWorkoutCount();
      final prCount = await db.getPRCount();

      final weeklySessions = allWorkouts.where((workout) {
        final date = _workoutDate(workout);
        return date != null &&
            !date.isBefore(start) &&
            date.isBefore(end);
      }).toList();

      weeklySessions.sort((a, b) {
        final dateA = _workoutDate(a);
        final dateB = _workoutDate(b);

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      // Weekly volume from completed weighted sets.
      final database = await db.database;

      final volumeResult = await database.rawQuery(
        '''
        SELECT COALESCE(SUM(es.weight * es.reps), 0) AS volume
        FROM exercise_sets es
        INNER JOIN workouts w ON es.workoutId = w.id
        WHERE w.localDate >= ?
          AND w.localDate < ?
          AND es.completed = 1
        ''',
        [_dateKey(start), _dateKey(end)],
      );

      final volume = _number(volumeResult.first['volume']);

      // Today's nutrition comes from locally saved meals.
      final nutrition = await db.getDailyNutrition(now);

      if (!mounted) return;

      setState(() {
        weekStart = start;
        totalWorkouts = workoutCount;
        totalPRs = prCount;
        workoutsThisWeek = weeklySessions.length;
        this.weeklySessions = weeklySessions;
        weeklyVolume = volume;

        mealsToday =
            (nutrition['mealCount'] as num?)?.toInt() ?? 0;
        todayCalories = _number(nutrition['calories']);
        todayProtein = _number(nutrition['protein']);
        todayCarbs = _number(nutrition['carbs']);
        todayFat = _number(nutrition['fat']);

        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not refresh dashboard: $error'),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get visibleSessions {
    if (selectedWeekday == null) return weeklySessions;

    return weeklySessions.where((workout) {
      return _workoutDate(workout)?.weekday == selectedWeekday;
    }).toList();
  }

  int _sessionsOnDay(DateTime day) {
    return weeklySessions.where((workout) {
      final date = _workoutDate(workout);

      return date != null &&
          date.year == day.year &&
          date.month == day.month &&
          date.day == day.day;
    }).length;
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
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
          Icon(icon, color: Colors.orange, size: 24),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekCalendar() {
    final today = DateTime.now();

    return Row(
      children: List.generate(7, (index) {
        final day = weekStart.add(Duration(days: index));
        final count = _sessionsOnDay(day);

        final isToday = day.year == today.year &&
            day.month == today.month &&
            day.day == today.day;

        final selected = selectedWeekday == day.weekday;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  selectedWeekday =
                  selected ? null : day.weekday;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 1,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.orange
                      : isToday
                      ? Colors.orange.withValues(alpha: 0.12)
                      : const Color(0xFF22242A),
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !selected
                      ? Border.all(color: Colors.orange)
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      weekdays[index],
                      style: TextStyle(
                        fontSize: 10,
                        color: selected ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Icon(
                      count > 0
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      size: 12,
                      color: count > 0
                          ? selected
                          ? Colors.black
                          : Colors.greenAccent
                          : Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _sessionList() {
    final sessions = visibleSessions;

    if (sessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(Icons.fitness_center, size: 34, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'No workouts for this selection',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 5),
            Text(
              'Completed sessions will appear here.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: sessions.map((workout) {
        final date = _workoutDate(workout);
        final split = workout['split']?.toString() ?? 'Workout';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D21),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0x33FF9800),
                child: Icon(Icons.fitness_center, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      split,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date == null
                          ? 'Date unavailable'
                          : _sessionDate(date),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _nutritionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.greenAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu,
                color: Colors.greenAccent,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Today's Nutrition",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh nutrition',
                onPressed: loadDashboard,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$mealsToday meal${mealsToday == 1 ? '' : 's'} saved today',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 18),
          const Text(
            'CALORIES CONSUMED',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                todayCalories.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 7, bottom: 6),
                child: Text(
                  'kcal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _macroMini(
                  'Protein',
                  todayProtein,
                  Colors.greenAccent,
                ),
              ),
              Expanded(
                child: _macroMini(
                  'Carbs',
                  todayCarbs,
                  Colors.lightBlueAccent,
                ),
              ),
              Expanded(
                child: _macroMini(
                  'Fat',
                  todayFat,
                  Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onOpenNutrition,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Log a Meal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroMini(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          '${value.toStringAsFixed(1)} g',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chosenDay = selectedWeekday == null
        ? null
        : weekdays[selectedWeekday! - 1];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'IRONLOG',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            if (loading) const LinearProgressIndicator(),

            const Text(
              'YOUR FITNESS, AT A GLANCE',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              "Let's get stronger.",
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Train with purpose. Track every rep.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 23),

            // Muscle-wise workout shortcut.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D21),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: Colors.orange,
                    size: 30,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'What are we training today?',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose a muscle and build your own workout '
                        'from the exercise library.',
                    style: TextStyle(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 17),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onBuildWorkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Build Your Workout'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 27),

            // Week calendar.
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Your Week',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatWeekRange(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Your calendar week runs Monday to Sunday.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 15),

            _weekCalendar(),

            const SizedBox(height: 17),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.32,
              children: [
                _statCard(
                  title: 'This Week',
                  value: '$workoutsThisWeek',
                  subtitle: 'Workouts',
                  icon: Icons.calendar_month,
                ),
                _statCard(
                  title: 'Training Volume',
                  value: weeklyVolume >= 1000
                      ? '${(weeklyVolume / 1000).toStringAsFixed(1)}k'
                      : weeklyVolume.toStringAsFixed(0),
                  subtitle: 'Weighted sets · kg × reps',
                  icon: Icons.trending_up,
                ),
                _statCard(
                  title: 'All Workouts',
                  value: '$totalWorkouts',
                  subtitle: 'Sessions saved',
                  icon: Icons.fitness_center,
                ),
                _statCard(
                  title: 'Personal Records',
                  value: '$totalPRs',
                  subtitle: 'Exercises with a PR',
                  icon: Icons.emoji_events,
                ),
              ],
            ),

            const SizedBox(height: 27),

            Row(
              children: [
                Expanded(
                  child: Text(
                    chosenDay == null
                        ? 'Completed This Week'
                        : 'Completed on $chosenDay',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (selectedWeekday != null)
                  TextButton(
                    onPressed: () {
                      setState(() => selectedWeekday = null);
                    },
                    child: const Text('Show all'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            _sessionList(),

            const SizedBox(height: 27),

            const Text(
              'Progression',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 13),

            const ProgressChart(),

            const SizedBox(height: 27),

            _nutritionCard(),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}