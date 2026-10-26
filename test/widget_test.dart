import 'package:flutter_test/flutter_test.dart';
import 'package:ironlog/main.dart';

void main() {

  test('IronLog app can be created', () {
    expect(
      const IronLogApp(),
      isA<IronLogApp>(),
    );
  });
}