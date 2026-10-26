class FoodItem {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const FoodItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  // Convert FoodItem to Map (for SQLite later)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  // Create FoodItem from Map (when reading from SQLite later)
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'],
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'FoodItem(name: $name, calories: $calories, protein: $protein, carbs: $carbs, fat: $fat)';
  }
}