# Coach: Smart next-set weights + Today's Workout home widgets — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the "Coach" feature: the app recommends the working weight/rep target for the next set of every exercise during a live workout (tappable chip), and surfaces the same intelligence on two new Android home-screen widgets (Today's Workout, Next Up).

**Architecture:** A pure, stateless engine (`lib/services/smart_progression.dart`) is the single source of truth for hints. A new `CoachState` mixin (part of the existing `fit_state.dart` state library) exposes `nextSetHints()` + `applyHint()` to the session screen. A second pure builder (`lib/services/today_widget.dart`) produces `TodayCardData` for the two home widgets, which reuse the existing `home_widget` bridge, `renderFlutterWidget`, Settings pin flow, and the Kotlin `HomeWidgetProvider` pattern. Everything is unit-testable without plugin calls.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2, `home_widget` ^0.7.0, Material 3-style custom theming (`AppTheme`, `GymColors`), `package:flutter_gen`-style generated l10n (5 ARB files), Kotlin app-widget receivers.

**Worktree note:** Work in the current repo (`C:\Users\raiga\Desktop\Trainingapp`). Branch `main`, origin remote `R4iga/Trainingapp`. JDK 21 is already configured for Gradle. Do NOT commit unless a step says "Commit".

---

## File structure

**Created**
- `lib/services/smart_progression.dart` — pure engine: `ProgressionVerdict`, `ProgressionHint`, `plateFor`, `roundUpTo`, `priorWorkingSets`, `heaviestWorkingSet`, `nextSetHint`. Imports only `../models/workout.dart` + `dart:math`.
- `lib/services/today_widget.dart` — pure data layer: `LiftHintRow`, `TodayCardData`, `planDayForToday`, `trainedToday`, `buildTodayCard`. Imports engine + models only.
- `lib/state/coach_state.dart` — `part of 'fit_state.dart'`; mixin `CoachState` with `planById`, `activeSessionDay`, `nextSetHints`, `applyHint`.
- `test/smart_progression_test.dart`, `test/coach_state_test.dart`, `test/coach_session_chip_test.dart`, `test/today_widget_test.dart`.
- Android: `android/app/src/main/kotlin/com/gymmane/app/TodayWidgetProvider.kt`, `NextUpWidgetProvider.kt`; `res/xml/today_widget_info.xml`, `res/xml/next_up_widget_info.xml`; `res/layout/widget_today.xml`, `res/layout/widget_next_up.xml`.

**Modified**
- `lib/state/fit_state.dart` — add `part 'coach_state.dart';` and `import '../services/smart_progression.dart';`.
- `lib/models/live_session.dart` — `WorkoutSession` gains nullable `planId` / `planDayIndex` (additive JSON keys `pl` / `pd`).
- `lib/state/workout_state.dart` — `_beginSessionWithPlan` stores `planId` / `planDayIndex`.
- `lib/screens/session_screen.dart` — `_hintRow` chip under `_plateRow`.
- `lib/widgets/home_widget_views.dart` — `TodayWidgetView`, `NextUpWidgetView`.
- `lib/services/home_widget_bridge.dart` — render + update the two new widgets.
- `lib/screens/settings_screen.dart` — two new entries in the "Add widget" list.
- `lib/l10n/app_en.arb`, `app_es.arb`, `app_it.arb`, `app_pt.arb`, `app_zh.arb` (+ run `flutter gen-l10n`).
- `android/app/src/main/AndroidManifest.xml` — two new `<receiver>` blocks.
- `test/home_widgets_test.dart` — pump the two new widget views.

---

### Task 1: Engine primitives — `plateFor` / `roundUpTo`

**Files:**
- Create: `lib/services/smart_progression.dart`
- Test: `test/smart_progression_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/smart_progression_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/services/smart_progression.dart';

void main() {
  group('plateFor', () {
    test('kg uses 2.5 normally and 1.25 for light lifts', () {
      expect(plateFor('kg', 60), 2.5);
      expect(plateFor('kg', 19.9), 1.25);
    });

    test('lb uses 5.0 normally and 2.5 for light lifts', () {
      expect(plateFor('lb', 100), 5.0);
      expect(plateFor('lb', 44.9), 2.5);
    });
  });

  group('roundUpTo', () {
    test('rounds up to the nearest plate', () {
      expect(roundUpTo(40.0, 2.5), 40.0);
      expect(roundUpTo(41.2, 2.5), 42.5);
      expect(roundUpTo(45.1, 5), 50);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/smart_progression_test.dart`
