# Coach: Smart next-set weights + Today's Workout home widgets

Status: Approved design
Date: 2026-09-09

## Goal

A coherent "Coach" package: the app recommends the working weight and rep
target for the next set of every exercise, and surfaces that same intelligence
on the Android home screen with two new app widgets.

## 1. Decision engine — `lib/services/smart_progression.dart`

A stateless, pure, unit-testable engine. The single source of truth for
mid-workout hints and widget data.

### Inputs

- `priorWorkingSets(List<LoggedSession> sessions, String exerciseId)`:
  find the latest `LoggedSession` that contains the exercise; return only its
  `working` sets (`SetKind.normal` only — exclude `warmup`, `drop`, `failure`).
- Target rep range: a min (`reps`) and max (`repsMax`) pair.
- Plate increment for rounding.

### Output

`Suggestion` with a verdict and a suggested weight:

| Verdict | Condition | Suggested weight |
|---|---|---|
| `firstTime` | no prior working sets | none (no chip) |
| `bump` | every working set reached `>= range.max` | `lastMaxWeight + plate`, rounded up to plate |
| `reduce` | any working set below `range.min` | `lastMaxWeight - plate`, floored at 0 |
| `hold` | mixed results | last used working weight |

Empty target range or missing data always falls through to `hold` / no chip.

### Helpers

- `double roundUpTo(double w, double plate)` — round a suggestion up to the
  nearest plate.
- `double plateFor(String units, double weight)` — `2.5` kg / `5` lb normally;
  `1.25` kg / `2.5` lb when weight < 20 kg / 45 lb (light lifts).

### Target-range priority

1. If the current workout was started from a plan day (`startPlanDay`), use the
   plan exercise's `reps`..`repsMax`. Single-number plans become `(n, n)`.
2. Otherwise use the last session's achieved working reps as the target
   (min = max = the reps of the heaviest working set in the latest session).
   Rule: "plan range, else last reps".

## 2. Session screen — inline hint chips

- `workout_state.dart` gains `Map<String, Suggestion> nextSetHints()` built
  from the engine (per exercise currently in the active workout). Keeps the
  widget thin and the computation testable at the state level.
- In `lib/screens/session_screen.dart`, after a set is logged, the next set's
  **weight field** shows a tappable chip:
  - `bump`: `↑ 40 kg × 8–10 · hit 10 last time`
  - `reduce`: `↓ 40 kg × 8–10 · missed last time`
  - `hold`: `→ 40 kg × 8–10 · keep it`
- Tapping the chip pre-fills that set's weight (and reps target).
- No working history → no chip. Works in freestyle workouts too (fallback
  target).
- New l10n keys: suggest labels, verdict text, "last time", units-free numbers.

## 3. Home-screen widgets (Android, existing bridge)

Reuse `HomeWidgetBridge.renderFlutterWidget`, the update trigger
(`onWidgetsShouldUpdate` already fires on every notify), and the Settings
"Add widget" pin flow.

### 3a. Today's Workout widget (wide, ~320×230)

- Today's active plan day name, or `Rest day`, or `No plan yet`.
- Up to 5 exercises, each showing the **smart suggested weight × rep range**
  (computed with the same engine), plus a running streak and today's set count.

### 3b. Next Up widget (compact, ~160×155)

- The single lift the user is about to do: first exercise of today's plan day,
  else the most recent lift, with its suggested weight.

### Wiring

- Pure builder `buildTodayCard(...)` in `lib/services/today_widget.dart`
  returns a plain `TodayCardData` model (no plugin access) so it is unit
  testable.
- `TodayWidgetView` / `NextUpWidgetView` in `lib/widgets/home_widget_views.dart`
  render that data.
- Android: new `TodayWidgetProvider` / `NextUpWidgetProvider` receivers,
  `layout/widget_today.xml` + `layout/widget_next_up.xml`,
  `xml/today_widget_info.xml` + `xml/next_up_widget_info.xml`, manifest
  receivers, and preview drawables.
- Add both providers to the Settings "Add widget" list.

## 4. Localization

Add new keys to all 5 ARB files (`en`, `es`, `it`, `pt`, `zh`) and run
`flutter gen-l10n`. Keep the existing key-parity test green (pt/zh stay English
copies).

## 5. Testing

- Engine unit tests: bump / hold / reduce / first-time, rounding rules,
  set-kind filtering, units + plate selection, empty/missing data.
- State tests: `nextSetHints` with plan-range vs fallback target, empty
  history, freestyle workouts.
- Data-builder tests: `buildTodayCard` for planned day / rest day / no plan.
- No plugin calls in tests; widget views pumped directly with sample data.
- Run full `flutter analyze` + full `flutter test` after wiring.

## 6. Out of scope (deferred)

- Tap-to-start from widget (requires native click-through wiring).
- Weekly check-in / deload advice and guided periodized plans (the engine is
  reusable for these later).