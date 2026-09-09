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
