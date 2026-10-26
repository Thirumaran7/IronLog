
import 'package:flutter/material.dart';

import '../database/database_service.dart';

class PersonalRecordsScreen extends StatefulWidget {
  const PersonalRecordsScreen({super.key});

  @override
  State<PersonalRecordsScreen> createState() =>
      _PersonalRecordsScreenState();
}

class _PersonalRecordsScreenState
    extends State<PersonalRecordsScreen> {
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> records = [];

  final TextEditingController searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadRecords() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final savedRecords = await DatabaseService.instance
          .getAllPersonalRecords();

      if (!mounted) return;

      setState(() {
        records = savedRecords;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  dynamic firstValue(
      Map<String, dynamic> record,
      List<String> candidates,
      ) {
    for (final key in candidates) {
      final value = record[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  double number(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String exerciseName(Map<String, dynamic> record) {
    final value = firstValue(record, [
      'exercise',
      'exerciseName',
      'exercise_name',
      'name',
    ]);

    return value?.toString() ?? 'Exercise';
  }

  String recordType(Map<String, dynamic> record) {
    return firstValue(record, [
      'recordType',
      'record_type',
    ])?.toString() ??
        'load_reps';
  }

  String formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  String bestPerformance(Map<String, dynamic> record) {
    final type = recordType(record);

    final weight = firstValue(record, [
      'weight',
      'bestWeight',
      'best_weight',
    ]);

    final reps = firstValue(record, [
      'reps',
      'bestReps',
      'best_reps',
    ]);

    final amount = firstValue(record, [
      'amount',
      'bestAmount',
      'best_amount',
      'value',
      'durationSeconds',
      'duration_seconds',
    ]);

    if (type == 'duration_seconds') {
      final duration = amount ?? reps;

      if (duration != null) {
        return '${formatNumber(number(duration))} seconds';
      }
    }

    if (type == 'bodyweight_reps') {
      final count = amount ?? reps;

      if (count != null) {
        return '${formatNumber(number(count))} reps';
      }
    }

    if (weight != null && reps != null) {
      final load = number(weight);
      final repCount = number(reps);

      if (load > 0) {
        return '${formatNumber(load)} kg × '
            '${formatNumber(repCount)} reps';
      }

      return '${formatNumber(repCount)} reps';
    }

    if (weight != null && number(weight) > 0) {
      return '${formatNumber(number(weight))} kg';
    }

    if (amount != null) {
      return formatNumber(number(amount));
    }

    if (reps != null) {
      return '${formatNumber(number(reps))} reps';
    }

    return 'Record saved';
  }

  String recordDate(Map<String, dynamic> record) {
    final value = firstValue(record, [
      'updatedAt',
      'updated_at',
      'date',
      'achievedAt',
      'achieved_at',
      'createdAt',
      'created_at',
    ]);

    if (value == null) return 'Personal best';

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) return 'Personal best';

    final date = parsed.toLocal();

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

  List<Map<String, dynamic>> get filteredRecords {
    final query = searchController.text.trim().toLowerCase();

    final result = records.where((record) {
      return exerciseName(record).toLowerCase().contains(query);
    }).toList();

    result.sort((a, b) {
      return exerciseName(a).toLowerCase().compareTo(
        exerciseName(b).toLowerCase(),
      );
    });

    return result;
  }

  Widget recordCard(Map<String, dynamic> record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.orange,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName(record),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  bestPerformance(record),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  recordDate(record),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.military_tech_outlined,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 48,
      ),
      child: Column(
        children: [
          Icon(icon, size: 54, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecords = filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Personal Records',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh records',
            onPressed: isLoading ? null : loadRecords,
            icon: const Icon(Icons.refresh),
          ),
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
              const Text(
                'Could not load personal records.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: loadRecords,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadRecords,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'YOUR ACHIEVEMENTS',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Every PR matters.',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Keep your best recorded performances in one place.',
              style: TextStyle(
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D21),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.orange,
                    size: 34,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${records.length}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Saved personal records',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search an exercise...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                  tooltip: 'Clear search',
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
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (records.isEmpty)
              emptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No personal records yet',
                subtitle:
                'Complete and save workouts to build your '
                    'personal record history.',
              )
            else if (visibleRecords.isEmpty)
              emptyState(
                icon: Icons.search_off,
                title: 'No matching exercises',
                subtitle:
                'Try searching with another exercise name.',
              )
            else ...[
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your records',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${visibleRecords.length} exercises',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...visibleRecords.map(recordCard),
              ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
