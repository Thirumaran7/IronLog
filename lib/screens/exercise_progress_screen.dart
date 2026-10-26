
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../database/database_service.dart';

class ExerciseProgressScreen extends StatefulWidget {
  const ExerciseProgressScreen({super.key});

  @override
  State<ExerciseProgressScreen> createState() =>
      _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState
    extends State<ExerciseProgressScreen> {
  bool loading = true;
  String? error;
  String? selectedExercise;

  Map<String, List<Map<String, dynamic>>> histories = {};

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  double number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String formatDate(dynamic value) {
    final date = parseDate(value);
    if (date == null) return 'Date unavailable';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> loadProgress() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final rows =
      await DatabaseService.instance.getAllExerciseProgress();

      final grouped = <String, List<Map<String, dynamic>>>{};

      for (final row in rows) {
        final name = row['exerciseName']?.toString().trim() ?? '';

        if (name.isEmpty) continue;

        grouped.putIfAbsent(name, () => []).add(row);
      }

      for (final records in grouped.values) {
        records.sort((a, b) {
          final dateA = parseDate(a['workoutDate']);
          final dateB = parseDate(b['workoutDate']);

          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateB.compareTo(dateA);
        });
      }

      final names = grouped.keys.toList()
        ..sort((a, b) {
          final dateA = parseDate(grouped[a]!.first['workoutDate']);
          final dateB = parseDate(grouped[b]!.first['workoutDate']);

          if (dateA == null && dateB == null) {
            return a.compareTo(b);
          }
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateB.compareTo(dateA);
        });

      if (!mounted) return;

      setState(() {
        histories = grouped;

        if (selectedExercise == null ||
            !grouped.containsKey(selectedExercise)) {
          selectedExercise = names.isEmpty ? null : names.first;
        }

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> get currentRecords {
    return histories[selectedExercise] ?? [];
  }

  String recordType(Map<String, dynamic> record) {
    return record['recordType']?.toString() ?? 'load_reps';
  }

  bool isWeighted(Map<String, dynamic> record) {
    return recordType(record) == 'load_reps';
  }

  bool isTimed(Map<String, dynamic> record) {
    return recordType(record) == 'duration_seconds';
  }

  double metric(Map<String, dynamic> record) {
    if (isWeighted(record)) {
      return number(record['bestWeight']);
    }

    return number(record['bestAmount']);
  }

  String metricLabel(Map<String, dynamic> record) {
    if (isWeighted(record)) {
      return '${metric(record).toStringAsFixed(1)} kg';
    }

    final amount = number(record['bestAmount']).toStringAsFixed(0);
    return isTimed(record) ? '$amount sec' : '$amount reps';
  }

  String comparisonText(
      Map<String, dynamic> latest,
      Map<String, dynamic> previous,
      ) {
    if (recordType(latest) != recordType(previous)) {
      return 'Tracking type changed between sessions';
    }

    if (isWeighted(latest)) {
      final currentWeight = number(latest['bestWeight']);
      final previousWeight = number(previous['bestWeight']);
      final currentReps = number(latest['bestAmount']);
      final previousReps = number(previous['bestAmount']);

      if (currentWeight > previousWeight) {
        return '+${(currentWeight - previousWeight).toStringAsFixed(1)} kg '
            'in best load';
      }

      if (currentWeight < previousWeight) {
        return '${(currentWeight - previousWeight).toStringAsFixed(1)} kg '
            'in best load';
      }

      if (currentReps > previousReps) {
        return '+${(currentReps - previousReps).toStringAsFixed(0)} '
            'in best reps';
      }

      if (currentReps < previousReps) {
        return '${(currentReps - previousReps).toStringAsFixed(0)} '
            'in best reps';
      }

      return 'Best load and reps maintained';
    }

    final difference =
        number(latest['bestAmount']) - number(previous['bestAmount']);

    if (difference > 0) {
      return '+${difference.toStringAsFixed(0)} '
          '${isTimed(latest) ? 'seconds' : 'reps'}';
    }

    if (difference < 0) {
      return '${difference.toStringAsFixed(0)} '
          '${isTimed(latest) ? 'seconds' : 'reps'}';
    }

    return 'Previous performance matched';
  }

  Widget summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange),
          const SizedBox(height: 13),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
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

  Widget buildChart(List<Map<String, dynamic>> records) {
    // Records arrive newest first; display the oldest of the last six first.
    final recent = records.take(6).toList().reversed.toList();

    final values = recent.map(metric).toList();
    final maximum = values.fold<double>(
      0,
          (maxValue, value) => math.max(maxValue, value),
    );

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
            'Recent performance',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isWeighted(records.first)
                ? 'Best recorded load per session'
                : isTimed(records.first)
                ? 'Best duration per session'
                : 'Best reps per session',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(recent.length, (index) {
                final record = recent[index];
                final value = values[index];

                final barHeight = maximum <= 0
                    ? 0.0
                    : (value / maximum * 88).clamp(5.0, 88.0);

                final date = parseDate(record['workoutDate']);
                final dateLabel = date == null
                    ? '--'
                    : '${date.day}/${date.month}';

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          child: Text(
                            value == value.roundToDouble()
                                ? value.toStringAsFixed(0)
                                : value.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSessionHistory(List<Map<String, dynamic>> records) {
    return Column(
      children: records.map((record) {
        final name = record['workoutName']?.toString() ?? 'Workout';
        final sets = record['completedSets']?.toString() ?? '0';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D21),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.fitness_center,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(record['workoutDate']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sets completed sets',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                metricLabel(record),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = currentRecords;
    final latest = records.isEmpty ? null : records.first;
    final previous = records.length > 1 ? records[1] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exercise Progress',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : loadProgress,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.orange,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not load exercise progression.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: loadProgress,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      )
          : histories.isEmpty
          ? RefreshIndicator(
        onRefresh: loadProgress,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          children: const [
            SizedBox(height: 90),
            Icon(
              Icons.show_chart,
              color: Colors.grey,
              size: 58,
            ),
            SizedBox(height: 18),
            Text(
              'No exercise history yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete and save a workout with completed sets '
                  'to start tracking progression.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'TRACK YOUR LIFTS',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get stronger over time.',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Compare your completed sets across workout sessions.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: selectedExercise,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Choose exercise',
              filled: true,
              fillColor: const Color(0xFF1A1D21),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: histories.keys.map((name) {
              return DropdownMenuItem<String>(
                value: name,
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedExercise = value;
              });
            },
          ),
          const SizedBox(height: 20),
          if (latest != null) ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                summaryCard(
                  title: 'Latest best',
                  value: metricLabel(latest),
                  subtitle: formatDate(
                    latest['workoutDate'],
                  ),
                  icon: Icons.emoji_events_outlined,
                ),
                summaryCard(
                  title: 'Sessions',
                  value: '${records.length}',
                  subtitle: 'Recorded for this exercise',
                  icon: Icons.history,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (previous != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D21),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Since your previous session',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comparisonText(latest, previous),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Previous: ${metricLabel(previous)} · '
                          '${formatDate(previous['workoutDate'])}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            buildChart(records),
            const SizedBox(height: 24),
            const Text(
              'Session history',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            buildSessionHistory(records),
          ],
        ],
      ),
    );
  }
}