Expected: FAIL — `plateFor` / `roundUpTo` not defined.

- [ ] **Step 3: Create the engine file with the two helpers**

Create `lib/services/smart_progression.dart`:

```dart
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/smart_progression_test.dart`
Expected: PASS (2 groups, 3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/smart_progression.dart test/smart_progression_test.dart
git commit -m "feat(coach): progression engine plate helpers"
```

---

### Task 2: Engine — history filters + verdict logic

**Files:**
- Modify: `lib/services/smart_progression.dart`
- Modify: `test/smart_progression_test.dart`

- [ ] **Step 1: Add the failing tests**

Append to `test/smart_progression_test.dart` (inside `main()`, after the existing groups), keeping the existing imports and adding `import 'package:gymmane/models/workout.dart';` at the top:

```dart
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/smart_progression_test.dart`
Expected: FAIL — `priorWorkingSets`, `heaviestWorkingSet`, `nextSetHint`, `ProgressionHint`, `ProgressionVerdict` not defined.

- [ ] **Step 3: Implement the rest of the engine**

Append to `lib/services/smart_progression.dart`:

```dart
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
    if (s.weight > weight) {
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/smart_progression_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/smart_progression.dart test/smart_progression_test.dart
git commit -m "feat(coach): progression engine verdicts"
```

---

### Task 3: Localization keys (all 5 ARBs)

Add the Coach UI strings to every `lib/l10n/app_*.arb`. English goes in `app_en.arb`; `es` and `it` get real translations; `pt` and `zh` keep English copies (existing repo convention, enforced by `test/i18n_test.dart` parity test).

**Files:**
- Modify: `lib/l10n/app_en.arb`, `app_es.arb`, `app_it.arb`, `app_pt.arb`, `app_zh.arb`

- [ ] **Step 1: Add the keys to `app_en.arb`**

Insert these lines before the final closing `}` of `lib/l10n/app_en.arb` (JSON — mind the trailing comma of the previous entry):

```json
  "coachUp": "Try {weight} × {reps} - you hit {last} last time",
  "@coachUp": { "placeholders": { "weight": { "type": "String" }, "reps": { "type": "String" }, "last": { "type": "int" } } },
  "coachDown": "You missed {last} last time - try {weight} × {reps}",
  "@coachDown": { "placeholders": { "weight": { "type": "String" }, "reps": { "type": "String" }, "last": { "type": "int" } } },
  "coachHold": "Hold {weight} × {reps}",
  "@coachHold": { "placeholders": { "weight": { "type": "String" }, "reps": { "type": "String" } } },
  "wtToday": "TODAY",
  "wtRest": "Rest day",
  "wtNoPlan": "No plan yet",
  "wtNextUp": "NEXT UP",
  "wtSets": "sets",
  "addTodayWidget": "Add today's widget",
  "addNextUpWidget": "Add next-up widget"
```

- [ ] **Step 2: Add the same keys to the other four ARBs**

`lib/l10n/app_es.arb` (translated):

```json
  "coachUp": "Prueba {weight} × {reps} - la última vez hiciste {last}",
  "@coachUp": { "placeholders": { "weight": { "type": "String" }, "reps": { "type": "String" }, "last": { "type": "int" } } },
  "coachDown": "Fallaste {last} la última vez - prueba {weight} × {reps}",
  "@coachDown": { "placeholders": { "weight": { "type": "String" }, "reps": { "type": "String" }, "last": { "type": "int" } } },
  "coachHold": "Mantén {weight} × {reps}",
  "@coachHold": { "placeholders": { "weight": { "type": "String" }, "reps": { "type": "String" } } },
  "wtToday": "HOY",
  "wtRest": "Día de descanso",
  "wtNoPlan": "Aún sin plan",
  "wtNextUp": "SIGUIENTE",
  "wtSets": "series",
  "addTodayWidget": "Añadir widget de hoy",
  "addNextUpWidget": "Añadir widget siguiente"
```

`lib/l10n/app_it.arb` (translated):

```json
  "coachUp": "Prova {weight} × {reps} - l'ultima volta hai fatto {last}",
  "@coachUp": { "placeholders": { "weight": { "type": "String" }, "reps": { "type": "String" }, "last": { "type": "int" } } },
  "coachDown": "L'ultima volta hai mancato {last} - prova {weight} × {reps}",
  "@coachDown": { "placeholders": { "weight": { "type": "String" }, "reps": { "type": "String" }, "last": { "type": "int" } } },
  "coachHold": "Tieni {weight} × {reps}",
  "@coachHold": { "placeholders": { "weight": { "type": "String" }, "reps": { "type": "String" } } },
  "wtToday": "OGGI",
  "wtRest": "Giorno di riposo",
  "wtNoPlan": "Ancora nessun piano",
  "wtNextUp": "PROSSIMO",
  "wtSets": "serie",
  "addTodayWidget": "Aggiungi widget di oggi",
  "addNextUpWidget": "Aggiungi widget successivo"
```

`lib/l10n/app_pt.arb` and `lib/l10n/app_zh.arb` — identical English copies of the `app_en.arb` block from Step 1.

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: prints a generated-file note; `lib/l10n/app_localizations.dart` and the `app_localizations_*.dart` files are re-written with `coachUp`, `coachDown`, `coachHold`, `wtToday`, `wtRest`, `wtNoPlan`, `wtNextUp`, `wtSets`, `addTodayWidget`, `addNextUpWidget` getters.

- [ ] **Step 4: Verify parity**

Run: `flutter test test/i18n_test.dart`
Expected: PASS (all tests, including "no key is left untranslated in any shipped language").

- [ ] **Step 5: Commit**

```bash
git add lib/l10n
git commit -m "feat(coach): localization keys"
```

---

### Task 4: Session remembers its plan (model + wiring)

**Files:**
- Modify: `lib/models/live_session.dart`
- Modify: `lib/state/workout_state.dart`
- Test: `test/coach_state_test.dart` (create now, will grow)

- [ ] **Step 1: Add fields to `WorkoutSession`**

In `lib/models/live_session.dart` `WorkoutSession`, after the `int? summaryDuration;` line add:

```dart
  /// Plan the session was started from (nullable for freestyle workouts).
  String? planId;
  int? planDayIndex;
```

In `toJson()`, after the `'sd': summaryDuration,` line add:

```dart
        if (planId != null) 'pl': planId,
        if (planDayIndex != null) 'pd': planDayIndex,
```

In `fromJson()`, after the `..summaryDuration = (j['sd'] as num?)?.toInt();` line add:

```dart
        ..planId = j['pl'] as String?
        ..planDayIndex = (j['pd'] as num?)?.toInt()
```

- [ ] **Step 2: Store the plan when a session starts from a plan day**

In `lib/state/workout_state.dart` `_beginSessionWithPlan` (currently ends with `session = s;` around line 164), insert these two lines right before `session = s;`:

```dart
    s.planId = plan.id;
    s.planDayIndex = dayIndex;
```

- [ ] **Step 3: Write the failing tests**

Create `test/coach_state_test.dart`:

```dart
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/coach_state_test.dart`
Expected: PASS (2 tests). (The session-screen import of `smart_progression.dart` is registered only in Task 5.)

- [ ] **Step 5: Commit**

```bash
git add lib/models/live_session.dart lib/state/workout_state.dart test/coach_state_test.dart
git commit -m "feat(coach): session remembers its plan day"
```

---

### Task 5: `CoachState` mixin + `nextSetHints()`

**Files:**
- Modify: `lib/state/fit_state.dart`
- Create: `lib/state/coach_state.dart`
- Modify: `test/coach_state_test.dart`

- [ ] **Step 1: Register the new mixin part**

In `lib/state/fit_state.dart`:
- Add `import '../services/smart_progression.dart';` at the top with the other `../services/...` imports.
- Add `part 'coach_state.dart';` after the existing `part 'generator_state.dart';` line.

- [ ] **Step 2: Write the failing tests**

Append inside `main()` of `test/coach_state_test.dart` (before the closing `}`):

```dart
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
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/coach_state_test.dart`
Expected: FAIL — `nextSetHints` not defined.

- [ ] **Step 4: Implement `CoachState`**

Create `lib/state/coach_state.dart`:

```dart
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
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/coach_state_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/state/fit_state.dart lib/state/coach_state.dart test/coach_state_test.dart
git commit -m "feat(coach): next set hints from state"
```

---

### Task 6: `applyHint()` — pre-fill the next set

**Files:**
- Modify: `lib/state/coach_state.dart`
- Modify: `test/coach_state_test.dart`

- [ ] **Step 1: Write the failing tests**

Append inside `main()` of `test/coach_state_test.dart` (before the closing `}`):

```dart
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/coach_state_test.dart`
Expected: FAIL — `applyHint` not defined.

- [ ] **Step 3: Implement `applyHint`**

Append to the `CoachState` mixin body in `lib/state/coach_state.dart` (inside the closing brace, after `nextSetHints`):

```dart
  /// Apply [exIdx]'s suggestion to its next undone working set: sets the
  /// weight (display → stored kg) and the top of the rep range.
  void applyHint(int exIdx) {
    final s = session;
    if (s == null) return;
    if (exIdx < 0 || exIdx >= s.exercises.length) return;
    final ex = s.exercises[exIdx];
    final h = nextSetHints()[ex.id];
    if (h == null || !h.hasSuggestion || h.suggestedWeight == null) return;
    final idx = ex.sets.indexWhere((st) => !st.done && st.kind == SetKind.normal);
    if (idx < 0) return;
    ex.sets[idx].weight = _round3(fromDisplayWeight(h.suggestedWeight!).clamp(0, 1000));
    ex.sets[idx].reps = h.targetMax.clamp(0, 999);
    _persist();
    notifyListeners();
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/coach_state_test.dart`
Expected: PASS (9 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/state/coach_state.dart test/coach_state_test.dart
git commit -m "feat(coach): apply hint to next set"
```

---

### Task 7: Session screen smart-weight chip

**Files:**
- Modify: `lib/screens/session_screen.dart`
- Test: `test/coach_session_chip_test.dart` (new)

- [ ] **Step 1: Write the failing widget tests**

Create `test/coach_session_chip_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    fit.resetAllData();
    fit.setUnits('kg');
    fit.onboarded = true;
    fit.sessions.add(LoggedSession(DateTime(2026, 9, 7), 1200, [
      LoggedExercise('EIeI8Vf', 'Barbell Bench Press', 'chest', [
        LoggedSet(10, 60),
      ]),
    ]));
    fit.startWorkout();
    fit.toggleMuscle('chest');
    fit.trainContinue();
    fit.startSession();
    fit.session!.currentIndex =
        fit.session!.exercises.indexWhere((e) => e.id == 'EIeI8Vf');
    fit.route = 'session';
  });

  testWidgets('session shows a tappable smart-weight chip', (tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('62.5'), findsOneWidget, reason: 'bump a 62.5 kg');
  });

  testWidgets('tapping the chip pre-fills the next set', (tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.textContaining('62.5').first);
    await tester.pump();
    final ex = fit.session!.exercises.firstWhere((e) => e.id == 'EIeI8Vf');
    expect(ex.sets.first.weight, closeTo(62.5, 0.001));
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/coach_session_chip_test.dart`
Expected: FAIL — no text contains `62.5` (`findsOneWidget` fails; second test taps nothing).

- [ ] **Step 3: Implement `_hintRow` and place it in the exercise card**

In `lib/screens/session_screen.dart`:

1. Add `import '../services/smart_progression.dart';` to the imports.
2. Replace the line in the exercise card (currently `if (!repsOnly && ex != null) _plateRow(gc, ex),` around line 180) with:

```dart
              if (!repsOnly && ex != null) ...[
                _plateRow(gc, ex),
                _hintRow(gc, exIdx, ex),
              ],
```

3. Add a `String _targetLabel(int min, int max)` helper and the `_hintRow` method right after the `_plateRow(...)` method (after line ~449):

```dart
  String _targetLabel(int min, int max) => min == max ? '$min' : '$min-$max';

  Widget _hintRow(GymColors gc, int exIdx, SessionExercise ex) {
    final h = fit.nextSetHints()[ex.id];
    if (h == null || !h.hasSuggestion || h.suggestedWeight == null) {
      return const SizedBox.shrink();
    }
    final weight = '${fmt(_round1(h.suggestedWeight!))} ${fit.units.toUpperCase()}';
    final reps = _targetLabel(h.targetMin, h.targetMax);
    final last = h.lastBestReps ?? 0;
    final label = switch (h.verdict) {
      ProgressionVerdict.bump => t.coachUp(weight, reps, last),
      ProgressionVerdict.reduce => t.coachDown(weight, reps, last),
      _ => t.coachHold(weight, reps),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(_rowPad, 8, _rowPad, 0),
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => fit.applyHint(exIdx),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: gc.bgRaised2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.star, size: 13, color: gc.ember),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.s(11.5, weight: FontWeight.w600, color: gc.text)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/coach_session_chip_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Run the analysis to confirm no new warnings in the screen**

Run: `flutter analyze`
Expected: only the 3 pre-existing `onReorder` infos (`plan_generator_screen.dart:474`, `plan_edit_screen.dart:309`, `routine_edit_screen.dart:133`).

- [ ] **Step 6: Commit**

```bash
git add lib/screens/session_screen.dart test/coach_session_chip_test.dart
git commit -m "feat(coach): inline smart-weight chip in session"
```

---

### Task 8: Pure `today_widget.dart` data builder

**Files:**
- Create: `lib/services/today_widget.dart`
- Test: `test/today_widget_test.dart` (new)

- [ ] **Step 1: Write the failing tests**

Create `test/today_widget_test.dart`:

```dart
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
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/today_widget_test.dart`
Expected: FAIL — not found imports / undefined symbols.

- [ ] **Step 3: Implement `today_widget.dart`**

Create `lib/services/today_widget.dart`:

```dart
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/today_widget_test.dart`
Expected: PASS (9 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/today_widget.dart test/today_widget_test.dart
git commit -m "feat(coach): today widget data builder"
```

---

### Task 9: Widget views (`TodayWidgetView`, `NextUpWidgetView`) + draw tests

**Files:**
- Modify: `lib/widgets/home_widget_views.dart`
- Modify: `test/home_widgets_test.dart`

- [ ] **Step 1: Write the failing draw tests**

In `test/home_widgets_test.dart`:
1. Add `import 'package:gymmane/services/today_widget.dart';` at the top.
2. Inside the `for (final (name, gc) in [('dark', ...), ('light', ...)])` loop, after the `BodyWidgetView` line, add:

```dart
      await draw(
        tester,
        TodayWidgetView(
          gc: gc,
          data: const TodayCardData(
            live: false,
            rest: false,
            dayName: 'Push',
            streak: 12,
            todaySets: 6,
            lifts: [
              LiftHintRow(name: 'Bench', weightLabel: '62.5 kg', repLabel: '8-10', lastReps: 10),
              LiftHintRow(name: 'Shoulder Press', weightLabel: '40 kg', repLabel: '8', lastReps: 8),
            ],
          ),
        ),
      );
      await draw(
        tester,
        NextUpWidgetView(
          gc: gc,
          data: const TodayCardData(
            live: false,
            rest: false,
            dayName: 'Push',
            streak: 0,
            todaySets: 0,
            lifts: [
              LiftHintRow(name: 'Bench', weightLabel: '62.5 kg', repLabel: '8-10', lastReps: 10),
            ],
          ),
        ),
      );
```

3. Add one more test after the empty-history body test:

```dart
  testWidgets('the today widgets hold up against empty data', (tester) async {
    const empty = TodayCardData(
      live: false,
      rest: false,
      dayName: null,
      streak: 0,
      todaySets: 0,
      lifts: [],
    );
    await draw(tester, const TodayWidgetView(gc: GymColors.dark, data: empty));
    await draw(tester, const NextUpWidgetView(gc: GymColors.dark, data: empty));
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/home_widgets_test.dart`
Expected: FAIL — `TodayCardData` / `TodayWidgetView` / `NextUpWidgetView` not defined.

- [ ] **Step 3: Implement the views**

In `lib/widgets/home_widget_views.dart`:
1. Add `import '../services/today_widget.dart';` to the imports.
2. Append after the `BodyWidgetView` class (end of file):

```dart
class TodayWidgetView extends StatelessWidget {
  const TodayWidgetView({
    super.key,
    required this.gc,
    required this.data,
    this.size = const Size(320, 230),
  });

  final GymColors gc;
  final TodayCardData data;
  final Size size;

  @override
  Widget build(BuildContext context) {
    String _daysOrPlan() {
      if (data.live) return data.dayName ?? t.wtToday;
      if (data.rest) return t.wtRest;
      return data.dayName ?? t.wtNoPlan;
    }

    return Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gc.border, width: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(t.wtToday,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: TextStyle(
                        fontFamily: _kDisplay,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: gc.text)),
              ),
              const Spacer(),
              Icon(Icons.local_fire_department_rounded, size: 14, color: gc.accent),
              const SizedBox(width: 3),
              Text('${data.streak}',
                  style: TextStyle(
                      fontFamily: _kDisplay, fontSize: 13, fontWeight: FontWeight.w700, color: gc.accent)),
              const SizedBox(width: 12),
              Text('${data.todaySets} ${t.wtSets}',
                  style: TextStyle(fontFamily: _kBody, fontSize: 10.5, color: gc.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(_daysOrPlan(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: _kDisplay, fontSize: 16, fontWeight: FontWeight.w700, color: gc.text)),
          const SizedBox(height: 10),
          Expanded(
            child: data.lifts.isEmpty
                ? Center(
                    child: Text('—', style: TextStyle(fontFamily: _kBody, fontSize: 22, color: gc.textTertiary)),
                  )
                : Column(
                    children: [
                      for (final row in data.lifts) _liftRow(gc, row),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _liftRow(GymColors gc, LiftHintRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(row.name,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(fontFamily: _kBody, fontSize: 11, color: gc.text)),
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(row.weightLabel ?? '—',
                style: TextStyle(fontFamily: _kDisplay, fontSize: 13, fontWeight: FontWeight.w700, color: gc.ember)),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(row.repLabel,
                style: TextStyle(fontFamily: _kBody, fontSize: 11, color: gc.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class NextUpWidgetView extends StatelessWidget {
  const NextUpWidgetView({
    super.key,
    required this.gc,
    required this.data,
    this.size = const Size(160, 155),
  });

  final GymColors gc;
  final TodayCardData data;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final lift = data.lifts.isEmpty ? null : data.lifts.first;

    return Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gc.border, width: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.wtNextUp,
              style: TextStyle(
                  fontFamily: _kDisplay,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: gc.textSecondary)),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(lift?.weightLabel ?? '—',
                style: TextStyle(
                    fontFamily: _kDisplay, fontSize: 34, height: 1, fontWeight: FontWeight.w700, color: gc.ember)),
          ),
          const SizedBox(height: 4),
          Text(lift?.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: _kBody, fontSize: 13, color: gc.text)),
          const SizedBox(height: 2),
          Text(
            data.rest
                ? t.wtRest
                : (data.dayName ?? t.wtNoPlan),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: _kBody, fontSize: 10.5, color: gc.textSecondary),
          ),
        ],
      ),
    );
  }
}
```

> Note: avoid the `package:collection` `firstOrNull` extension — the plan above uses a plain `data.lifts.isEmpty ? null : data.lifts.first` safe read, which needs no extra import. (The code block already reflects this.)

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/home_widgets_test.dart`
Expected: PASS (draw tests + the two new widget views + empty-data test).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/home_widget_views.dart test/home_widgets_test.dart
git commit -m "feat(coach): home widget views"
```

---

### Task 10: Bridge renders + updates the new widgets

**Files:**
- Modify: `lib/services/home_widget_bridge.dart`

This task swaps the pure data builder into the existing widget render pipeline. It cannot be unit-tested (plugin calls) — verification is `flutter analyze` + a debug APK build compile check.

- [ ] **Step 1: Wire TodayWidgetView and NextUpWidgetView into `update()`**

In `lib/services/home_widget_bridge.dart`:
1. Add `import 'today_widget.dart';` to the imports.
2. Add the two keys next to the existing ones:

```dart
  static const todayKey = 'today_img';
  static const nextUpKey = 'next_up_img';
```

3. After the `BodyWidgetView` render block (after line ~58) add:

```dart
      final sessionDay = fit.activeSessionDay();
      final liveDone = fit.session == null
          ? 0
          : fit.session!.exercises.fold(
              0,
              (int a, e) => a + e.sets.where((s) => s.done && s.counts).length,
            );
      final card = buildTodayCard(
        plans: fit.plans,
        liveDay: sessionDay,
        sessions: fit.sessions,
        isRepsOnly: fit.isRepsOnly,
        units: fit.units,
        streak: fit.currentStreak,
        todaySets: fit.setsToday + liveDone,
      );
      await HomeWidget.renderFlutterWidget(
        TodayWidgetView(gc: gc, data: card, size: const Size(320, 230)),
        key: todayKey,
        logicalSize: const Size(320, 230),
        pixelRatio: 3,
      );
      await HomeWidget.renderFlutterWidget(
        NextUpWidgetView(gc: gc, data: card, size: const Size(160, 155)),
        key: nextUpKey,
        logicalSize: const Size(160, 155),
        pixelRatio: 3,
      );
      await HomeWidget.updateWidget(
          qualifiedAndroidName: '$_pkg.TodayWidgetProvider');
      await HomeWidget.updateWidget(
          qualifiedAndroidName: '$_pkg.NextUpWidgetProvider');
```

- [ ] **Step 2: Verify it compiles and is clean**

Run: `flutter analyze`
Expected: no new issues (the 3 pre-existing `onReorder` infos only).

- [ ] **Step 3: Commit**

```bash
git add lib/services/home_widget_bridge.dart
git commit -m "feat(coach): bridge renders today + next-up widgets"
```

---

### Task 11: Android widget receivers (Kotlin + XML + manifest)

Copy the existing `HeatmapWidgetProvider` pattern exactly.

**Files:**
- Create: `android/app/src/main/kotlin/com/gymmane/app/TodayWidgetProvider.kt`
- Create: `android/app/src/main/kotlin/com/gymmane/app/NextUpWidgetProvider.kt`
- Create: `android/app/src/main/res/xml/today_widget_info.xml`
- Create: `android/app/src/main/res/xml/next_up_widget_info.xml`
- Create: `android/app/src/main/res/layout/widget_today.xml`
- Create: `android/app/src/main/res/layout/widget_next_up.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Create the Kotlin providers**

`android/app/src/main/kotlin/com/gymmane/app/TodayWidgetProvider.kt`:

```kotlin
package com.gymmane.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TodayWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_today).apply {
                val path = widgetData.getString("today_img", null)
                if (path != null) {
                    val bmp = BitmapFactory.decodeFile(path)
                    if (bmp != null) setImageViewBitmap(R.id.widget_today_image, bmp)
                }
                val open = PendingIntent.getActivity(
                    context,
                    0,
                    Intent(context, MainActivity::class.java),
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                )
                setOnClickPendingIntent(R.id.widget_today_image, open)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
```

`android/app/src/main/kotlin/com/gymmane/app/NextUpWidgetProvider.kt` — same file with the class renamed to `NextUpWidgetProvider`, `R.layout.widget_next_up`, key `"next_up_img"`, and image id `R.id.widget_next_up_image`.

- [ ] **Step 2: Create the widget info XMLs**

`android/app/src/main/res/xml/today_widget_info.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="110dp"
    android:targetCellWidth="4"
    android:targetCellHeight="3"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/widget_today"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"
    android:previewImage="@drawable/preview_heatmap" />
```

`android/app/src/main/res/xml/next_up_widget_info.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="110dp"
    android:targetCellWidth="2"
    android:targetCellHeight="2"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/widget_next_up"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"
    android:previewImage="@drawable/preview_stats" />
```

- [ ] **Step 3: Create the widget layouts**

`android/app/src/main/res/layout/widget_today.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <ImageView
        android:id="@+id/widget_today_image"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:adjustViewBounds="true"
        android:scaleType="fitCenter"
        android:contentDescription="GymMane" />
</FrameLayout>
```

`android/app/src/main/res/layout/widget_next_up.xml` — same with id `@+id/widget_next_up_image`.

- [ ] **Step 4: Register the receivers in the manifest**

In `android/app/src/main/AndroidManifest.xml`, after the existing `BodyWidgetProvider` `<receiver>...</receiver>` block, add:

```xml
        <receiver
            android:name=".TodayWidgetProvider"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/today_widget_info" />
        </receiver>
        <receiver
            android:name=".NextUpWidgetProvider"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/next_up_widget_info" />
        </receiver>
```

- [ ] **Step 5: Verify the Android resources resolve**

Run: `flutter build apk --debug`
Expected: BUILD SUCCESSFUL (layout ids `widget_today_image` / `widget_next_up_image` and the two preview drawables resolve).

- [ ] **Step 6: Commit**

```bash
git add android/app/src/main
git commit -m "feat(coach): android today + next-up widget providers"
```

---

### Task 12: Settings "Add widget" entries

**Files:**
- Modify: `lib/screens/settings_screen.dart`

- [ ] **Step 1: Add the two providers to the widget list**

In `lib/screens/settings_screen.dart`, in the `_linkGroup` inside the `if (Platform.isAndroid) ...[` block (currently three entries: Heatmap/Stats/Body, lines ~164-168), append two entries:

```dart
                (PhosphorIconsRegular.squaresFour, t.addTodayWidget, () => _addWidget(context, 'TodayWidgetProvider')),
                (PhosphorIconsRegular.arrowRight, t.addNextUpWidget, () => _addWidget(context, 'NextUpWidgetProvider')),
```

- [ ] **Step 2: Verify**

Run: `flutter analyze`
Expected: no new issues.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/settings_screen.dart
git commit -m "feat(coach): pin today + next-up widgets from settings"
```

---

### Task 13: Full verification

- [ ] **Step 1: Run the complete suite**

Run: `flutter test`
Expected: all tests PASS (372 baseline + the new engine/state/chip/today-widget tests). The l10n parity test (`i18n_test.dart`) must stay green.

- [ ] **Step 2: Run analysis**

Run: `flutter analyze`
Expected: only the 3 pre-existing `onReorder` infos (`plan_generator_screen.dart:474`, `plan_edit_screen.dart:309`, `routine_edit_screen.dart:133`). No new warnings or errors.

- [ ] **Step 3: (Optional, only if a release APK is requested) rebuild the release**

Run: `flutter build apk --release`
Expected: `build\app\outputs\flutter-apk\app-release.apk` produced.

- [ ] **Step 4: Manual smoke on device (if available)**

Pin both widgets from Settings → both render; start a plan-day session → suggestion chip appears on exercises with history; tapping it pre-fills the set.

---

## Self-review notes (from spec)

- **Spec §1 (engine):** Tasks 1-2 implement `priorWorkingSets`, verdict table, `roundUpTo`, `plateFor`, empty-data → firstTime/no chip. ✓
- **Spec §1 target-range priority:** Task 5 (`nextSetHints`) uses plan `reps..repsMax` when started from a plan day (via the `planId`/`planDayIndex` stored in Task 4), else last heavy working reps ("plan range, else last reps"). ✓
- **Spec §2 (session chips):** Task 7 renders bump/hold/reduce labels, hit/missed last-time text, tap → `applyHint` pre-fills weight + reps target; works in freestyle (fallback target). L10n keys in Task 3. ✓
- **Spec §3a/3b (widgets):** Today's Workout (wide) + Next Up (compact) via Task 9 views, Task 8 pure builder, Task 10 bridge, Task 11 Android receivers/resources/manifest, Task 12 Settings list. Rest day = already trained today (no invented weekday schedule); No-plan = nothing available. ✓
- **Spec §4 (l10n):** Task 3 (5 ARBs + parity + gen-l10n). ✓
- **Spec §5 (tests):** Tasks 1-2 engine, 5-6 state, 8-9 builder/views, 7 chip widget test; no plugin calls in tests. ✓
- **Spec §6 (out of scope):** no tap-to-start, no check-in/deload. ✓

## Notes for the executor

- `fit_state.dart` parts: add files via `part 'coach_state.dart';` (Task 5) — all privates (`_round3`, `fmt`, `_round1`, `toDisplayWeight`, etc.) are shared with the part-file mixin.
- Weight scale discipline: stored weights are **always kg**; display conversions happen only at the boundary (`toDisplayWeight` / `fromDisplayWeight`). The engine and `today_widget.dart` work in display units; `applyHint` converts back to kg before storing.
- Keep commits in order; each task ends green on its own tests.