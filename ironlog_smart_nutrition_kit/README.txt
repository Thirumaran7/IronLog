IRONLOG SMART NUTRITION PARSER UPDATE

This kit contains:
- lib/services/nutrition_ai_service.dart (updated food matching + quantity parser)
- assets/data/foods.json (179 generic/bodybuilding foods, including Greek yogurt aliases)

INSTALL
1. Stop the running IronLog app.
2. Extract this ZIP into the ROOT of your ironlog project folder and allow it to replace files.
   Example root: C:\Users\thiru\StudioProjects\ironlog
3. Do NOT delete or replace assets/data/indian_recipes.json. Keep that file from the earlier INDB setup.
4. Ensure pubspec.yaml lists BOTH assets:
     - assets/data/foods.json
     - assets/data/indian_recipes.json
   Keep the indentation aligned with your existing asset entries. Do not duplicate existing lines.
5. From the project root, run:
     flutter pub get
     flutter analyze
     flutter run

TRY THESE INPUTS IN NUTRITION
- 200g greek yogut
- 200 g Greek yogurt
- Greek yogurt 200g
- two eggs
- 1/2 cup oats
- 200g chicken breast, 100g cooked rice

NOTES
- Quantities without explicit units are still estimated; enter grams when possible.
- ml is treated approximately as grams, which is reasonable for water-like drinks but not exact for every liquid.
- A typo fallback allows at most a one-character edit for words of 5+ letters; short food words must match exactly to reduce false matches.
- INDB-derived recipe data has a redistribution/licensing caveat. Keep it for private/local development until permission to redistribute is confirmed.
