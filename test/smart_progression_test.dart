import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/services/smart_progression.dart';

void main() {
  group('plateFor', () {
    test('kg uses 2.5 normally and 1.25 for light lifts', () {
      expect(plateFor('kg', 60), 2.5);
      expect(plateFor('kg', 19.9), 1.25);
    });

    test('kg at threshold (20) uses normal step', () {
      expect(plateFor('kg', 20), 2.5);
    });

    test('lb uses 5.0 normally and 2.5 for light lifts', () {
      expect(plateFor('lb', 100), 5.0);
      expect(plateFor('lb', 44.9), 2.5);
    });

    test('lb at threshold (45) uses normal step', () {
      expect(plateFor('lb', 45), 5.0);
    });
  });

  group('roundUpTo', () {
    test('rounds up to the nearest plate', () {
      expect(roundUpTo(40.0, 2.5), 40.0);
      expect(roundUpTo(41.2, 2.5), 42.5);
      expect(roundUpTo(45.1, 5), 50);
    });
  });

  group('ProgressionHint', () {
    test('firstTime verdict has no suggestion', () {
      const hint = ProgressionHint(
        verdict: ProgressionVerdict.firstTime,
        targetMin: 20,
        targetMax: 25,
      );
      expect(hint.hasSuggestion, isFalse);
      expect(hint.suggestedWeight, isNull);
      expect(hint.lastMaxWeight, isNull);
      expect(hint.lastBestReps, isNull);
    });

    test('bump verdict carries all fields', () {
      const hint = ProgressionHint(
        verdict: ProgressionVerdict.bump,
        targetMin: 30,
        targetMax: 35,
        suggestedWeight: 32.5,
        lastMaxWeight: 30.0,
        lastBestReps: 8,
      );
      expect(hint.hasSuggestion, isTrue);
      expect(hint.suggestedWeight, 32.5);
      expect(hint.lastMaxWeight, 30.0);
      expect(hint.lastBestReps, 8);
    });
  });
}
