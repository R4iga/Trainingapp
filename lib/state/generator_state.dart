part of 'fit_state.dart';

/// State for the AI-style workout plan generator.
///
/// Holds the user's week configuration (muscles per day, rest days,
/// preferences), a working draft `WorkoutPlan` and the operations to generate
/// the week with the deterministic engine. Plans are saved through the normal
/// [PlansState] pipeline, so they behave exactly like hand-built plans.
mixin GeneratorState on FitCore, LibraryState, PlansState {
  /// Muscle ids selected per weekday (Monday = 1 … Sunday = 7).
  final Map<int, List<String>> genMuscles = {};

  /// Weekdays that should stay empty (rest days).
  final Set<int> genRestDays = {};

  WorkoutPrefs genPrefs = WorkoutPrefs.defaults;

  /// The work-in-progress generated week. `null` until the first day generates.
  WorkoutPlan? genDraft;

  // ---- Navigation ---------------------------------------------------------

  void goGenerator() => pushRoute('plan-generator');

  void backFromGenerator() {
    genDraft = null;
    popRoute(fallback: 'plans');
  }

  // ---- Week configuration ---------------------------------------------------

  void toggleGenMuscle(int w, String muscle) {
    final list = genMuscles[w] ?? [];
    if (list.contains(muscle)) {
      list.remove(muscle);
      if (list.isEmpty) genMuscles.remove(w);
    } else {
      genMuscles[w] = [...list, muscle];
    }
    genDraft = null;
    _persist();
    notifyListeners();
  }

  bool genDayHas(int w, String muscle) =>
      (genMuscles[w] ?? const []).contains(muscle);

  void clearGenMuscles() {
    genMuscles.clear();
    genDraft = null;
    _persist();
    notifyListeners();
  }

  void toggleGenRest(int w) {
    if (genRestDays.contains(w)) {
      genRestDays.remove(w);
    } else {
      genRestDays.add(w);
      final day = genDraft?.days[w - 1];
      if (day != null) day.exercises = const [];
    }
    genDraft = null;
    _persist();
    notifyListeners();
  }

  /// Applies an entire-week preset (PPL, Upper/Lower, …) and clears any
  /// previously selected muscles.
  void applyGenPreset(GenStyle style) {
    genPrefs = genPrefs.copyWith(style: style);
    genMuscles.clear();
    kGenPresetFor(style).forEach((w, list) {
      if (list.isNotEmpty) genMuscles[w] = List.of(list);
    });
    genDraft = null;
    _persist();
    notifyListeners();
  }

  void setGenPrefs(WorkoutPrefs prefs) {
    genPrefs = prefs;
    genDraft = null;
    _persist();
    notifyListeners();
  }

  // ---- Draft ----------------------------------------------------------------

  WorkoutPlanDay? genDraftDay(int w) {
    if (genDraft == null || w < 1 || w > 7) return null;
    return genDraft!.days[w - 1];
  }

  void _ensureGenDraft() {
    if (genDraft != null) return;
    genDraft = WorkoutPlan(
      id: 'gen-draft',
      name: '',
      source: 'custom',
      days: [
        for (final w in kWeekdays)
          WorkoutPlanDay(
            name: t.weekday(w),
            muscles: List<String>.from(genMuscles[w] ?? const []),
            exercises: const [],
          ),
      ],
    );
  }

  /// Weekly context for the engine, computed from already-generated days
  /// before [currentDay] so volume and exercise use stay balanced.
  GenContext _genContext(int currentDay) {
    final used = <String>{};
    final weeklySets = <String, int>{};
    final last = <String, int>{};
    for (final w in kWeekdays) {
      if (w >= currentDay) break;
      if (genRestDays.contains(w)) continue;
      final d = genDraft?.days[w - 1];
      if (d == null) continue;
      for (final m in d.muscles) {
        if (!last.containsKey(m)) last[m] = w;
      }
      for (final e in d.exercises) {
        used.add(e.exerciseId);
        weeklySets[e.primary] = (weeklySets[e.primary] ?? 0) + e.sets;
        if (!last.containsKey(e.primary)) last[e.primary] = w;
      }
    }
    return GenContext(
      usedExerciseIds: used,
      weeklySets: weeklySets,
      lastTrainedDay: last,
      currentDay: currentDay,
    );
  }

  void _writeGenDay(int w, List<WorkoutPlanExercise> exercises) {
    final day = genDraft!.days[w - 1];
    day.exercises = exercises;
    day.muscles = List<String>.from(genMuscles[w] ?? const []);
  }

  // ---- Generation ------------------------------------------------------------

  /// Regenerates one day. Uses the day's current exercises as an "avoid" set,
  /// so regenerating visibly swaps movements instead of repeating them.
  void generateGenDay(int w) {
    final muscles = genMuscles[w] ?? const [];
    if (muscles.isEmpty || genRestDays.contains(w)) return;
    _ensureGenDraft();
    final day = genDraft!.days[w - 1];
    final req = GenRequest(
      prefs: genPrefs,
      muscles: muscles,
      context: _genContext(w),
      avoidIds: {for (final e in day.exercises) e.exerciseId},
    );
    _writeGenDay(w, buildGenDay(req, allExercises));
    _persist();
    notifyListeners();
  }

  /// Generates every configured day of the week in order, letting each day
  /// see the volume/exercises of the days before it.
  void generateGenWeek() {
    _ensureGenDraft();
    for (final w in kWeekdays) {
      final muscles = genMuscles[w] ?? const [];
      final day = genDraft!.days[w - 1];
      if (muscles.isEmpty || genRestDays.contains(w)) {
        day.exercises = const [];
        day.muscles = List<String>.from(muscles);
        continue;
      }
      final req = GenRequest(
        prefs: genPrefs,
        muscles: muscles,
        context: _genContext(w),
        avoidIds: {for (final e in day.exercises) e.exerciseId},
      );
      _writeGenDay(w, buildGenDay(req, allExercises));
    }
    _persist();
    notifyListeners();
  }

  // ---- Draft editing ----------------------------------------------------------

  void replaceGenExercise(int w, int index) {
    final day = genDraftDay(w);
    if (day == null || index < 0 || index >= day.exercises.length) return;
    final cur = day.exercises[index];
    final muscles = genMuscles[w] ?? const [];
    final muscle = muscles.contains(cur.primary)
        ? cur.primary
        : (muscles.isNotEmpty ? muscles.first : cur.primary);
    final req = GenRequest(
      prefs: genPrefs,
      muscles: muscles,
      context: _genContext(w),
      avoidIds: {for (final e in day.exercises) e.exerciseId},
    );
    final next = replaceOneGenExercise(req, allExercises, muscle, cur.exerciseId);
    if (next == null) return;
    day.exercises[index] = next;
    _persist();
    notifyListeners();
  }

  void updateGenExercise(
    int w,
    int index,
    WorkoutPlanExercise Function(WorkoutPlanExercise) update,
  ) {
    final day = genDraftDay(w);
    if (day == null || index < 0 || index >= day.exercises.length) return;
    day.exercises[index] = update(day.exercises[index]);
    _persist();
    notifyListeners();
  }

  void removeGenExercise(int w, int index) {
    final day = genDraftDay(w);
    if (day == null || index < 0 || index >= day.exercises.length) return;
    day.exercises.removeAt(index);
    _persist();
    notifyListeners();
  }

  void reorderGenExercise(int w, int from, int to) {
    final exs = genDraftDay(w)?.exercises;
    if (exs == null || from < 0 || from >= exs.length) return;
    if (to > from) to -= 1;
    exs.insert(to.clamp(0, exs.length), exs.removeAt(from));
    _persist();
    notifyListeners();
  }

  void clearGenDay(int w) {
    final day = genDraftDay(w);
    if (day == null) return;
    day.exercises = const [];
    _persist();
    notifyListeners();
  }

  // ---- Saving ------------------------------------------------------------------

  /// Saves the generated week as a normal plan, reusing the PlansState
  /// pipeline. Returns the new plan id.
  String saveGenAsPlan() {
    _ensureGenDraft();
    final now = DateTime.now();
    final id = 'p${now.microsecondsSinceEpoch}';
    final days = <WorkoutPlanDay>[];
    for (final w in kWeekdays) {
      final rest = genRestDays.contains(w);
      final muscles = List<String>.from(genMuscles[w] ?? const []);
      final exercises = rest
          ? const <WorkoutPlanExercise>[]
          : List<WorkoutPlanExercise>.of(genDraft!.days[w - 1].exercises);
      if (muscles.isEmpty && exercises.isEmpty) continue;
      days.add(WorkoutPlanDay(
        name: t.weekday(w),
        muscles: muscles,
        exercises: exercises,
      ));
    }
    if (days.isEmpty) return '';
    plans.add(WorkoutPlan(
      id: id,
      name: '',
      goal: genPrefs.goal,
      difficulty: genPrefs.difficulty,
      days: days,
      createdAt: now,
      updatedAt: now,
      source: 'custom',
    ));
    genDraft = null;
    _persist();
    notifyListeners();
    return id;
  }

  // ---- Persistence -----------------------------------------------------------------

  void _loadGenerator(Map<String, dynamic> data) {
    genMuscles.clear();
    ((data['genMuscles'] as Map?) ?? const {}).forEach((k, v) {
      final w = int.tryParse(k as String);
      if (w != null) genMuscles[w] = ((v as List?) ?? const []).cast<String>();
    });
    genRestDays
      ..clear()
      ..addAll(((data['genRest'] as List?) ?? const []).cast<int>());
    genPrefs = WorkoutPrefs.fromJson(
        (data['genPrefs'] as Map?)?.cast<String, dynamic>() ?? const {});
    final rawDays = data['genDraft'] as List?;
    if (rawDays != null && rawDays.isNotEmpty) {
      genDraft = WorkoutPlan(
        id: 'gen-draft',
        name: '',
        source: 'custom',
        days: rawDays
            .map((d) => WorkoutPlanDay.fromJson((d as Map).cast<String, dynamic>()))
            .toList(),
      );
    }
  }

  void _resetGenerator() {
    genMuscles.clear();
    genRestDays.clear();
    genPrefs = WorkoutPrefs.defaults;
    genDraft = null;
  }
}