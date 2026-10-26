import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

String _localDayKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();

  DatabaseService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ironlog.db');

    return openDatabase(
      path,
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE workouts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            split TEXT,
            date TEXT,
            localDate TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE exercise_sets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workoutId INTEGER,
            exercise TEXT,
            setNumber INTEGER,
            weight REAL,
            reps INTEGER,
            completed INTEGER,
            recordType TEXT NOT NULL DEFAULT 'load_reps'
          )
        ''');

        await db.execute('''
          CREATE TABLE prs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            exercise TEXT UNIQUE,
            weight REAL,
            reps INTEGER,
            date TEXT,
            recordType TEXT NOT NULL DEFAULT 'load_reps'
          )
        ''');

        await db.execute('''
          CREATE TABLE body_weight(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            weight REAL,
            date TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE progress_photos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT,
            date TEXT,
            note TEXT
          )
        ''');

        await _createMealLogsTable(db);
        await _createNutritionGoalsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE progress_photos(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              imagePath TEXT,
              date TEXT,
              note TEXT
            )
          ''');
        }

        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE workouts ADD COLUMN localDate TEXT',
          );

          final rows = await db.query(
            'workouts',
            columns: ['id', 'date'],
          );

          for (final row in rows) {
            final rawDate = row['date']?.toString();
            if (rawDate == null) continue;

            final parsed = DateTime.tryParse(rawDate);
            if (parsed == null) continue;

            await db.update(
              'workouts',
              {'localDate': _localDayKey(parsed.toLocal())},
              where: 'id = ?',
              whereArgs: [row['id']],
            );
          }
        }

        if (oldVersion < 4) {
          await db.execute('''
            ALTER TABLE prs
            ADD COLUMN recordType TEXT NOT NULL DEFAULT 'load_reps'
          ''');
        }

        if (oldVersion < 5) {
          await db.execute('''
            ALTER TABLE exercise_sets
            ADD COLUMN recordType TEXT NOT NULL DEFAULT 'load_reps'
          ''');
        }

        if (oldVersion < 6) {
          await _createMealLogsTable(db);
        }

        if (oldVersion < 7) {
          await _ensureMealNutrientColumns(db);
        }

        if (oldVersion < 8) {
          await _createNutritionGoalsTable(db);
        }
      },
    );
  }

  /// Stores one editable daily target row. Starter targets are defaults only;
  /// users can personalize them from the Nutrition screen.
  Future<void> _createNutritionGoalsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS nutrition_goals(
        id INTEGER PRIMARY KEY CHECK(id = 1),
        calories REAL NOT NULL DEFAULT 2500,
        protein REAL NOT NULL DEFAULT 150,
        carbs REAL NOT NULL DEFAULT 300,
        fat REAL NOT NULL DEFAULT 70,
        fiber REAL NOT NULL DEFAULT 30,
        updatedAt TEXT
      )
    ''');

    await db.insert(
      'nutrition_goals',
      {
        'id': 1,
        'calories': 2500.0,
        'protein': 150.0,
        'carbs': 300.0,
        'fat': 70.0,
        'fiber': 30.0,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Map<String, dynamic>> getNutritionGoals() async {
    final db = await database;
    final rows = await db.query(
      'nutrition_goals',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      return Map<String, dynamic>.from(rows.first);
    }

    // Defensive fallback if a database was interrupted during creation.
    await _createNutritionGoalsTable(db);
    final fallback = await db.query(
      'nutrition_goals',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    return Map<String, dynamic>.from(fallback.first);
  }

  Future<void> updateNutritionGoals({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
  }) async {
    final values = [calories, protein, carbs, fat, fiber];
    if (values.any((value) => !value.isFinite || value <= 0)) {
      throw ArgumentError('Nutrition goals must be positive finite values.');
    }

    final db = await database;
    await _createNutritionGoalsTable(db);
    await db.update(
      'nutrition_goals',
      {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> _createMealLogsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE meal_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        foodText TEXT NOT NULL,
        mealType TEXT NOT NULL DEFAULT 'Meal',
        calories REAL NOT NULL DEFAULT 0,
        protein REAL NOT NULL DEFAULT 0,
        carbs REAL NOT NULL DEFAULT 0,
        fat REAL NOT NULL DEFAULT 0,
        calcium REAL NOT NULL DEFAULT 0,
        fiber REAL NOT NULL DEFAULT 0,
        sodium REAL NOT NULL DEFAULT 0,
        potassium REAL NOT NULL DEFAULT 0,
        iron REAL NOT NULL DEFAULT 0,
        magnesium REAL NOT NULL DEFAULT 0,
        zinc REAL NOT NULL DEFAULT 0,
        phosphorus REAL NOT NULL DEFAULT 0,
        vitaminC REAL NOT NULL DEFAULT 0,
        vitaminA REAL NOT NULL DEFAULT 0,
        folate REAL NOT NULL DEFAULT 0,
        vitaminE REAL NOT NULL DEFAULT 0,
        vitaminB1 REAL NOT NULL DEFAULT 0,
        vitaminB2 REAL NOT NULL DEFAULT 0,
        vitaminB3 REAL NOT NULL DEFAULT 0,
        vitaminB6 REAL NOT NULL DEFAULT 0,
        detectedFoods TEXT NOT NULL DEFAULT '[]',
        date TEXT NOT NULL,
        localDate TEXT NOT NULL
      )
    ''');
  }

  /// Adds nutrient columns to an existing version-6 database without deleting
  /// any previously saved meal, workout, set, PR, weight, or photo records.
  Future<void> _ensureMealNutrientColumns(DatabaseExecutor db) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info(meal_logs)');
    final existingColumns = tableInfo
        .map((row) => row['name']?.toString())
        .whereType<String>()
        .toSet();

    const nutrientColumns = <String, String>{
      'fiber': 'REAL NOT NULL DEFAULT 0',
      'sodium': 'REAL NOT NULL DEFAULT 0',
      'potassium': 'REAL NOT NULL DEFAULT 0',
      'iron': 'REAL NOT NULL DEFAULT 0',
      'magnesium': 'REAL NOT NULL DEFAULT 0',
      'zinc': 'REAL NOT NULL DEFAULT 0',
      'phosphorus': 'REAL NOT NULL DEFAULT 0',
      'vitaminC': 'REAL NOT NULL DEFAULT 0',
      'vitaminA': 'REAL NOT NULL DEFAULT 0',
      'folate': 'REAL NOT NULL DEFAULT 0',
      'vitaminE': 'REAL NOT NULL DEFAULT 0',
      'vitaminB1': 'REAL NOT NULL DEFAULT 0',
      'vitaminB2': 'REAL NOT NULL DEFAULT 0',
      'vitaminB3': 'REAL NOT NULL DEFAULT 0',
      'vitaminB6': 'REAL NOT NULL DEFAULT 0',
    };

    for (final entry in nutrientColumns.entries) {
      if (existingColumns.contains(entry.key)) continue;
      await db.execute(
        'ALTER TABLE meal_logs ADD COLUMN ${entry.key} ${entry.value}',
      );
    }
  }

  // --------------------------------------------------
  // WORKOUTS
  // --------------------------------------------------

  Future<int> insertWorkout(String split) async {
    final db = await database;
    final now = DateTime.now();

    return db.insert('workouts', {
      'split': split,
      'date': now.toUtc().toIso8601String(),
      'localDate': _localDayKey(now),
    });
  }

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    final db = await database;

    return db.query(
      'workouts',
      orderBy: 'date DESC',
    );
  }

  Future<int> getWorkoutCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM workouts',
    );

    return (result.first['count'] as num).toInt();
  }

  Future<List<Map<String, dynamic>>> getWeeklyWorkouts() async {
    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final monday = today.subtract(
      Duration(days: today.weekday - 1),
    );
    final nextMonday = monday.add(const Duration(days: 7));

    return db.rawQuery(
      '''
      SELECT localDate AS day, COUNT(*) AS count
      FROM workouts
      WHERE localDate >= ? AND localDate < ?
      GROUP BY localDate
      ORDER BY localDate ASC
      ''',
      [
        _localDayKey(monday),
        _localDayKey(nextMonday),
      ],
    );
  }

  // --------------------------------------------------
  // EXERCISE SETS
  // --------------------------------------------------

  Future<void> insertExerciseSet({
    required int workoutId,
    required String exercise,
    required int setNumber,
    required double weight,
    required int reps,
    required bool completed,
    String recordType = 'load_reps',
  }) async {
    final db = await database;

    await db.insert('exercise_sets', {
      'workoutId': workoutId,
      'exercise': exercise,
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'completed': completed ? 1 : 0,
      'recordType': recordType,
    });
  }

  Future<List<Map<String, dynamic>>> getLastExerciseSets(
      String exercise,
      ) async {
    final db = await database;

    return db.query(
      'exercise_sets',
      where: 'exercise = ?',
      whereArgs: [exercise],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPreviousWorkoutSets(
      String exercise,
      ) async {
    final db = await database;

    return db.rawQuery(
      '''
      SELECT
        es.exercise,
        es.weight,
        es.reps,
        es.setNumber,
        es.completed,
        es.recordType,
        es.workoutId,
        w.date,
        w.localDate
      FROM exercise_sets es
      INNER JOIN workouts w ON es.workoutId = w.id
      WHERE es.exercise = ?
      ORDER BY w.date ASC, es.setNumber ASC
      ''',
      [exercise],
    );
  }

  // --------------------------------------------------
  // PERSONAL RECORDS
  // --------------------------------------------------

  Future<Map<String, dynamic>?> getPR(String exercise) async {
    final db = await database;

    final result = await db.query(
      'prs',
      where: 'exercise = ?',
      whereArgs: [exercise],
      limit: 1,
    );

    return result.isEmpty ? null : result.first;
  }

  Future<void> savePR({
    required String exercise,
    required double weight,
    required int reps,
    String recordType = 'load_reps',
  }) async {
    final db = await database;

    await db.insert(
      'prs',
      {
        'exercise': exercise,
        'weight': weight,
        'reps': reps,
        'date': DateTime.now().toUtc().toIso8601String(),
        'recordType': recordType,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getPRCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM prs',
    );

    return (result.first['count'] as num).toInt();
  }

  // --------------------------------------------------
  // NUTRITION: SAVE MEALS
  // --------------------------------------------------

  Future<int> insertMealLog({
    required String foodText,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required double calcium,
    double fiber = 0,
    double sodium = 0,
    double potassium = 0,
    double iron = 0,
    double magnesium = 0,
    double zinc = 0,
    double phosphorus = 0,
    double vitaminC = 0,
    double vitaminA = 0,
    double folate = 0,
    double vitaminE = 0,
    double vitaminB1 = 0,
    double vitaminB2 = 0,
    double vitaminB3 = 0,
    double vitaminB6 = 0,
    required List<String> detectedFoods,
    String mealType = 'Meal',
  }) async {
    final db = await database;
    final now = DateTime.now();

    return db.insert('meal_logs', {
      'foodText': foodText.trim(),
      'mealType': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'calcium': calcium,
      'fiber': fiber,
      'sodium': sodium,
      'potassium': potassium,
      'iron': iron,
      'magnesium': magnesium,
      'zinc': zinc,
      'phosphorus': phosphorus,
      'vitaminC': vitaminC,
      'vitaminA': vitaminA,
      'folate': folate,
      'vitaminE': vitaminE,
      'vitaminB1': vitaminB1,
      'vitaminB2': vitaminB2,
      'vitaminB3': vitaminB3,
      'vitaminB6': vitaminB6,
      'detectedFoods': jsonEncode(detectedFoods),
      'date': now.toUtc().toIso8601String(),
      'localDate': _localDayKey(now),
    });
  }

  Future<List<Map<String, dynamic>>> getMealsForDate(
      DateTime date,
      ) async {
    final db = await database;

    final localDate = _localDayKey(date);

    return db.query(
      'meal_logs',
      where: 'localDate = ?',
      whereArgs: [localDate],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getRecentMeals({
    int limit = 50,
  }) async {
    final db = await database;

    return db.query(
      'meal_logs',
      orderBy: 'date DESC',
      limit: limit,
    );
  }

  Future<Map<String, dynamic>> getDailyNutrition(
      DateTime date,
      ) async {
    final db = await database;
    final localDate = _localDayKey(date);

    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS mealCount,
        COALESCE(SUM(calories), 0) AS calories,
        COALESCE(SUM(protein), 0) AS protein,
        COALESCE(SUM(carbs), 0) AS carbs,
        COALESCE(SUM(fat), 0) AS fat,
        COALESCE(SUM(calcium), 0) AS calcium,
        COALESCE(SUM(fiber), 0) AS fiber,
        COALESCE(SUM(sodium), 0) AS sodium,
        COALESCE(SUM(potassium), 0) AS potassium,
        COALESCE(SUM(iron), 0) AS iron,
        COALESCE(SUM(magnesium), 0) AS magnesium,
        COALESCE(SUM(zinc), 0) AS zinc,
        COALESCE(SUM(phosphorus), 0) AS phosphorus,
        COALESCE(SUM(vitaminC), 0) AS vitaminC,
        COALESCE(SUM(vitaminA), 0) AS vitaminA,
        COALESCE(SUM(folate), 0) AS folate,
        COALESCE(SUM(vitaminE), 0) AS vitaminE,
        COALESCE(SUM(vitaminB1), 0) AS vitaminB1,
        COALESCE(SUM(vitaminB2), 0) AS vitaminB2,
        COALESCE(SUM(vitaminB3), 0) AS vitaminB3,
        COALESCE(SUM(vitaminB6), 0) AS vitaminB6
      FROM meal_logs
      WHERE localDate = ?
      ''',
      [localDate],
    );

    return result.first;
  }

  Future<int> deleteMealLog(int id) async {
    final db = await database;

    return db.delete(
      'meal_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --------------------------------------------------
  // LEGACY TABLES PRESERVED
  // --------------------------------------------------

  Future<void> insertBodyWeight(double weight) async {
    final db = await database;

    await db.insert('body_weight', {
      'weight': weight,
      'date': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getBodyWeights() async {
    final db = await database;

    return db.query(
      'body_weight',
      orderBy: 'date ASC',
    );
  }

  Future<double?> getLatestWeight() async {
    final db = await database;

    final result = await db.query(
      'body_weight',
      orderBy: 'date DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return (result.first['weight'] as num).toDouble();
  }

  Future<void> insertProgressPhoto({
    required String imagePath,
    String note = '',
  }) async {
    final db = await database;

    await db.insert('progress_photos', {
      'imagePath': imagePath,
      'date': DateTime.now().toUtc().toIso8601String(),
      'note': note,
    });
  }

  Future<List<Map<String, dynamic>>> getProgressPhotos() async {
    final db = await database;

    return db.query(
      'progress_photos',
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllExerciseProgress() async {
    final db = await database;

    // Detect the exercise-name column without changing the database.
    final tableInfo = await db.rawQuery(
      'PRAGMA table_info(exercise_sets)',
    );

    final columns = tableInfo
        .map((row) => row['name']?.toString())
        .whereType<String>()
        .toSet();

    const candidates = [
      'exercise',
      'exerciseName',
      'exercise_name',
    ];

    final exerciseColumn = candidates.firstWhere(
          (column) => columns.contains(column),
      orElse: () => '',
    );

    if (exerciseColumn.isEmpty) {
      throw StateError(
        'Could not find the exercise-name column in exercise_sets.',
      );
    }

    final rows = await db.rawQuery('''
    SELECT
      es.$exerciseColumn AS exerciseName,
      w.id AS workoutId,
      w.split AS workoutName,
      COALESCE(NULLIF(w.localDate, ''), w.date) AS workoutDate,
      COALESCE(es.recordType, 'load_reps') AS recordType,

      COUNT(
        CASE WHEN es.completed = 1 THEN 1 END
      ) AS completedSets,

      MAX(
        CASE
          WHEN es.completed = 1
            AND COALESCE(es.recordType, 'load_reps') = 'load_reps'
          THEN es.weight
        END
      ) AS bestWeight,

      MAX(
        CASE WHEN es.completed = 1 THEN es.reps END
      ) AS bestAmount,

      SUM(
        CASE
          WHEN es.completed = 1
            AND COALESCE(es.recordType, 'load_reps') = 'load_reps'
          THEN es.weight * es.reps
          ELSE 0
        END
      ) AS volume

    FROM exercise_sets es
    INNER JOIN workouts w ON es.workoutId = w.id

    GROUP BY
      es.$exerciseColumn,
      w.id,
      w.split,
      w.localDate,
      w.date,
      es.recordType

    HAVING COUNT(
      CASE WHEN es.completed = 1 THEN 1 END
    ) > 0

    ORDER BY workoutDate DESC
  ''');

    return rows;
  }

  Future<List<Map<String, dynamic>>> getExerciseProgressForCycle(
      int cycleId,
      ) async {
    final db = await database;

    await _ensureTrainingCycleTables(db);

    // Detect the exercise-name column used by this database.
    final tableInfo = await db.rawQuery(
      'PRAGMA table_info(exercise_sets)',
    );

    final columns = tableInfo
        .map((row) => row['name']?.toString())
        .whereType<String>()
        .toSet();

    const candidates = [
      'exercise',
      'exerciseName',
      'exercise_name',
    ];

    final exerciseColumn = candidates.firstWhere(
          (column) => columns.contains(column),
      orElse: () => '',
    );

    if (exerciseColumn.isEmpty) {
      throw StateError(
        'Could not find the exercise-name column in exercise_sets.',
      );
    }

    final rows = await db.rawQuery('''
    SELECT
      es.$exerciseColumn AS exerciseName,
      w.id AS workoutId,
      w.split AS workoutName,
      COALESCE(NULLIF(w.localDate, ''), w.date) AS workoutDate,
      COALESCE(es.recordType, 'load_reps') AS recordType,

      COUNT(
        CASE WHEN es.completed = 1 THEN 1 END
      ) AS completedSets,

      MAX(
        CASE
          WHEN es.completed = 1
            AND COALESCE(es.recordType, 'load_reps') = 'load_reps'
          THEN es.weight
        END
      ) AS bestWeight,

      MAX(
        CASE WHEN es.completed = 1 THEN es.reps END
      ) AS bestAmount,

      SUM(
        CASE
          WHEN es.completed = 1
            AND COALESCE(es.recordType, 'load_reps') = 'load_reps'
          THEN es.weight * es.reps
          ELSE 0
        END
      ) AS volume

    FROM exercise_sets es
    INNER JOIN workouts w
      ON es.workoutId = w.id
    INNER JOIN workout_cycle_sessions m
      ON m.workoutId = w.id

    WHERE m.cycleId = ?

    GROUP BY
      es.$exerciseColumn,
      w.id,
      w.split,
      w.localDate,
      w.date,
      es.recordType

    HAVING COUNT(
      CASE WHEN es.completed = 1 THEN 1 END
    ) > 0

    ORDER BY workoutDate DESC
  ''', [cycleId]);

    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }


  Future<List<Map<String, dynamic>>> getAllPersonalRecords() async {
    final db = await database;

    final tableInfo = await db.rawQuery(
      'PRAGMA table_info(prs)',
    );

    if (tableInfo.isEmpty) {
      throw StateError(
        'The personal records table (prs) was not found.',
      );
    }

    // Read saved records without changing existing data.
    return db.query('prs');
  }

  Future<void> _ensureTrainingCycleTables(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS training_cycles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      startedAt TEXT NOT NULL,
      isActive INTEGER NOT NULL DEFAULT 0
    )
  ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS workout_cycle_sessions (
      workoutId INTEGER PRIMARY KEY,
      cycleId INTEGER NOT NULL,
      FOREIGN KEY (workoutId) REFERENCES workouts(id),
      FOREIGN KEY (cycleId) REFERENCES training_cycles(id)
    )
  ''');

    final cycles = await db.query(
      'training_cycles',
      orderBy: 'id ASC',
    );

    int activeCycleId;

    if (cycles.isEmpty) {
      // Preserve all existing workouts in the initial cycle.
      activeCycleId = await db.insert('training_cycles', {
        'name': 'Cycle 1',
        'startedAt': DateTime.now().toIso8601String(),
        'isActive': 1,
      });
    } else {
      final activeCycles = await db.query(
        'training_cycles',
        where: 'isActive = ?',
        whereArgs: [1],
        orderBy: 'id DESC',
        limit: 1,
      );

      if (activeCycles.isNotEmpty) {
        activeCycleId = (activeCycles.first['id'] as num).toInt();
      } else {
        activeCycleId = (cycles.last['id'] as num).toInt();

        await db.update(
          'training_cycles',
          {'isActive': 0},
        );

        await db.update(
          'training_cycles',
          {'isActive': 1},
          where: 'id = ?',
          whereArgs: [activeCycleId],
        );
      }
    }

    // Assign previously unassigned workouts to the active cycle.
    // Existing cycle assignments are never overwritten here.
    await db.rawInsert('''
    INSERT OR IGNORE INTO workout_cycle_sessions
      (workoutId, cycleId)
    SELECT w.id, ?
    FROM workouts w
    LEFT JOIN workout_cycle_sessions m
      ON m.workoutId = w.id
    WHERE m.workoutId IS NULL
  ''', [activeCycleId]);
  }

  Future<List<Map<String, dynamic>>> getTrainingCycles() async {
    final db = await database;
    await _ensureTrainingCycleTables(db);

    final rows = await db.rawQuery('''
    SELECT
      c.id,
      c.name,
      c.startedAt,
      c.isActive,
      COUNT(m.workoutId) AS workoutCount
    FROM training_cycles c
    LEFT JOIN workout_cycle_sessions m
      ON m.cycleId = c.id
    GROUP BY c.id, c.name, c.startedAt, c.isActive
    ORDER BY c.id DESC
  ''');

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<Map<String, dynamic>> getActiveTrainingCycle() async {
    final db = await database;
    await _ensureTrainingCycleTables(db);

    final rows = await db.query(
      'training_cycles',
      where: 'isActive = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw StateError('No active workout cycle was found.');
    }

    return Map<String, dynamic>.from(rows.first);
  }

  Future<int> createTrainingCycle(String name) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('Enter a name for the new cycle.');
    }

    final db = await database;
    await _ensureTrainingCycleTables(db);

    return db.transaction((txn) async {
      await txn.update(
        'training_cycles',
        {'isActive': 0},
      );

      return txn.insert('training_cycles', {
        'name': cleanName,
        'startedAt': DateTime.now().toIso8601String(),
        'isActive': 1,
      });
    });
  }

  Future<void> assignWorkoutToCycle({
    required int workoutId,
    required int cycleId,
  }) async {
    final db = await database;
    await _ensureTrainingCycleTables(db);

    final existingCycle = await db.query(
      'training_cycles',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [cycleId],
      limit: 1,
    );

    if (existingCycle.isEmpty) {
      throw ArgumentError('The selected workout cycle does not exist.');
    }

    await db.insert(
      'workout_cycle_sessions',
      {
        'workoutId': workoutId,
        'cycleId': cycleId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getWorkoutsForCycle(
      int cycleId,
      ) async {
    final db = await database;
    await _ensureTrainingCycleTables(db);

    final rows = await db.rawQuery('''
    SELECT w.*
    FROM workouts w
    INNER JOIN workout_cycle_sessions m
      ON m.workoutId = w.id
    WHERE m.cycleId = ?
    ORDER BY COALESCE(NULLIF(w.localDate, ''), w.date) DESC
  ''', [cycleId]);

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> setActiveTrainingCycle(int cycleId) async {
    final db = await database;
    await _ensureTrainingCycleTables(db);

    await db.transaction((txn) async {
      final cycle = await txn.query(
        'training_cycles',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [cycleId],
        limit: 1,
      );

      if (cycle.isEmpty) {
        throw ArgumentError('Workout cycle not found.');
      }

      await txn.update(
        'training_cycles',
        {'isActive': 0},
      );

      await txn.update(
        'training_cycles',
        {'isActive': 1},
        where: 'id = ?',
        whereArgs: [cycleId],
      );
    });
  }

}
