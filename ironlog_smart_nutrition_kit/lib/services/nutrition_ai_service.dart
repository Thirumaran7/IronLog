import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class NutritionResult {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double calcium;
  final List<String> detectedFoods;

  NutritionResult({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calcium,
    required this.detectedFoods,
  });
}

class _FoodEntry {
  final String id;
  final String name;
  final List<String> aliases;
  final double defaultGrams;
  final Map<String, double> portions;
  final Map<String, double> nutrients;

  const _FoodEntry({
    required this.id,
    required this.name,
    required this.aliases,
    required this.defaultGrams,
    required this.portions,
    required this.nutrients,
  });

  factory _FoodEntry.fromJson(Map<String, dynamic> json) {
    final rawNutrients = json['per100g'] as Map<String, dynamic>;
    final rawPortions = (json['portions'] as Map<String, dynamic>?) ?? {};

    return _FoodEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: (json['aliases'] as List<dynamic>)
          .map((value) => value.toString().toLowerCase())
          .toList(),
      defaultGrams: (json['defaultGrams'] as num?)?.toDouble() ?? 100,
      portions: rawPortions.map(
        (key, value) => MapEntry(key.toLowerCase(), (value as num).toDouble()),
      ),
      nutrients: rawNutrients.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  double nutrient(String key) => nutrients[key] ?? 0;

  double portionGrams(String key, double fallback) => portions[key] ?? fallback;
}

class NutritionAIService {
  static const String _assetPath = 'assets/data/foods.json';
  static const String _indianRecipesAssetPath =
      'assets/data/indian_recipes.json';

  Future<List<_FoodEntry>>? _foodsFuture;

  Future<List<_FoodEntry>> _loadFoods() {
    return _foodsFuture ??= _readFoods();
  }

