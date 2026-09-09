import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/models/exercise.dart';
import 'package:gymmane/models/generator.dart';
import 'package:gymmane/models/workout_plan.dart';
import 'package:gymmane/services/workout_generator.dart';

void main() {
  final pool = kExercises;

  test('session length maps to a sensible exercise budget', () {
    expect(genExerciseCount(20), 4);
    expect(genExerciseCount(25), 5);
    expect(genExerciseCount(30), 5);
    expect(genExerciseCount(45), 7);
    expect(genExerciseCount(60), 8);
    expect(genExerciseCount(75), 10);
    expect(genExerciseCount(90), 11);
    expect(genExerciseCount(120), 11);
  });

  test('a day with no muscles comes back empty', () {
    final plan = buildGenDay(const GenRequest(prefs: WorkoutPrefs(), muscles: []), pool);
    expect(plan, isEmpty);
  });

  const prefs60 = WorkoutPrefs(durationMinutes: 60);

  test('a chest day generates valid, unique exercises that train the chest', () {
    final day = buildGenDay(const GenRequest(prefs: prefs60, muscles: ['chest']), pool);
    expect(day, isNotEmpty);
    expect(day.length, lessThanOrEqualTo(genExerciseCount(60)));

    final ids = <String>{};
    for (final e in day) {
      final ex = pool.firstWhere((x) => x.id == e.exerciseId);
      expect(ids.add(e.exerciseId), isTrue, reason: 'no duplicate exercises');
      expect(ex.primary == 'chest' || ex.secondary.contains('chest'), isTrue,
          reason: '${ex.name} should train chest');
      expect(e.sets, inInclusiveRange(2, 8));
      expect(e.reps, inInclusiveRange(1, 40));
      expect(e.repsMax, isNotNull);
      expect(e.reps, lessThanOrEqualTo(e.repsMax!));
      expect(e.restSeconds, inInclusiveRange(30, 240));
    }
  });

  test('a multi-muscle day only picks exercises for the requested muscles', () {
    const muscles = ['chest', 'back', 'quads'];
    final day = buildGenDay(const GenRequest(prefs: prefs60, muscles: muscles), pool);
    expect(day, isNotEmpty);

    final ids = <String>{};
    for (final e in day) {
      final ex = pool.firstWhere((x) => x.id == e.exerciseId);
      expect(ids.add(e.exerciseId), isTrue);
      final trainsRequested = muscles.contains(ex.primary) ||
          ex.secondary.any(muscles.contains);
      expect(trainsRequested, isTrue,
          reason: '${ex.name} (primary ${ex.primary}) is off-plan');
    }
  });

  test('home equipment stays home-friendly', () {
    const prefs = WorkoutPrefs(durationMinutes: 45, equipment: GenEquipment.home);
    final day = buildGenDay(const GenRequest(prefs: prefs, muscles: ['chest', 'back']), pool);
    expect(day, isNotEmpty);
    for (final e in day) {
      final ex = pool.firstWhere((x) => x.id == e.exerciseId);
      expect(kGenEquipmentAllow[GenEquipment.home]!.contains(ex.equipment), isTrue,
          reason: '${ex.name} (${ex.equipment}) needs gear not available at home');
    }
  });

  test('a beginner keeps advanced moves out of the plan', () {
    const prefs =
        WorkoutPrefs(durationMinutes: 60, difficulty: 'Beginner', goal: PlanGoal.beginner);
    final day = buildGenDay(const GenRequest(prefs: prefs, muscles: ['chest', 'back', 'quads']), pool);
    expect(day, isNotEmpty);
    for (final e in day) {
      final ex = pool.firstWhere((x) => x.id == e.exerciseId);
      expect(ex.difficulty, isNot('Advanced'));
    }
  });

  test('goal tweaks sets, reps and rest', () {
    WorkoutPlanExercise build(PlanGoal g, String difficulty, int min) =>
        buildGenDay(
            GenRequest(
                prefs: WorkoutPrefs(goal: g, difficulty: difficulty, durationMinutes: min),
                muscles: ['chest']),
            pool)
            .first;

    final strength = build(PlanGoal.strength, 'Advanced', 60);
    expect(strength.reps, lessThanOrEqualTo(5));
    expect(strength.restSeconds, greaterThanOrEqualTo(150));

    final fatLoss = build(PlanGoal.fatLoss, 'Intermediate', 60);
    expect(fatLoss.reps, greaterThanOrEqualTo(8));
    expect(fatLoss.restSeconds, lessThanOrEqualTo(75));
  });

  test('regenerating a day prefers a visibly different set', () {
    const prefs =
        WorkoutPrefs(durationMinutes: 60, difficulty: 'Intermediate', goal: PlanGoal.muscleGain);
    final first = buildGenDay(const GenRequest(prefs: prefs, muscles: ['chest', 'shoulders']), pool);
    final again = buildGenDay(GenRequest(
        prefs: prefs,
        muscles: const ['chest', 'shoulders'],
        context: const GenContext(),
        avoidIds: {for (final e in first) e.exerciseId}),
        pool);
    final firstIds = first.map((e) => e.exerciseId).toSet();
    final againIds = again.map((e) => e.exerciseId).toSet();
    // Almost none of the previous exercises should come back when we ask for
    // a replacement (the heavy "avoid" penalty usually wins).
    expect(firstIds.intersection(againIds).length, lessThanOrEqualTo(1));
  });

  test('replaceOneGenExercise swaps in a different valid exercise', () {
    const prefs =
        WorkoutPrefs(durationMinutes: 60, difficulty: 'Intermediate', goal: PlanGoal.muscleGain);
    final day = buildGenDay(const GenRequest(prefs: prefs, muscles: ['chest']), pool);
    final current = day.first;
    final next = replaceOneGenExercise(
        const GenRequest(prefs: prefs, muscles: ['chest']), pool, 'chest', current.exerciseId);
    expect(next, isNotNull);
    expect(next!.exerciseId, isNot(current.exerciseId));
    final ex = pool.firstWhere((x) => x.id == next.exerciseId);
    expect(ex.primary == 'chest' || ex.secondary.contains('chest'), isTrue);
  });

  test('weekly context prevents burning through the set budget', () {
    // Chest is already at its weekly ceiling → only a single snatched set.
    final context = GenContext(
      weeklySets: const {'chest': 100},
      currentDay: 3,
    );
    final day = buildGenDay(
        GenRequest(prefs: prefs60, muscles: const ['chest'], context: context), pool);
    expect(day.length, 1, reason: 'week volume cap should leave a single set slot');
  });

  test('weekly context avoids repeating the same exercises', () {
    final monday = buildGenDay(
        const GenRequest(prefs: prefs60, muscles: ['back', 'biceps']), pool);
    final context = GenContext(
      usedExerciseIds: {for (final e in monday) e.exerciseId},
      currentDay: 2,
    );
    final tuesday = buildGenDay(
        GenRequest(prefs: prefs60, muscles: const ['back', 'biceps'], context: context), pool);
    final mondayIds = monday.map((e) => e.exerciseId).toSet();
    for (final e in tuesday) {
      expect(mondayIds.contains(e.exerciseId), isFalse);
    }
  });

  test('presets cover the expected week structure', () {
    final order = kMuscles.map((m) => m.id).toSet();
    final ppl = kGenPresetFor(GenStyle.ppl);
    for (final w in kWeekdays) {
      final days = ppl[w] ?? const <String>[];
      for (final m in days) {
        expect(order.contains(m), isTrue, reason: '$m is not a real muscle id');
      }
    }
    expect(ppl[1], containsAll(['chest', 'shoulders', 'triceps']));
    expect(ppl[2], containsAll(['back', 'biceps']));
    expect(ppl[7], isEmpty);

    for (final style in GenStyle.values) {
      final presets = kGenPresetFor(style);
      if (style == GenStyle.custom) {
        expect(presets, isEmpty, reason: 'custom starts clean');
        continue;
      }
      expect(presets.length, 7);
      for (final list in presets.values) {
        expect(list.toSet().length, list.length, reason: 'no duplicate muscles per day');
      }
    }
  });
}