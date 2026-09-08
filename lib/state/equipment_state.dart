part of 'fit_state.dart';

/// State for user-owned equipment and the recommendation engine.
///
/// `userEquipment` tracks what equipment the user personally has access to
/// (e.g. at home). This is distinct from place-based gear (gyms with their
/// own equipment lists).
mixin EquipmentState on FitCore, LibraryState, PlansState, StatsState {
  void goEquipment() => pushRoute('equipment');
  void backFromEquipment() => popRoute(fallback: 'home');
  /// Toggle a piece of equipment in the user's personal inventory.
  void toggleUserEquipment(String eq) {
    if (userEquipment.contains(eq)) {
      userEquipment.remove(eq);
    } else {
      userEquipment.add(eq);
    }
    _persist();
    notifyListeners();
  }

  /// Whether the user owns (or has access to) a given equipment type.
  bool hasEquipment(String eq) {
    if (eq == 'Bodyweight') return true;
    return userEquipment.contains(eq);
  }

  /// Replace the user's entire equipment list with a preset set.
  void applyEquipmentPreset(Set<String> preset) {
    userEquipment
      ..clear()
      ..addAll(preset);
    _persist();
    notifyListeners();
  }

  /// Whether the user can perform a given exercise with their equipment.
  bool canDoExercise(Exercise ex) => hasEquipment(ex.equipment);

  /// Total number of exercises the user can perform with their equipment.
  int get exercisableCount =>
      allExercises.where(canDoExercise).length;

  /// Recommend exercises for a muscle group given the user's equipment.
  ///
  /// Prioritises favourites, then exercises with logged history, then new ones.
  List<Exercise> recommendForMuscle(String muscle, {int limit = 6}) {
    final pool = allExercises
        .where((ex) =>
            (ex.primary == muscle || ex.secondary.contains(muscle)) &&
            canDoExercise(ex))
        .toList();
    pool.sort((a, b) {
      int rank(Exercise e) {
        if (favorites[e.id] == true) return 0;
        if (exerciseHistory(e.id).isNotEmpty) return 1;
        return 2;
      }

      return rank(a).compareTo(rank(b));
    });
    return pool.take(limit).toList();
  }

  /// Check which exercises in a plan need equipment the user doesn't have.
  ///
  /// Returns a list of (exerciseId, exerciseName, missingEquipment) triples.
  List<(String id, String name, String missing)> planEquipmentIssues(
      WorkoutPlan plan) {
    final issues = <(String, String, String)>[];
    for (final day in plan.days) {
      for (final pe in day.exercises) {
        final ex = exerciseById(pe.exerciseId);
        if (ex != null && !canDoExercise(ex)) {
          issues.add((ex.id, ex.name, ex.equipment));
        }
      }
    }
    return issues;
  }

  /// For a given exercise that the user CAN'T do, find alternatives they CAN do
  /// that target the same muscles, sorted by favourite → history → new.
  List<Exercise> equipmentAlternatives(Exercise ex, {int limit = 3}) {
    final pool = allExercises
        .where((e) =>
            e.id != ex.id &&
            (e.primary == ex.primary || ex.secondary.contains(ex.primary)) &&
            canDoExercise(e))
        .toList();
    pool.sort((a, b) {
      int rank(Exercise e) {
        if (favorites[e.id] == true) return 0;
        if (exerciseHistory(e.id).isNotEmpty) return 1;
        return 2;
      }

      return rank(a).compareTo(rank(b));
    });
    return pool.take(limit).toList();
  }

  /// Find library plans compatible with the user's equipment.
  ///
  /// A plan is compatible if all its exercises can be performed with the
  /// user's equipment. Returns plans sorted by compatibility (fully
  /// compatible first), then by category.
  List<WorkoutPlan> compatibleLibraryPlans() {
    _ensureLibrary();
    return libraryPlans.where((plan) {
      for (final day in plan.days) {
        for (final pe in day.exercises) {
          final ex = exerciseById(pe.exerciseId);
          if (ex != null && !canDoExercise(ex)) return false;
        }
      }
      return true;
    }).toList();
  }

  /// Build a set of muscles the user has covered with their equipment.
  Set<String> get availableMuscleCoverage {
    final covered = <String>{};
    for (final ex in allExercises) {
      if (canDoExercise(ex)) {
        covered.add(ex.primary);
        covered.addAll(ex.secondary);
      }
    }
    return covered;
  }

  /// Suggest a full workout split based on available equipment.
  ///
  /// Returns a list of (focus, exercises) where focus is a muscle family name.
  List<(String focus, List<Exercise> exercises)> suggestSplit({int exPerFocus = 4}) {
    const families = [
      ('Chest & Triceps', ['chest', 'triceps']),
      ('Back & Biceps', ['back', 'biceps']),
      ('Legs', ['quads', 'hamstrings', 'glutes', 'calves']),
      ('Shoulders & Core', ['shoulders', 'abdomen']),
    ];
    final suggestions = <(String, List<Exercise>)>[];
    for (final (name, muscles) in families) {
      final exs = <Exercise>[];
      for (final m in muscles) {
        exs.addAll(recommendForMuscle(m, limit: 2));
      }
      if (exs.isNotEmpty) {
        suggestions.add((name, exs.take(exPerFocus).toList()));
      }
    }
    return suggestions;
  }
}
