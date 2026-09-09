import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/models/workout.dart';
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

  group('priorWorkingSets', () {
    test('returns only the normal sets of the LATEST session for the exercise', () {
      final sessions = [
        LoggedSession(DateTime(2026, 9, 1), 1000, [
          LoggedExercise('a', 'A', 'chest', [LoggedSet(8, 40)]),
        ]),
        LoggedSession(DateTime(2026, 9, 2), 1000, [
          LoggedExercise('a', 'A', 'chest', [
            LoggedSet(9, 45),
            LoggedSet(8, 42.5, kind: SetKind.warmup),
            LoggedSet(7, 47.5, kind: SetKind.drop),
          ]),
        ]),
      ];
      final sets = priorWorkingSets(sessions, 'a');
      expect(sets.map((s) => s.weight), [45.0], reason: 'solo la sesión más reciente y solo sets normales');
    });

    test('returns empty when the exercise was never logged', () {
      expect(priorWorkingSets([], 'a'), isEmpty);
      expect(priorWorkingSets([LoggedSession(DateTime(2026, 9, 1), 1000, [])], 'a'), isEmpty);
    });
  });

  group('nextSetHint', () {
    test('firstTime when no working sets exist', () {
      final h = nextSetHint(lastWorkingSets: [], targetMin: 8, targetMax: 10, plate: 2.5);
      expect(h.verdict, ProgressionVerdict.firstTime);
      expect(h.hasSuggestion, isFalse);
      expect(h.suggestedWeight, isNull);
    });

    test('bump when every set reached the top of the range', () {
      final h = nextSetHint(
        lastWorkingSets: [LoggedSet(10, 40), LoggedSet(11, 40)],
        targetMin: 8,
        targetMax: 10,
        plate: 2.5,
      );
      expect(h.verdict, ProgressionVerdict.bump);
      expect(h.suggestedWeight, 42.5);
      expect(h.lastBestReps, 11);
    });

    test('reduce when a set fell below the bottom of the range', () {
      final h = nextSetHint(
        lastWorkingSets: [LoggedSet(9, 40), LoggedSet(5, 40)],
        targetMin: 8,
        targetMax: 10,
        plate: 2.5,
      );
      expect(h.verdict, ProgressionVerdict.reduce);
      expect(h.suggestedWeight, 37.5);
    });

    test('reduce never goes below zero', () {
      final h = nextSetHint(
        lastWorkingSets: [LoggedSet(5, 1)],
        targetMin: 8,
        targetMax: 10,
        plate: 2.5,
      );
      expect(h.suggestedWeight, 0);
    });

    test('hold when every set is inside the range but none hit the top', () {
      final h = nextSetHint(
        lastWorkingSets: [LoggedSet(9, 40), LoggedSet(10, 40)],
        targetMin: 8,
        targetMax: 12,
        plate: 2.5,
      );
      expect(h.verdict, ProgressionVerdict.hold);
      expect(h.suggestedWeight, 40, reason: 'mantiene el último peso de trabajo');
      expect(h.lastBestReps, 10);
    });
  });
}