  Future<List<_FoodEntry>> _readAssetFoods(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final foodList = decoded['foods'] as List<dynamic>;

    return foodList
        .map((item) => _FoodEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<_FoodEntry>> _readFoods() async {
    final existingFoods = await _readAssetFoods(_assetPath);
    final indianRecipes = await _readAssetFoods(_indianRecipesAssetPath);

    // Keep the current generic/bodybuilding foods and add the INDB recipes.
    // Existing foods stay first if the same alias appears in both databases.
    return [...existingFoods, ...indianRecipes];
  }

  Future<NutritionResult> analyze(String input) async {
    final text = input.trim();
    if (text.isEmpty) {
      throw ArgumentError('Please enter a food or meal description.');
    }

    final foods = await _loadFoods();
    final segments = text
        .split(RegExp(r'(?:\r?\n|[,;]+|\s+(?:and|plus)\s+|\s*\+\s*)', caseSensitive: false))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double calcium = 0;
    var recognizedCount = 0;
    final detected = <String>[];
    final seen = <String>{};

    for (final segment in segments) {
      final match = _findFood(segment, foods);

      if (match == null) {
        detected.add('⚠ Not recognized (excluded from totals): $segment');
        continue;
      }

      final quantity = _parseQuantity(segment, match);
      final factor = quantity.grams / 100.0;
      recognizedCount++;
      final key = '${match.id}:${quantity.grams.toStringAsFixed(2)}';

      calories += match.nutrient('calories') * factor;
      protein += match.nutrient('protein') * factor;
      carbs += match.nutrient('carbs') * factor;
      fat += match.nutrient('fat') * factor;
      calcium += match.nutrient('calcium') * factor;

      final description = '${quantity.label} ${match.name}';
      if (seen.add('$key:$description')) {
        detected.add(description);
      }
    }

    if (recognizedCount == 0) {
      throw FormatException(
        'No supported foods were recognized. Try specific ingredients, '
        'for example: 2 eggs, 150g cooked rice, 200g chicken breast.',
      );
    }

    return NutritionResult(
      calories: _round1(calories),
      protein: _round1(protein),
      carbs: _round1(carbs),
      fat: _round1(fat),
      calcium: _round1(calcium),
      detectedFoods: detected,
    );
  }

  _FoodEntry? _findFood(String segment, List<_FoodEntry> foods) {
    // Search aliases from longest to shortest so a specific entry such as
    // "low-fat Greek yogurt" wins over a generic "Greek yogurt" entry.
    final candidates = <({String alias, List<String> words, _FoodEntry food})>[];
    for (final food in foods) {
      for (final rawAlias in [...food.aliases, food.name]) {
        final alias = _normalizeForMatching(rawAlias);
        if (alias.isEmpty) continue;
        candidates.add((alias: alias, words: alias.split(' '), food: food));
      }
    }
    candidates.sort((a, b) => b.alias.length.compareTo(a.alias.length));

    final normalized = _normalizeForMatching(segment);
    // Exact whole-word pass first. This handles punctuation, hyphens, and
    // repeated spaces without creating fuzzy matches unnecessarily.
    for (final candidate in candidates) {
      final pattern = RegExp(
        r'(^|\s)' + RegExp.escape(candidate.alias) + r'(\s|$)',
      );
      if (pattern.hasMatch(normalized)) return candidate.food;
    }

    // Small typo fallback for longer words, e.g. "yogut" -> "yogurt".
    // Words shorter than five letters must match exactly to avoid false hits.
    final inputWords = normalized.split(' ');
    for (final candidate in candidates) {
      if (candidate.words.length > inputWords.length) continue;
      for (var start = 0; start <= inputWords.length - candidate.words.length; start++) {
        var matches = true;
        for (var i = 0; i < candidate.words.length; i++) {
          if (!_sameOrNearWord(inputWords[start + i], candidate.words[i])) {
            matches = false;
            break;
          }
        }
        if (matches) return candidate.food;
      }
    }
    return null;
  }

  String _normalizeForMatching(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  bool _sameOrNearWord(String input, String expected) {
    if (input == expected) return true;
    if (input.length < 5 || expected.length < 5) return false;
    return _editDistanceAtMostOne(input, expected);
  }

  bool _editDistanceAtMostOne(String a, String b) {
    if ((a.length - b.length).abs() > 1) return false;
    var i = 0;
    var j = 0;
    var edits = 0;
    while (i < a.length && j < b.length) {
      if (a.codeUnitAt(i) == b.codeUnitAt(j)) {
        i++;
        j++;
        continue;
      }
      edits++;
      if (edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (b.length > a.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    if (i < a.length || j < b.length) edits++;
    return edits <= 1;
  }

  _ParsedQuantity _parseQuantity(String segment, _FoodEntry food) {
    final expanded = _expandNumberWords(segment.toLowerCase());
    const unitPattern =
        r'(?:millilit(?:er|re)s?|kilograms?|kgs?|kg|grams?|gms?|g|ml|lit(?:er|re)s?|l|tablespoons?|tbsp|teaspoons?|tsp|cups?|slices?|pieces?|piece|pcs?|eggs?|bananas?|apples?|oranges?|idlis?|dosas?|chapatis?|rotis?|plates?|servings?|scoops?|bowls?)';
    const numberPattern = r'(?:\d+\s*/\s*\d+|\d+(?:\.\d+)?)';
    final leadingPattern = RegExp(
      r'^\s*(' + numberPattern + r')\s*(?:(' + unitPattern + r')(?=\s|$))?\s*(?:a\s+)?(?:of\s+)?',
      caseSensitive: false,
    );
    final trailingPattern = RegExp(
      r'(?:^|\s)(' + numberPattern + r')\s*(?:(' + unitPattern + r')(?=\s|$))?\s*$',
      caseSensitive: false,
    );
    final leading = leadingPattern.firstMatch(expanded);
    final trailing = leading == null ? trailingPattern.firstMatch(expanded) : null;
    final match = leading ?? trailing;

    if (match == null) {
      final grams = food.defaultGrams;
      return _ParsedQuantity(grams, '${_format(grams)} g (assumed)');
    }

    final amount = _parseAmount(match.group(1) ?? '1');
    final unit = (match.group(2) ?? '').toLowerCase();
    double grams;
    String label;

    if (unit == 'kg' || unit == 'kgs' || unit.startsWith('kilo')) {
      grams = amount * 1000;
      label = '${_format(amount)} kg';
    } else if (unit == 'g' || unit == 'gm' || unit == 'gms' || unit.startsWith('gram')) {
      grams = amount;
      label = '${_format(amount)} g';
    } else if (unit == 'ml' || unit.startsWith('milliliter') || unit.startsWith('millilitre')) {
      grams = amount; // Approximation for water-like liquids such as milk.
      label = '${_format(amount)} ml';
    } else if (unit == 'l' || unit.startsWith('liter') || unit.startsWith('litre')) {
      grams = amount * 1000;
      label = '${_format(amount)} L';
    } else if (unit == 'tbsp' || unit.startsWith('tablespoon')) {
      grams = amount * food.portionGrams('tbsp', 15);
      label = '${_format(amount)} tbsp';
    } else if (unit == 'tsp' || unit.startsWith('teaspoon')) {
      grams = amount * food.portionGrams('tsp', 5);
      label = '${_format(amount)} tsp';
    } else if (unit == 'cup' || unit == 'cups') {
      grams = amount * food.portionGrams('cup', 240);
      label = '${_format(amount)} cup';
    } else if (unit == 'slice' || unit == 'slices') {
      grams = amount * food.portionGrams('slice', food.portionGrams('piece', food.defaultGrams));
      label = '${_format(amount)} slice';
    } else if (unit == 'plate' || unit == 'plates') {
      grams = amount * food.portionGrams('plate', food.portionGrams('serving', food.defaultGrams));
      label = '${_format(amount)} plate';
    } else if (unit == 'bowl' || unit == 'bowls') {
      grams = amount * food.portionGrams('bowl', food.portionGrams('cup', food.defaultGrams));
      label = '${_format(amount)} bowl';
    } else if (unit == 'scoop' || unit == 'scoops') {
      grams = amount * food.portionGrams('scoop', food.defaultGrams);
      label = '${_format(amount)} scoop';
    } else if (unit.isNotEmpty) {
      // Countable items: eggs, bananas, idlis, dosas, chapatis, etc.
      final portionKey = _countPortionKey(unit);
      grams = amount * food.portionGrams(portionKey, food.portionGrams('piece', food.defaultGrams));
      label = '${_format(amount)} $unit';
    } else if (amount > 10) {
      // If a large number is given without a unit, assume grams.
      grams = amount;
      label = '${_format(amount)} g (assumed)';
    } else {
      // Small values without units are treated as pieces/servings where supported.
      grams = amount * food.portionGrams('piece', food.defaultGrams);
      label = '${_format(amount)} portion';
    }

    // Guard against accidentally nonsensical quantities.
    if (!grams.isFinite || grams <= 0 || grams > 100000) {
      grams = food.defaultGrams;
      label = '${grams.toStringAsFixed(0)} g (assumed)';
    }

    return _ParsedQuantity(grams, label);
  }

  double _parseAmount(String value) {
    final fraction = RegExp(r'^\s*(\d+)\s*/\s*(\d+)\s*$').firstMatch(value);
    if (fraction != null) {
      final denominator = double.tryParse(fraction.group(2)!) ?? 0;
      if (denominator == 0) return 1;
      return (double.tryParse(fraction.group(1)!) ?? 1) / denominator;
    }
    return double.tryParse(value.trim()) ?? 1;
  }

  String _countPortionKey(String unit) {
    if (unit.startsWith('egg')) return 'egg';
    if (unit.startsWith('banana')) return 'banana';
    if (unit.startsWith('apple')) return 'apple';
    if (unit.startsWith('orange')) return 'orange';
    if (unit.startsWith('idli')) return 'idli';
    if (unit.startsWith('dosa')) return 'dosa';
    if (unit.startsWith('chapati')) return 'chapati';
    if (unit.startsWith('roti')) return 'roti';
    if (unit == 'piece' || unit == 'pieces' || unit == 'pcs') return 'piece';
    if (unit == 'serving' || unit == 'servings') return 'serving';
    return 'piece';
  }

  String _expandNumberWords(String input) {
    const replacements = {
      'zero': '0',
      'one': '1',
      'two': '2',
      'three': '3',
      'four': '4',
      'five': '5',
      'six': '6',
      'seven': '7',
      'eight': '8',
      'nine': '9',
      'ten': '10',
      'half': '0.5',
    };
    var result = input;
    replacements.forEach((word, number) {
      result = result.replaceAll(RegExp('\\b$word\\b'), number);
    });
    return result;
  }

  double _round1(double value) => double.parse(value.toStringAsFixed(1));

  String _format(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}

class _ParsedQuantity {
  final double grams;
  final String label;

  const _ParsedQuantity(this.grams, this.label);
}
