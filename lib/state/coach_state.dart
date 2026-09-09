part of 'fit_state.dart';

/// "Coach" logic: mid-workout next-set suggestions backed by the pure
/// progression engine, exposed to the session screen and the home widgets.
mixin CoachState on FitCore, LibraryState, PlansState, StatsState, WorkoutState {
  WorkoutPlan? planById(String id) {
    for (final p in plans) {
      if (p.id == id) return p;
    }
    for (final p in libraryPlans) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// The plan day the active session was started from, if any.
  WorkoutPlanDay? activeSessionDay() {
    final s = session;
    if (s == null || s.planId == null || s.planDayIndex == null) return null;
    final p = planById(s.planId!);
    if (p == null) return null;
    final i = s.planDayIndex!;
    if (i < 0 || i >= p.days.length) return null;
    return p.days[i];
  }

  /// Smart suggestion per exercise in the active session, keyed by exercise
  /// id. Target range: plan range when the session came from a plan day,
  /// otherwise the last heavy working reps. Weights are in display units.
  Map<String, ProgressionHint> nextSetHints() {
    final out = <String, ProgressionHint>{};
    final s = session;
    if (s == null) return out;
    final day = activeSessionDay();
    for (final ex in s.exercises) {
      if (isRepsOnly(ex.id)) continue;
      final last = priorWorkingSets(sessions, ex.id);
      WorkoutPlanExercise? pe;
      if (day != null) {
        for (final e in day.exercises) {
          if (e.exerciseId == ex.id) {
            pe = e;
            break;
          }
        }
      }
      int tMin, tMax;
      if (pe != null) {
        tMin = pe.reps;
        tMax = pe.repsMax ?? pe.reps;
      } else if (last.isNotEmpty) {
        final h = heaviestWorkingSet(last);
        tMin = h.reps;
        tMax = h.reps;
      } else {
        continue;
      }
      final display = [
        for (final l in last) LoggedSet(l.reps, toDisplayWeight(l.weight), kind: l.kind),
      ];
      final heaviest = heaviestWorkingSet(display);
      final plate = plateFor(units, heaviest.weight);
      out[ex.id] = nextSetHint(
        lastWorkingSets: display,
        targetMin: tMin,
        targetMax: tMax,
        plate: plate,
      );
    }
    return out;
  }
}
