import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/services/smart_progression.dart';

void main() {
  group('plateFor', () {
    test('kg uses 2.5 normally and 1.25 for light lifts', () {
      expect(plateFor('kg', 60), 2.5);
      expect(plateFor('kg', 19.9), 1.25);
    });

    test('lb uses 5.0 normally and 2.5 for light lifts', () {
      expect(plateFor('lb', 100), 5.0);
      expect(plateFor('lb', 44.9), 2.5);
    });
  });

  group('roundUpTo', () {
    test('rounds up to the nearest plate', () {
      expect(roundUpTo(40.0, 2.5), 40.0);
      expect(roundUpTo(41.2, 2.5), 42.5);
      expect(roundUpTo(45.1, 5), 50);
    });
  });
}
