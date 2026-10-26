import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class NutritionResult {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double calcium;
  final double fiber;
  final double sodium;
  final double potassium;
  final double iron;
  final double magnesium;
  final double zinc;
  final double phosphorus;
  final double vitaminC;
  final double vitaminA;
  final double folate;
  final double vitaminE;
  final double vitaminB1;
  final double vitaminB2;
  final double vitaminB3;
  final double vitaminB6;
  final List<String> detectedFoods;
  /// Nutrient keys for which at least one recognized food lacked usable data.
  final Set<String> incompleteNutrients;

  NutritionResult({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calcium,
    this.fiber = 0,
    this.sodium = 0,
    this.potassium = 0,
    this.iron = 0,
    this.magnesium = 0,
    this.zinc = 0,
    this.phosphorus = 0,
    this.vitaminC = 0,
    this.vitaminA = 0,
    this.folate = 0,
    this.vitaminE = 0,
    this.vitaminB1 = 0,
    this.vitaminB2 = 0,
    this.vitaminB3 = 0,
    this.vitaminB6 = 0,
    required this.detectedFoods,
    this.incompleteNutrients = const <String>{},
  });
}

class _FoodEntry {
  final String id;
  final String name;
  final List<String> aliases;
  final double defaultGrams;
  final Map<String, double> portions;
  final Map<String, double> nutrients;
  final Map<String, String> nutrientStatus;

  const _FoodEntry({
    required this.id,
    required this.name,
    required this.aliases,
    required this.defaultGrams,
    required this.portions,
    required this.nutrients,
    required this.nutrientStatus,
  });

