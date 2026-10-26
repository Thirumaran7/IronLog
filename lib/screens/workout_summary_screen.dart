import 'package:flutter/material.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final String split;
  final double volume;
  final int prs;
  final int workouts;

  const WorkoutSummaryScreen({
    super.key,
    required this.split,
    required this.volume,
    required this.prs,
    required this.workouts,
  });

  String aiMessage() {
    if (prs > 0) {
      return "Outstanding! You hit $prs new PR${prs > 1 ? "s" : ""} today.";
    }

    if (volume > 5000) {
      return "Great session. Your training volume was high today.";
    }

    return "Solid consistency. Keep progressing next workout.";
  }

  Widget statCard(
      IconData icon,
      String title,
      String value,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Workout Summary"),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D21),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.orange,
                  size: 60,
                ),
                const SizedBox(height: 12),
                Text(
                  "$split Complete!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  aiMessage(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
            children: [
              statCard(
                Icons.fitness_center,
                "Volume",
                "${volume.toStringAsFixed(0)} kg",
                Colors.orange,
              ),
              statCard(
                Icons.emoji_events,
                "PRs",
                "$prs",
                Colors.green,
              ),
              statCard(
                Icons.local_fire_department,
                "Workouts",
                "$workouts",
                Colors.red,
              ),
              statCard(
                Icons.trending_up,
                "Status",
                prs > 0 ? "Progress" : "Consistent",
                Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                padding:
                const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text("Back to Dashboard"),
            ),
          ),
        ],
      ),
    );
  }
}