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
}