  factory _FoodEntry.fromJson(Map<String, dynamic> json) {
    final rawNutrients = json['per100g'] as Map<String, dynamic>;
    final rawPortions = (json['portions'] as Map<String, dynamic>?) ?? {};
    final Map<String, dynamic> rawStatus =
        json['nutrientStatus'] as Map<String, dynamic>? ?? <String, dynamic>{};

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
      nutrientStatus: rawStatus.map<String, String>(
        (key, value) => MapEntry<String, String>(key, value.toString()),
      ),
    );
  }

  bool nutrientDataAvailable(String key) {
    final status = nutrientStatus[key];
    if (status != null) return status != 'unknown';
    // Older recipe records do not carry nutrientStatus; treat a nonzero value
    // from their normalized key or an equivalent source key as available.
    return nutrient(key) != 0;
  }

  double nutrient(String key) {
    final direct = nutrients[key];
    if (direct != null && direct != 0) return direct;

    // INDB uses source-specific nutrient names as well as the normalized
    // keys used in foods.json. Fall back to equivalent names when necessary.
    const aliases = <String, List<String>>{
      'calories': ['energy_kcal'],
      'protein': ['protein_g'],
      'carbs': ['carb_g'],
      'fat': ['fat_g'],
      'fiber': ['fibre', 'fibre_g', 'fiber_g'],
      'calcium': ['calcium_mg'],
      'sodium': ['sodium_mg'],
      'potassium': ['potassium_mg'],
      'iron': ['iron_mg'],
      'magnesium': ['magnesium_mg'],
      'zinc': ['zinc_mg'],
      'phosphorus': ['phosphorus_mg'],
      'vitaminC': ['vitc_mg', 'vitamin_c_mg'],
      'vitaminA': ['vita_ug', 'vitamin_a_ug'],
      'folate': ['folate_ug', 'vitb9_ug'],
      'vitaminE': ['vite_mg', 'vitamin_e_mg'],
      'vitaminB1': ['vitb1_mg'],
      'vitaminB2': ['vitb2_mg'],
      'vitaminB3': ['vitb3_mg'],
      'vitaminB6': ['vitb6_mg'],
    };
    for (final alias in aliases[key] ?? const <String>[]) {
      final value = nutrients[alias];
      if (value != null && value != 0) return value;
    }
    return direct ?? 0;
  }

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
    double fiber = 0;
    double sodium = 0;
    double potassium = 0;
    double iron = 0;
    double magnesium = 0;
    double zinc = 0;
    double phosphorus = 0;
    double vitaminC = 0;
    double vitaminA = 0;
    double folate = 0;
    double vitaminE = 0;
    double vitaminB1 = 0;
    double vitaminB2 = 0;
    double vitaminB3 = 0;
    double vitaminB6 = 0;
    var recognizedCount = 0;
    final detected = <String>[];
    final seen = <String>{};
    final incompleteNutrients = <String>{};
    const trackedMicronutrients = <String>[
      'calcium', 'iron', 'sodium', 'potassium', 'magnesium', 'zinc',
      'phosphorus', 'vitaminC', 'vitaminA', 'vitaminE', 'vitaminB1',
      'vitaminB2', 'vitaminB3', 'vitaminB6', 'folate',
    ];

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
      for (final nutrientKey in trackedMicronutrients) {
        if (!match.nutrientDataAvailable(nutrientKey)) {
          incompleteNutrients.add(nutrientKey);
        }
      }

      calories += match.nutrient('calories') * factor;
      protein += match.nutrient('protein') * factor;
      carbs += match.nutrient('carbs') * factor;
      fat += match.nutrient('fat') * factor;
      calcium += match.nutrient('calcium') * factor;
      fiber += match.nutrient('fiber') * factor;
      sodium += match.nutrient('sodium') * factor;
      potassium += match.nutrient('potassium') * factor;
      iron += match.nutrient('iron') * factor;
      magnesium += match.nutrient('magnesium') * factor;
      zinc += match.nutrient('zinc') * factor;
      phosphorus += match.nutrient('phosphorus') * factor;
      vitaminC += match.nutrient('vitaminC') * factor;
      vitaminA += match.nutrient('vitaminA') * factor;
      folate += match.nutrient('folate') * factor;
      vitaminE += match.nutrient('vitaminE') * factor;
      vitaminB1 += match.nutrient('vitaminB1') * factor;
      vitaminB2 += match.nutrient('vitaminB2') * factor;
      vitaminB3 += match.nutrient('vitaminB3') * factor;
      vitaminB6 += match.nutrient('vitaminB6') * factor;

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
      calcium: _round3(calcium),
      fiber: _round1(fiber),
      sodium: _round3(sodium),
      potassium: _round3(potassium),
      iron: _round3(iron),
      magnesium: _round3(magnesium),
      zinc: _round3(zinc),
      phosphorus: _round3(phosphorus),
      vitaminC: _round3(vitaminC),
      vitaminA: _round3(vitaminA),
      folate: _round3(folate),
      vitaminE: _round3(vitaminE),
      vitaminB1: _round3(vitaminB1),
      vitaminB2: _round3(vitaminB2),
      vitaminB3: _round3(vitaminB3),
      vitaminB6: _round3(vitaminB6),
      detectedFoods: detected,
      incompleteNutrients: incompleteNutrients,
    );
  }

  _FoodEntry? _findFood(String segment, List<_FoodEntry> foods) {
    // Search aliases from longest to shortest so a specific entry such as
    // "low-fat Greek yogurt" wins over a generic "Greek yogurt" entry.
    final candidates =
        <({String alias, List<String> words, _FoodEntry food, int foodIndex})>[];
    for (var foodIndex = 0; foodIndex < foods.length; foodIndex++) {
      final food = foods[foodIndex];
      for (final rawAlias in [...food.aliases, food.name]) {
        final alias = _normalizeForMatching(rawAlias);
        if (alias.isEmpty) continue;
        candidates.add((
          alias: alias,
          words: alias.split(' '),
          food: food,
          foodIndex: foodIndex,
        ));
      }
    }
    // Prefer longer, more specific aliases. For equal-length collisions, keep
    // the earlier food first (the generic foods.json catalogue precedes the
    // imported recipes). Use list position rather than ID because IDs can repeat
    // across the two catalogues.
    candidates.sort((a, b) {
      final byLength = b.alias.length.compareTo(a.alias.length);
      if (byLength != 0) return byLength;
      return a.foodIndex.compareTo(b.foodIndex);
    });

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
  // Preserve small micronutrient values such as banana vitamin B1 (0.031 mg).
  double _round3(double value) => double.parse(value.toStringAsFixed(3));

  String _format(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}

class _ParsedQuantity {
  final double grams;
  final String label;

  const _ParsedQuantity(this.grams, this.label);
}
