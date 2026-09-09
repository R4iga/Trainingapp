/// Pure decision engine for "Coach": next-set weight suggestions and the
/// Today's Workout / Next Up home widgets. No plugins, no state — everything
/// is passed in and plain values come out.
library;

import 'dart:math' as math;

import '../models/workout.dart';

/// Double-progression verdict for the next working set.
enum ProgressionVerdict { firstTime, bump, reduce, hold }

/// Outcome of [nextSetHint]. All weights are in DISPLAY units (kg or lb as
/// the user sees them) — callers convert with the app's display helpers.
class ProgressionHint {
  const ProgressionHint({
    required this.verdict,
    required this.targetMin,
    required this.targetMax,
    this.suggestedWeight,
    this.lastMaxWeight,
    this.lastBestReps,
  });

  final ProgressionVerdict verdict;
  final int targetMin;
  final int targetMax;

  /// Weight to pre-fill the next set with, in display units. Null on
  /// [ProgressionVerdict.firstTime].
  final double? suggestedWeight;

  /// Heaviest working weight of the last session (display units).
  final double? lastMaxWeight;

  /// Reps of that heaviest set.
  final int? lastBestReps;

  bool get hasSuggestion => verdict != ProgressionVerdict.firstTime;
}

/// Plate increment for a display [weight]. 2.5 kg / 5 lb normally; half that
/// for light lifts (under 20 kg / 45 lb) so early progression stays granular.
double plateFor(String units, double weight) {
  final step = units == 'lb' ? 5.0 : 2.5;
  final light = units == 'lb' ? 45.0 : 20.0;
  return weight < light ? step / 2 : step;
}

/// Round [weight] up to the nearest multiple of [plate].
double roundUpTo(double weight, double plate) => (weight / plate).ceil() * plate;

/// The normal (non warmup/drop/failure) sets of the most recent session that
/// contains [exerciseId]. The caller decides the display-unit scale.
List<LoggedSet> priorWorkingSets(List<LoggedSession> sessions, String exerciseId) {
  final sorted = [...sessions]..sort((a, b) => b.date.compareTo(a.date));
  for (final s in sorted) {
    for (final e in s.exercises) {
      if (e.id == exerciseId) {
        return e.sets.where((s) => s.kind == SetKind.normal).toList();
      }
    }
  }
  return const [];
}

/// Reps/weight of the heaviest working set in [sets] (empty-safe returns 0/0).
({int reps, double weight}) heaviestWorkingSet(List<LoggedSet> sets) {
  var reps = 0, weight = 0.0;
  for (final s in sets) {
    if (s.weight > weight || (s.weight == weight && s.reps > reps)) {
      weight = s.weight;
      reps = s.reps;
    }
  }
  return (reps: reps, weight: weight);
}

/// Double-progression decision for the next working set.
///
/// [lastWorkingSets] are normal working sets from the latest session; the
/// caller supplies a rep [targetMin]..[targetMax] and a [plate] increment.
/// All weights are in display units.
ProgressionHint nextSetHint({
  required List<LoggedSet> lastWorkingSets,
  required int targetMin,
  required int targetMax,
  required double plate,
}) {
  if (lastWorkingSets.isEmpty) {
    return ProgressionHint(
      verdict: ProgressionVerdict.firstTime,
      targetMin: targetMin,
      targetMax: targetMax,
    );
  }

  final heaviest = heaviestWorkingSet(lastWorkingSets);
  final everyAtTarget = lastWorkingSets.every((s) => s.reps >= targetMax);
  final anyMissed = lastWorkingSets.any((s) => s.reps < targetMin);

  if (everyAtTarget) {
    return ProgressionHint(
      verdict: ProgressionVerdict.bump,
      targetMin: targetMin,
      targetMax: targetMax,
      suggestedWeight: roundUpTo(heaviest.weight + plate, plate),
      lastMaxWeight: heaviest.weight,
      lastBestReps: heaviest.reps,
    );
  }
  if (anyMissed) {
    return ProgressionHint(
      verdict: ProgressionVerdict.reduce,
      targetMin: targetMin,
      targetMax: targetMax,
      suggestedWeight: math.max(0.0, roundUpTo(heaviest.weight - plate, plate)),
      lastMaxWeight: heaviest.weight,
      lastBestReps: heaviest.reps,
    );
  }
  return ProgressionHint(
    verdict: ProgressionVerdict.hold,
    targetMin: targetMin,
    targetMax: targetMax,
    suggestedWeight: heaviest.weight,
    lastMaxWeight: heaviest.weight,
    lastBestReps: heaviest.reps,
  );
}
