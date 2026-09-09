import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/models/workout_plan.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/services/smart_progression.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    fit.resetAllData();
    fit.setUnits('kg');
  });

  WorkoutPlan twoDayPlan() => WorkoutPlan(
        id: 'p1',
        name: 'Split',
        days: [
          WorkoutPlanDay(name: 'Push', exercises: [
            WorkoutPlanExercise(
              exerciseId: 'EIeI8Vf',
              name: 'Barbell Bench Press',
              primary: 'chest',
              sets: 3,
              reps: 8,
              repsMax: 10,
            ),
          ]),
          WorkoutPlanDay(name: 'Pull', exercises: []),
        ],
      );

  void logBench(int reps, double weight) {
    fit.sessions.add(LoggedSession(DateTime(2026, 9, 7), 1200, [
      LoggedExercise('EIeI8Vf', 'Barbell Bench Press', 'chest', [
        LoggedSet(reps, weight),
      ]),
    ]));
  }

  test('a session started from a plan remembers which day it came from', () {
    fit.plans.add(twoDayPlan());
    fit.startPlanDay(fit.plans.last, 0);
    expect(fit.session!.planId, 'p1');
    expect(fit.session!.planDayIndex, 0);
  });

  test('a freestyle session has no plan attached', () {
    fit.startWorkout();
    fit.toggleMuscle('chest');
    fit.trainContinue();
    fit.startSession();
    expect(fit.session!.planId, isNull);
  });

  test('plan exercise range drives the suggestion target', () {
    logBench(10, 60);
    fit.plans.add(twoDayPlan());
    fit.startPlanDay(fit.plans.last, 0);
    final hint = fit.nextSetHints()['EIeI8Vf']!;
    expect(hint.verdict, ProgressionVerdict.bump);
    expect(hint.targetMin, 8);
    expect(hint.targetMax, 10, reason: 'usa el rango del plan, no el historial');
    expect(hint.suggestedWeight, 62.5);
  });

  test('freestyle workouts fall back to the last heavy reps', () {
    logBench(8, 60);
    fit.startWorkout();
    fit.toggleMuscle('chest');
    fit.trainContinue();
    fit.startSession();
    final hint = fit.nextSetHints()['EIeI8Vf']!;
    expect(hint.targetMin, 8);
    expect(hint.targetMax, 8, reason: 'sin plan: min = max = reps del set más pesado');
    expect(hint.verdict, ProgressionVerdict.bump);
  });

  test('no history means no suggestion', () {
    fit.startWorkout();
    fit.toggleMuscle('chest');
    fit.trainContinue();
    fit.startSession();
    expect(fit.nextSetHints()['EIeI8Vf'], isNull);
  });

  test('reps-only exercises are skipped', () {
    logBench(10, 60);
    fit.repsOnly.add('EIeI8Vf');
    fit.startWorkout();
    fit.toggleMuscle('chest');
    fit.trainContinue();
    fit.startSession();
    expect(fit.nextSetHints().containsKey('EIeI8Vf'), isFalse);
  });

  test('applyHint fills the next undone working set with weight and reps', () {
    logBench(10, 60);
    fit.plans.add(twoDayPlan());
    fit.startPlanDay(fit.plans.last, 0);
    fit.addSet(0); // a second set to fill (opening pre-fills from history)
    fit.toggleSet(0, 0); // first set logged
    fit.applyHint(0);
    final next = fit.session!.exercises[0].sets.firstWhere(
      (s) => !s.done && s.kind == SetKind.normal,
    );
    expect(next.weight, closeTo(62.5, 0.001));
    expect(next.reps, 10, reason: 'apunta a la parte alta del rango');
  });

  test('applyHint does nothing when every set is done', () {
    logBench(10, 60);
    fit.plans.add(twoDayPlan());
    fit.startPlanDay(fit.plans.last, 0);
    final sets = fit.session!.exercises[0].sets;
    for (var j = 0; j < sets.length; j++) {
      fit.toggleSet(0, j);
    }
    final before = sets.last.weight;
    fit.applyHint(0);
    expect(sets.last.weight, before);
  });

  test('applyHint respects the display unit conversion', () {
    logBench(10, 60);
    fit.setUnits('lb');
    fit.plans.add(twoDayPlan());
    fit.startPlanDay(fit.plans.last, 0);
    fit.addSet(0);
    fit.toggleSet(0, 0);
    fit.applyHint(0);
    final next = fit.session!.exercises[0].sets.firstWhere(
      (s) => !s.done && s.kind == SetKind.normal,
    );
    // last display max = 60 kg * 2.20462 = 132.28 lb; plate 5 lb -> roundUp 140 lb.
    expect(next.weight, closeTo(140 / 2.20462, 0.01));
  });
}
