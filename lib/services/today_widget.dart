/// Pure data layer for the Today's Workout / Next Up home widgets.
///
/// No plugins, no global state: everything a card needs is passed in and a
/// plain [TodayCardData] comes out, so it is fully unit-testable.
library;

import '../models/workout.dart';
import '../models/workout_plan.dart';
import 'smart_progression.dart';

const double _lbPerKg = 2.20462;

double _toDisplay(String units, double kg) => units == 'lb' ? kg * _lbPerKg : kg;

String _fmtWeight(double v) {
  final r = (v * 10).round() / 10;
  return r == r.round() ? '${r.round()}' : '$r';
}

/// One exercise row of the Today's Workout widget.
class LiftHintRow {
  const LiftHintRow({
    required this.name,
    required this.repLabel,
    required this.lastReps,
    this.weightLabel,
  });

  final String name;

  /// e.g. '62.5 kg'. Null for reps-only lifts or when there is no history.
  final String? weightLabel;

  /// e.g. '8-10' (or '8' for a single number).
  final String repLabel;
  final int lastReps;
}

/// Everything a home widget needs to render, pre-formatted for the view.
class TodayCardData {
  const TodayCardData({
    required this.live,
    required this.rest,
    required this.dayName,
    required this.streak,
    required this.todaySets,
    required this.lifts,
  });

  final bool live;
  final bool rest;

  /// Plan-day name when a day is shown; null for rest / no-plan.
  final String? dayName;
  final int streak;
  final int todaySets;
  final List<LiftHintRow> lifts;
}

/// The first non-archived plan's day for [now], rotating from Monday.
/// Plans with no days are skipped; returns null when nothing qualifies.
WorkoutPlanDay? planDayForToday(List<WorkoutPlan> plans, DateTime now) {
  final active = plans.where((p) => !p.archived && p.days.isNotEmpty).toList()
    ..sort((a, b) => (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0));
  if (active.isEmpty) return null;
  final plan = active.first;
  final index = (now.weekday - 1) % plan.days.length;
  return plan.days[index];
}

bool trainedToday(List<LoggedSession> sessions, DateTime now) {
  final t = DateTime(now.year, now.month, now.day);
  for (final s in sessions) {
    if (s.date.year == t.year && s.date.month == t.month && s.date.day == t.day) {
      return true;
    }
  }
  return false;
}

List<LiftHintRow> _liftsForDay(
  WorkoutPlanDay day,
  List<LoggedSession> sessions,
  bool Function(String id) isRepsOnly,
  String units,
) {
  final rows = <LiftHintRow>[];
  for (final pe in day.exercises.take(5)) {
    final tMin = pe.reps;
    final tMax = pe.repsMax ?? pe.reps;
    final repLabel = tMin == tMax ? '$tMin' : '$tMin-$tMax';
    if (isRepsOnly(pe.exerciseId)) {
      rows.add(LiftHintRow(name: pe.name, repLabel: repLabel, lastReps: 0));
      continue;
    }
    final last = priorWorkingSets(sessions, pe.exerciseId);
    final display = [
      for (final l in last) LoggedSet(l.reps, _toDisplay(units, l.weight), kind: l.kind),
    ];
    final heaviest = heaviestWorkingSet(display);
    final plate = plateFor(units, heaviest.weight);
    final hint = nextSetHint(
      lastWorkingSets: display,
      targetMin: tMin,
      targetMax: tMax,
      plate: plate,
    );
    rows.add(LiftHintRow(
      name: pe.name,
      repLabel: repLabel,
      lastReps: heaviest.reps,
      weightLabel: hint.suggestedWeight == null
          ? null
          : '${_fmtWeight(hint.suggestedWeight!)} $units',
    ));
  }
  return rows;
}

/// Build the card. [liveDay] is the in-progress plan day of an active
/// session (if any); [plans]/[sessions]/[isRepsOnly]/[units] feed the pure
/// engine. [now] is injectable so tests stay deterministic.
TodayCardData buildTodayCard({
  DateTime? now,
  required List<WorkoutPlan> plans,
  required WorkoutPlanDay? liveDay,
  required List<LoggedSession> sessions,
  required bool Function(String exerciseId) isRepsOnly,
  required String units,
  required int streak,
  required int todaySets,
}) {
  final t0 = now ?? DateTime.now();
  final rest = liveDay == null && trainedToday(sessions, t0);
  final day = liveDay ?? (rest ? null : planDayForToday(plans, t0));
  return TodayCardData(
    live: liveDay != null,
    rest: rest,
    dayName: day?.name,
    streak: streak,
    todaySets: todaySets,
    lifts: day == null ? const [] : _liftsForDay(day, sessions, isRepsOnly, units),
  );
}
