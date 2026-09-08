part of 'fit_state.dart';

/// State management for saved workout plans.
///
/// Plans live alongside routines in the app's persisted store. The library
/// holds a set of built-in (offline) programs that can be imported into the
/// user's own plans without overwriting them.
mixin PlansState on FitCore, LibraryState {
  final List<WorkoutPlan> plans = [];
  final List<WorkoutPlan> libraryPlans = [];
  bool _libraryLoaded = false;
  String? activePlanId;
  String? activeLibraryPlanId;

  /// Build the offline program library from the structured [kProgramLibrary]
  /// data, resolving exercise names against the catalog.
  void _ensureLibrary() {
    if (_libraryLoaded) return;
    _libraryLoaded = true;
    libraryPlans.clear();
    for (final def in kProgramLibrary) {
      libraryPlans.add(_buildLibraryPlan(def));
    }
  }

  WorkoutPlan _buildLibraryPlan(ProgramDef def) {
    final days = <WorkoutPlanDay>[];
    for (final d in def.days) {
      final exs = <WorkoutPlanExercise>[];
      for (final e in d.exercises) {
        final ex = matchExercise(e.name, allExercises);
        final primary = ex?.primary ?? guessMuscle(e.name) ?? 'other';
        exs.add(WorkoutPlanExercise(
          exerciseId: ex?.id ?? 'lib:${e.name}',
          name: ex?.name ?? e.name,
          primary: primary,
          sets: e.sets,
          reps: e.reps,
          repsMax: e.repsMax,
          restSeconds: e.restSeconds,
        ));
      }
      days.add(WorkoutPlanDay(name: d.name, exercises: exs));
    }
    return WorkoutPlan(
      id: 'lib-${def.id}',
      name: def.name,
      description: def.description,
      goal: def.goal,
      difficulty: def.difficulty,
      days: days,
      source: 'library',
    );
  }

  // ---- Navigation ---------------------------------------------------------

  void goPlans() => pushRoute('plans');

  void backFromPlans() => popRoute();

  void openPlan(String id) {
    activePlanId = id;
    pushRoute('plan-edit');
  }

  void closePlanEdit() => popRoute(fallback: 'plans');

  void openLibrary() => pushRoute('plan-library');

  void backFromLibrary() => popRoute(fallback: 'plans');

  // ---- Lookup -------------------------------------------------------------

  WorkoutPlan? _plan(String id) {
    for (final p in plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  WorkoutPlan? _libraryPlan(String id) {
    _ensureLibrary();
    for (final p in libraryPlans) {
      if (p.id == id) return p;
    }
    return null;
  }

  WorkoutPlan? get activePlan => _plan(activePlanId ?? '');

  WorkoutPlan? get activeLibraryPlan => _libraryPlan(activeLibraryPlanId ?? '');

  List<WorkoutPlan> get visiblePlans =>
      plans.where((p) => !p.archived).toList();

  List<WorkoutPlan> get archivedPlans => plans.where((p) => p.archived).toList();

  List<WorkoutPlanExercise> planExercises(WorkoutPlan plan) =>
      plan.days.expand((d) => d.exercises).toList();

  // ---- CRUD ---------------------------------------------------------------

  String createPlan([String name = '']) {
    final now = DateTime.now();
    final id = 'p${now.microsecondsSinceEpoch}';
    plans.add(WorkoutPlan(
      id: id,
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
    ));
    _persist();
    notifyListeners();
    return id;
  }

  WorkoutPlan duplicatePlan(String id, {String? newName}) {
    final src = _plan(id);
    if (src == null) {
      // fall back to a library plan (shared copy)
      final lib = _libraryPlan(id);
      if (lib == null) return _emptyPlan();
      return _copyToPlans(lib, newName: newName ?? '${lib.name} (Copy)');
    }
    final now = DateTime.now();
    final copy = WorkoutPlan(
      id: 'p${now.microsecondsSinceEpoch}',
      name: newName ?? '${src.name} (Copy)',
      description: src.description,
      goal: src.goal,
      difficulty: src.difficulty,
      days: src.days.map((d) => WorkoutPlanDay(name: d.name, exercises: List.of(d.exercises))).toList(),
      createdAt: now,
      updatedAt: now,
      source: 'custom',
    );
    plans.add(copy);
    _persist();
    notifyListeners();
    return copy;
  }

  WorkoutPlan _emptyPlan() {
    final now = DateTime.now();
    return WorkoutPlan(
      id: 'p${now.microsecondsSinceEpoch}',
      name: 'Copy',
      createdAt: now,
      updatedAt: now,
    );
  }

  WorkoutPlan _copyToPlans(WorkoutPlan src, {String? newName}) {
    final now = DateTime.now();
    final copy = WorkoutPlan(
      id: 'p${now.microsecondsSinceEpoch}',
      name: newName ?? '${src.name} (Copy)',
      description: src.description,
      goal: src.goal,
      difficulty: src.difficulty,
      days: src.days.map((d) => WorkoutPlanDay(name: d.name, exercises: List.of(d.exercises))).toList(),
      createdAt: now,
      updatedAt: now,
      creator: src.creator,
      source: 'custom',
      importCode: src.importCode,
    );
    plans.add(copy);
    _persist();
    notifyListeners();
    return copy;
  }

  void renamePlan(String id, String name) {
    final p = _plan(id);
    if (p == null) return;
    p.name = name.trim();
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void setPlanDescription(String id, String description) {
    final p = _plan(id);
    if (p == null) return;
    p.description = description.trim();
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void setPlanGoal(String id, PlanGoal goal) {
    final p = _plan(id);
    if (p == null) return;
    p.goal = goal;
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void setPlanDifficulty(String id, String difficulty) {
    final p = _plan(id);
    if (p == null) return;
    p.difficulty = difficulty;
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void togglePlanFavorite(String id) {
    final p = _plan(id);
    if (p == null) return;
    p.favorite = !p.favorite;
    _persist();
    notifyListeners();
  }

  void archivePlan(String id) {
    final p = _plan(id);
    if (p == null) return;
    p.archived = true;
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void unarchivePlan(String id) {
    final p = _plan(id);
    if (p == null) return;
    p.archived = false;
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void deletePlan(String id) {
    plans.removeWhere((p) => p.id == id);
    if (activePlanId == id) activePlanId = null;
    _persist();
    notifyListeners();
  }

  // ---- Day / exercise editing ----------------------------------------------

  void addPlanDay(String id, [String name = '']) {
    final p = _plan(id);
    if (p == null) return;
    final name2 = name.trim().isEmpty ? 'Day ${p.days.length + 1}' : name.trim();
    p.days.add(WorkoutPlanDay(name: name2, exercises: []));
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void renamePlanDay(String id, int dayIndex, String name) {
    final p = _plan(id);
    if (p == null || dayIndex < 0 || dayIndex >= p.days.length) return;
    p.days[dayIndex].name = name.trim();
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void removePlanDay(String id, int dayIndex) {
    final p = _plan(id);
    if (p == null || dayIndex < 0 || dayIndex >= p.days.length) return;
    p.days.removeAt(dayIndex);
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void reorderPlanDays(String id, int from, int to) {
    final d = _plan(id)?.days;
    if (d == null || from < 0 || from >= d.length) return;
    if (to > from) to -= 1;
    d.insert(to.clamp(0, d.length), d.removeAt(from));
    persistNow();
    notifyListeners();
  }

  void addPlanExercise(String id, int dayIndex, String exerciseId) {
    final p = _plan(id);
    if (p == null || dayIndex < 0 || dayIndex >= p.days.length) return;
    final ex = exerciseById(exerciseId);
    if (ex == null) return;
    final cfg = WorkoutPlanExercise(
      exerciseId: ex.id,
      name: ex.name,
      primary: ex.primary,
    );
    p.days[dayIndex].exercises.add(cfg);
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void removePlanExercise(String id, int dayIndex, int exIndex) {
    final p = _plan(id);
    if (p == null || dayIndex < 0 || dayIndex >= p.days.length) return;
    final d = p.days[dayIndex];
    if (exIndex < 0 || exIndex >= d.exercises.length) return;
    d.exercises.removeAt(exIndex);
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void reorderPlanExercise(String id, int dayIndex, int from, int to) {
    final p = _plan(id);
    if (p == null || dayIndex < 0 || dayIndex >= p.days.length) return;
    final exs = p.days[dayIndex].exercises;
    if (from < 0 || from >= exs.length) return;
    if (to > from) to -= 1;
    exs.insert(to.clamp(0, exs.length), exs.removeAt(from));
    p.updatedAt = DateTime.now();
    persistNow();
    notifyListeners();
  }

  void updatePlanExercise(
    String id,
    int dayIndex,
    int exIndex,
    WorkoutPlanExercise Function(WorkoutPlanExercise) update,
  ) {
    final p = _plan(id);
    if (p == null || dayIndex < 0 || dayIndex >= p.days.length) return;
    final d = p.days[dayIndex];
    if (exIndex < 0 || exIndex >= d.exercises.length) return;
    d.exercises[exIndex] = update(d.exercises[exIndex]);
    p.updatedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  // ---- Library import ------------------------------------------------------

  WorkoutPlan importLibraryPlan(String libraryId) =>
      duplicatePlan(libraryId);

  // ---- Plan transfer (export / share / codes) -------------------------------

  Map<String, dynamic> planExportJson(String id) {
    final p = _plan(id);
    if (p == null) return {};
    return {'gymmane_plan': 1, 'plan': p.toJson()};
  }

  /// Build a compact, reversible import code: `GYM-<id36>-<days>`
  ///
  /// The id is base36 encoded (upper-case, with leading zeros truncated on
  /// decode). This lets another install / friend re-import the same plan by
  /// rebuilding the id deterministically.
  String planImportCode(String id) {
    final src = _plan(id);
    if (src == null) return '';
    final code = _encodeId(src.id);
    final days = src.days.length.clamp(2, 9).toString();
    return 'GYM-$code-$days';
  }

  /// Rebuild a plan id from its import code, or null if the code is malformed.
  String? planIdFromCode(String raw) {
    final m = RegExp(r'^GYM-([A-Z0-9_-]+)-(\d)$').firstMatch(raw.trim().toUpperCase());
    if (m == null) return null;
    return _decodeId(m.group(1)!);
  }

  static String _encodeId(String id) {
    // Plan ids look like "p1234567890123". Encode the digits to base36.
    final digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty
        ? id.codeUnits.map((c) => c.toRadixString(16)).join()
        : int.parse(digits).toRadixString(36).toUpperCase();
  }

  static String _decodeId(String code) {
    try {
      final n = int.parse(code, radix: 36);
      return 'p$n';
    } catch (_) {
      return '';
    }
  }
}
