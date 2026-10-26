import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../database/database_service.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  final String exerciseName;

  const ExerciseHistoryScreen({
    super.key,
    required this.exerciseName,
  });

  @override
  State<ExerciseHistoryScreen> createState() =>
      _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState
    extends State<ExerciseHistoryScreen> {
  bool loading = true;
  String? errorMessage;

  List<_WorkoutRecord> history = [];
  String currentRecordType = 'load_reps';

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  DateTime? _parseDate(Map<String, dynamic> row) {
    final localDate = row['localDate'];

    if (localDate is String) {
      final parsed = DateTime.tryParse(localDate);

      if (parsed != null) {
        return DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
        );
      }
    }

    final rawDate = row['date'];

    if (rawDate is! String) return null;

    return DateTime.tryParse(rawDate)?.toLocal();
  }

  Future<void> loadHistory() async {
    try {
      final rows = await DatabaseService.instance
          .getPreviousWorkoutSets(widget.exerciseName);

      final completedRows = rows.where((row) {
        return (row['completed'] as num?)?.toInt() == 1;
      }).toList();

      // Group completed sets by workout.
      final grouped =
      <String, List<Map<String, dynamic>>>{};

      for (final row in completedRows) {
        final workoutId = row['workoutId'];
        final key = workoutId?.toString() ??
            '${row['localDate']}_${row['date']}';

        grouped.putIfAbsent(key, () => []).add(row);
      }

      final records = <_WorkoutRecord>[];

      for (final group in grouped.values) {
        if (group.isEmpty) continue;

        final date = _parseDate(group.first);
        if (date == null) continue;

        final recordType =
            group.last['recordType']?.toString() ?? 'load_reps';

        double bestWeight = 0;
        int repsAtBestWeight = 0;
        int bestAmount = 0;
        double volume = 0;

        for (final set in group) {
          final weight =
              (set['weight'] as num?)?.toDouble() ?? 0;

          final amount =
              (set['reps'] as num?)?.toInt() ?? 0;

          if (amount > bestAmount) {
            bestAmount = amount;
          }

          if (recordType == 'load_reps') {
            if (weight > bestWeight) {
              bestWeight = weight;
              repsAtBestWeight = amount;
            } else if (weight == bestWeight &&
                amount > repsAtBestWeight) {
              repsAtBestWeight = amount;
            }

            if (weight > 0 && amount > 0) {
              volume += weight * amount;
            }
          }
        }

        records.add(
          _WorkoutRecord(
            date: date,
            recordType: recordType,
            bestWeight: bestWeight,
            repsAtBestWeight: repsAtBestWeight,
            bestAmount: bestAmount,
            volume: volume,
            setCount: group.length,
          ),
        );
      }

      records.sort((a, b) => a.date.compareTo(b.date));

      _calculatePRTimeline(records);

      if (!mounted) return;

      setState(() {
        history = records;

        if (records.isNotEmpty) {
          currentRecordType = records.last.recordType;
        }

        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = error.toString();
      });
    }
  }

  void _calculatePRTimeline(List<_WorkoutRecord> records) {
    final bestByType = <String, _WorkoutRecord>{};

    for (final record in records) {
      final previous = bestByType[record.recordType];

      bool improved = false;

      if (previous == null) {
        improved = true;
      } else if (record.recordType == 'load_reps') {
        improved =
            record.bestWeight > previous.bestWeight ||
                (record.bestWeight == previous.bestWeight &&
                    record.repsAtBestWeight >
                        previous.repsAtBestWeight);
      } else {
        improved = record.bestAmount > previous.bestAmount;
      }

      record.isPR = improved;

      if (improved) {
        bestByType[record.recordType] = record;
      }
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'bodyweight_reps':
        return 'Bodyweight';
      case 'duration_seconds':
        return 'Timed';
      default:
        return 'Weighted';
    }
  }

  String _dateLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _performanceLabel(_WorkoutRecord record) {
    switch (record.recordType) {
      case 'bodyweight_reps':
        return '${record.bestAmount} reps';

      case 'duration_seconds':
        return '${record.bestAmount} seconds';

      default:
        return '${record.bestWeight.toStringAsFixed(1)} kg'
            ' × ${record.repsAtBestWeight} reps';
    }
  }

  double _performanceValue(_WorkoutRecord record) {
    if (record.recordType == 'load_reps') {
      return record.bestWeight;
    }

    return record.bestAmount.toDouble();
  }

  List<_WorkoutRecord> get currentTypeHistory {
    return history
        .where((record) =>
    record.recordType == currentRecordType)
        .toList();
  }

  String get _metricUnit {
    switch (currentRecordType) {
      case 'bodyweight_reps':
        return 'reps';
      case 'duration_seconds':
        return 'seconds';
      default:
        return 'kg';
    }
  }

  String get _metricTitle {
    switch (currentRecordType) {
      case 'bodyweight_reps':
        return 'Best Reps';
      case 'duration_seconds':
        return 'Longest Duration';
      default:
        return 'Best Weight';
    }
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final records = currentTypeHistory;

    if (records.isEmpty) {
      return const _EmptyState(
        message: 'Complete an exercise to see your progression.',
      );
    }

    final recent = records.length <= 7
        ? records
        : records.sublist(records.length - 7);

    double maxValue = 1;

    for (final record in recent) {
      maxValue = math.max(
        maxValue,
        _performanceValue(record),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance (${_metricUnit})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Recent completed workouts',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 155,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: recent.map((record) {
                final value = _performanceValue(record);

                final barHeight = value <= 0
                    ? 3.0
                    : (value / maxValue * 90)
                    .clamp(4.0, 90.0)
                    .toDouble();

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          value.toStringAsFixed(
                            value == value.roundToDouble() ? 0 : 1,
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          height: barHeight,
                          width: 18,
                          decoration: BoxDecoration(
                            color: record.isPR
                                ? Colors.greenAccent
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${record.date.day}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Green bars indicate a new record.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeTab() {
    if (currentRecordType != 'load_reps') {
      return const _EmptyState(
        message:
        'Load volume applies to weighted exercises. '
            'Bodyweight reps and timed exercises use other metrics.',
      );
    }

    final records = currentTypeHistory;

    if (records.isEmpty) {
      return const _EmptyState(
        message: 'Complete weighted sets to track volume.',
      );
    }

    final recent = records.length <= 7
        ? records
        : records.sublist(records.length - 7);

    final maxVolume = recent.fold<double>(
      1,
          (maximum, record) => math.max(maximum, record.volume),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Volume',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sum of completed weight × reps',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          ...recent.reversed.map((record) {
            final fraction =
            (record.volume / maxVolume).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_dateLabel(record.date)),
                      Text(
                        '${record.volume.toStringAsFixed(0)} kg × reps',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade800,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPRTab() {
    final prs = history
        .where((record) => record.isPR)
        .toList()
        .reversed
        .toList();

    if (prs.isEmpty) {
      return const _EmptyState(
        message: 'Your future personal records will appear here.',
      );
    }

    return Column(
      children: prs.map((record) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D21),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0x3338D98B),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _performanceLabel(record),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateLabel(record.date),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _typeLabel(record.recordType),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
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

  Widget _buildHistoryList() {
    if (history.isEmpty) {
      return const _EmptyState(
        message: 'No completed sets recorded for this exercise yet.',
      );
    }

    return Column(
      children: history.reversed.map((record) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D21),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.history,
                color: Colors.orange,
                size: 25,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateLabel(record.date),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _performanceLabel(record),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.setCount} completed sets · '
                          '${_typeLabel(record.recordType)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (record.isPR)
                const Icon(
                  Icons.emoji_events,
                  color: Colors.greenAccent,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPerformanceTab() {
    final relevant = currentTypeHistory;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (relevant.isEmpty) {
      return const _EmptyState(
        message: 'Finish a workout to begin tracking progression.',
      );
    }

    final best = relevant.reduce((a, b) {
      if (currentRecordType == 'load_reps') {
        if (a.bestWeight != b.bestWeight) {
          return a.bestWeight > b.bestWeight ? a : b;
        }

        return a.repsAtBestWeight >= b.repsAtBestWeight ? a : b;
      }

      return a.bestAmount >= b.bestAmount ? a : b;
    });

    final averageSets = relevant.fold<int>(
      0,
          (total, record) => total + record.setCount,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                label: _metricTitle,
                value: _performanceLabel(best),
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                label: 'Sessions',
                value: '${relevant.length}',
                icon: Icons.history,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _statCard(
          label: 'Completed sets across sessions',
          value: '$averageSets',
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(height: 20),
        _buildPerformanceChart(),
        const SizedBox(height: 24),
        const Text(
          'Workout History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildHistoryList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.exerciseName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Performance'),
              Tab(text: 'Volume'),
              Tab(text: 'PRs'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh history',
              onPressed: loadHistory,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? _EmptyState(
          message: 'Could not load history.\n$errorMessage',
        )
            : TabBarView(
          children: [
            _buildPerformanceTab(),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildVolumeTab(),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPRTab(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutRecord {
  final DateTime date;
  final String recordType;
  final double bestWeight;
  final int repsAtBestWeight;
  final int bestAmount;
  final double volume;
  final int setCount;

  bool isPR = false;

  _WorkoutRecord({
    required this.date,
    required this.recordType,
    required this.bestWeight,
    required this.repsAtBestWeight,
    required this.bestAmount,
    required this.volume,
    required this.setCount,
  });
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insights,
              size: 42,
              color: Colors.grey,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}