
import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/progress_screen.dart';

void main() {
  runApp(const IronLogApp());
}

class IronLogApp extends StatelessWidget {
  const IronLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IronLog',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101114),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  int dashboardVersion = 0;

  void openTab(int index) {
    setState(() {
      // Refresh Home whenever the user returns from another tab.
      if (index == 0 && currentIndex != 0) {
        dashboardVersion++;
      }

      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(
        key: ValueKey('dashboard-$dashboardVersion'),
        onBuildWorkout: () => openTab(1),
        onOpenNutrition: () => openTab(2),
      ),
      const WorkoutScreen(),
      const NutritionScreen(),
      const ProgressScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: const Color(0xFF1A1D21),
        indicatorColor: Colors.orange.withValues(alpha: 0.22),
        onDestinationSelected: openTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Nutrition',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
