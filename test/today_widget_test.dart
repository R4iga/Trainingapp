import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/models/workout_plan.dart';
import 'package:gymmane/services/today_widget.dart';

void main() {
  WorkoutPlan twoDayPlan() => WorkoutPlan(
        id: 'p1',
        name: 'Split',
        archived: false,
        days: [
          WorkoutPlanDay(name: 'Push', exercises: [
            WorkoutPlanExercise(
              exerciseId: 'a',
              name: 'Bench',
              primary: 'chest',
              sets: 3,
              reps: 8,
              repsMax: 10,
            ),
            WorkoutPlanExercise(
              exerciseId: 'b',
              name: 'Shoulder Press',
              primary: 'shoulders',
              sets: 3,
              reps: 8,
            ),
          ]),
          WorkoutPlanDay(name: 'Pull', exercises: []),
        ],
      );

  List<LoggedSession> benchHistoryLog() => [
        LoggedSession(DateTime(2026, 9, 7), 1200, [
          LoggedExercise('a', 'Bench', 'chest', [LoggedSet(10, 60)]),
        ]),
      ];

  final wednesday = DateTime(2026, 9, 9, 10); // 2026-09-09 = Wednesday

  test('planDayForToday rotates through the days from Monday', () {
    final day = planDayForToday([twoDayPlan()], wednesday)!;
    expect(day.name, 'Push', reason: 'miércoles -> index (3-1) % 2 = 0');
  });

  test('planDayForToday ignores archived plans', () {
    final p = twoDayPlan()..archived = true;
    expect(planDayForToday([p], wednesday), isNull);
  });

  test('trainedToday detects a session on the same calendar day', () {
    final today = DateTime(2026, 9, 9, 20);
    final sessions = [
      LoggedSession(DateTime(2026, 9, 9, 7), 600, [LoggedExercise('a', 'Bench', 'chest', [LoggedSet(5, 20)])]),
      LoggedSession(DateTime(2026, 9, 8, 7), 600, [LoggedExercise('a', 'Bench', 'chest', [LoggedSet(5, 20)])]),
    ];
    expect(trainedToday(sessions, today), isTrue);
    expect(trainedToday([sessions.last], today), isFalse);
  });

  test('buildTodayCard with a live plan day lifts use the engine', () {
    final data = buildTodayCard(
      now: wednesday,
      plans: [twoDayPlan()],
      liveDay: twoDayPlan().days.first,
      sessions: benchHistoryLog(),
      isRepsOnly: (_) => false,
      units: 'kg',
      streak: 3,
      todaySets: 12,
    );
    expect(data.live, isTrue);
    expect(data.dayName, 'Push');
    final bench = data.lifts.first;
    expect(bench.name, 'Bench');
    expect(bench.weightLabel, '62.5 kg', reason: '60 + 2.5 redondeado');
    expect(bench.repLabel, '8-10');
  });

  test('buildTodayCard shows rest when already trained today', () {
    final data = buildTodayCard(
      now: DateTime(2026, 9, 9, 20),
      plans: [twoDayPlan()],
      liveDay: null,
      sessions: benchHistoryLog() + [
        LoggedSession(DateTime(2026, 9, 9, 7), 600, [LoggedExercise('a', 'Bench', 'chest', [LoggedSet(5, 20)])]),
      ],
      isRepsOnly: (_) => false,
      units: 'kg',
      streak: 2,
      todaySets: 4,
    );
    expect(data.rest, isTrue);
    expect(data.dayName, isNull);
    expect(data.lifts, isEmpty);
  });

  test('buildTodayCard says no-plan when there is nothing', () {
    final data = buildTodayCard(
      now: wednesday,
      plans: const [],
      liveDay: null,
      sessions: const [],
      isRepsOnly: (_) => false,
      units: 'kg',
      streak: 0,
      todaySets: 0,
    );
    expect(data.rest, isFalse);
    expect(data.dayName, isNull);
    expect(data.lifts, isEmpty);
  });

  test('buildTodayCard skips weights for reps-only exercises', () {
    final data = buildTodayCard(
      now: wednesday,
      plans: [twoDayPlan()],
      liveDay: twoDayPlan().days.first,
      sessions: benchHistoryLog(),
      isRepsOnly: (id) => id == 'a',
      units: 'kg',
      streak: 1,
      todaySets: 6,
    );
    expect(data.lifts.first.weightLabel, isNull);
  });

  test('buildTodayCard works in lb and rounds to the lb step', () {
    final data = buildTodayCard(
      now: wednesday,
      plans: [twoDayPlan()],
      liveDay: twoDayPlan().days.first,
      sessions: benchHistoryLog(),
      isRepsOnly: (_) => false,
      units: 'lb',
      streak: 1,
      todaySets: 6,
    );
    // 60 kg = 132.28 lb; heavy lift => plate 5 lb; bump -> 140 lb.
    expect(data.lifts.first.weightLabel, '140 lb');
  });

  test('buildTodayCard keeps at most five lifts', () {
    final many = WorkoutPlanDay(name: 'Full', exercises: [
      for (var i = 0; i < 8; i++)
        WorkoutPlanExercise(exerciseId: 'e$i', name: 'Ex $i', primary: 'chest', sets: 3, reps: 10),
    ]);
    final data = buildTodayCard(
      now: wednesday,
      plans: [twoDayPlan()],
      liveDay: many,
      sessions: const [],
      isRepsOnly: (_) => false,
      units: 'kg',
      streak: 0,
      todaySets: 0,
    );
    expect(data.lifts.length, 5);
    expect(data.lifts.first.weightLabel, isNull, reason: 'sin historial: sin peso sugerido');
    expect(data.lifts.first.lastReps, 0);
  });
}
