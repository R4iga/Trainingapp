import 'dart:math' as math;

import '../models/exercise.dart';
import '../models/generator.dart';
import '../models/workout_plan.dart';

final math.Random _rng = math.Random();

/// Equipment allowed per availability preset. `null` = everything.
const Map<GenEquipment, Set<String>?> kGenEquipmentAllow = {
  GenEquipment.fullGym: null,
  GenEquipment.basic: {
    'Barbell',
    'Dumbbell',
    'Cable',
    'Machine',
    'Bodyweight',
    'Weighted',
    'Band',
    'Kettlebell',
  },
  GenEquipment.home: {'Dumbbell', 'Bodyweight', 'Weighted', 'Band', 'Kettlebell'},
};

/// Approximate capacity for a session length (in exercises).
int genExerciseCount(int minutes) {
  if (minutes <= 20) return 4;
  if (minutes <= 30) return 5;
  if (minutes <= 45) return 7;
  if (minutes <= 60) return 8;
  if (minutes <= 75) return 10;
  return 11;
}

/// Scales a base set count down for shorter sessions.
int _trimSets(int sets, int minutes) {
  var out = sets;
  if (minutes <= 20) out -= 1;
  if (minutes <= 30) {
    out -= 1;
  } else if (minutes <= 45) {
    // keep
  }
  return out.clamp(2, 8);
}

bool _isMain(Exercise e, String muscle) {
  final label = e.name.toLowerCase();
  if (e.primary != muscle) return false;
  final sig = kGenSignatures[muscle];
  if (sig != null && sig.any((k) => label.contains(k))) return true;
  const words = [
    'press',
    'squat',
    'deadlift',
    'pull-up',
    'pull up',
    'pullup',
    'chin-up',
    'chin up',
    'chinup',
    'pulldown',
    'pull-down',
    'lunge',
    'dip',
    'bench',
    'thrust',
    'step-up',
    'step up',
    'clean',
    'snatch',
    'overhead',
    'swing',
    'carry',
    'farmer',
    'back extension',
    'hyperextension',
    'good morning',
    'row',
    'bridge',
    'hack squat',
    'split squat',
    'muscle up',
    'inverted row',
    'y raise',
  ];
  return words.any((w) => label.contains(w));
}

/// Candidate exercises for a muscle: anything that trains it primarily or
/// secondarily, so real compound movements are captured.
List<Exercise> _candidates(List<Exercise> pool, String muscle) =>
    pool.where((e) => e.primary == muscle || e.secondary.contains(muscle)).toList();

bool _equipmentOk(Exercise e, GenEquipment preset) {
  final allowed = kGenEquipmentAllow[preset];
  if (allowed == null) return true;
  return allowed.contains(e.equipment);
}

bool _difficultyOk(Exercise e, String difficulty) {
  if (difficulty != 'Beginner') return true;
  return e.difficulty != 'Advanced';
}

int _muscleIndex(String muscle) {
  final i = kGenMuscleOrder.indexOf(muscle);
  return i < 0 ? kGenMuscleOrder.length : i;
}

/// Maximum per-muscle exercises on a single day, honoring recovery and the
/// weekly set budget (~16 working sets per muscle per week).
int _allocCap(String muscle, GenContext ctx) {
  var cap = 3;
  if (ctx.lastTrainedDay[muscle] == ctx.currentDay - 1) cap = 2;
  final usedSets = ctx.weeklySets[muscle] ?? 0;
  final room = ((24 - usedSets) / 3).floor().clamp(1, 3);
  if (room < cap) cap = room;
  return cap;
}

Map<String, int> _allocate(List<String> muscles, int n, GenContext ctx) {
  final alloc = <String, int>{};
  for (final m in muscles) {
    alloc[m] = 1;
  }
  var remaining = n - muscles.length;
  if (remaining <= 0) return alloc;

  final order = List<String>.from(muscles)
    ..sort((a, b) => _muscleIndex(a).compareTo(_muscleIndex(b)));

  var guard = 300;
  var i = 0;
  while (remaining > 0 && guard > 0) {
    guard--;
    if (order.isEmpty) break;
    final m = order[i % order.length];
    i++;
    final cap = _allocCap(m, ctx);
    if (alloc[m]! >= cap) continue;
    alloc[m] = alloc[m]! + 1;
    remaining--;
  }
  return alloc;
}

({int sets, int repsLo, int repsHi, int rest}) _configFor(
  PlanGoal goal,
  bool isMain,
  String difficulty,
  int minutes,
) {
  var sets = isMain ? 4 : 3;
  int repsLo;
  int repsHi;
  int rest;

  switch (goal) {
    case PlanGoal.strength:
      sets = isMain ? 5 : 3;
      repsLo = isMain ? 3 : 8;
      repsHi = isMain ? 5 : 10;
      rest = isMain ? 180 : 120;
    case PlanGoal.muscleGain:
      repsLo = isMain ? 8 : 12;
      repsHi = isMain ? 12 : 15;
      rest = isMain ? 120 : 75;
    case PlanGoal.beginner:
      sets = isMain ? 3 : 2;
      repsLo = isMain ? 8 : 10;
      repsHi = isMain ? 12 : 15;
      rest = isMain ? 90 : 60;
    case PlanGoal.fatLoss:
      sets = 3;
      repsLo = isMain ? 10 : 12;
      repsHi = isMain ? 15 : 20;
      rest = isMain ? 60 : 45;
    case PlanGoal.generalFitness:
    case PlanGoal.maintenance:
      repsLo = isMain ? 8 : 10;
      repsHi = isMain ? 12 : 15;
      rest = isMain ? 90 : 60;
  }
  sets = _trimSets(sets, minutes);
  if (difficulty == 'Beginner') sets = math.max(2, sets - 1);
  return (sets: sets, repsLo: repsLo, repsHi: repsHi, rest: rest);
}

WorkoutPlanExercise _makeExercise(Exercise e, String muscle, WorkoutPrefs prefs) {
  final main = _isMain(e, muscle);
  final cfg = _configFor(prefs.goal, main, prefs.difficulty, prefs.durationMinutes);
  return WorkoutPlanExercise(
    exerciseId: e.id,
    name: e.name,
    primary: e.primary,
    sets: cfg.sets,
    reps: cfg.repsLo,
    repsMax: cfg.repsHi,
    restSeconds: cfg.rest,
  );
}

int _rank(Exercise e, String muscle, WorkoutPrefs prefs, Set<String> used, Set<String> avoid) {
  var score = 0;
  if (e.primary == muscle) score += 3;
  if (_isMain(e, muscle)) score += 2;
  if (e.difficulty == prefs.difficulty) score += 1;
  if (used.contains(e.id)) score -= 20;
  if (avoid.contains(e.id)) score -= 40;
  return score;
}

/// Picks a single exercise for [muscle], preferring primary-target movements
/// and avoiding ids in [used]/[avoid].
Exercise? _pickFor(
  List<Exercise> pool,
  String muscle,
  WorkoutPrefs prefs,
  Set<String> used,
  Set<String> avoid,
) {
  final all = _candidates(pool, muscle)
      .where((e) => _equipmentOk(e, prefs.equipment) && _difficultyOk(e, prefs.difficulty))
      .toList();
  if (all.isEmpty) return null;

  Exercise? best;
  var bestScore = -1 << 30;
  for (final e in all) {
    var s = _rank(e, muscle, prefs, used, avoid);
    s = s * 1000 + _rng.nextInt(1000);
    if (s > bestScore) {
      bestScore = s;
      best = e;
    }
  }
  return best;
}

/// Generates a full day of exercises for the requested muscles.
List<WorkoutPlanExercise> buildGenDay(GenRequest req, List<Exercise> pool) {
  final muscles = List<String>.from(req.muscles)..sort((a, b) => _muscleIndex(a).compareTo(_muscleIndex(b)));
  if (muscles.isEmpty) return const [];

  final n = genExerciseCount(req.prefs.durationMinutes);
  final alloc = _allocate(muscles, n, req.context);

  final chosen = <WorkoutPlanExercise>[];
  final dayIds = <String>{};
  final used = {...req.context.usedExerciseIds, ...req.avoidIds};

  for (final m in muscles) {
    final want = alloc[m] ?? 0;
    if (want <= 0) continue;
    var got = 0;
    var guard = 60;
    while (got < want && guard > 0) {
      guard--;
      final e = _pickFor(pool, m, req.prefs, used, dayIds);
      if (e == null) break;
      final ex = _makeExercise(e, m, req.prefs);
      dayIds.add(e.id);
      chosen.add(ex);
      got++;
    }
  }

  var list = _orderDay(chosen);
  list = _fitTime(list, req.prefs);
  if (list.isEmpty) list = _lastResort(pool, muscles, req.prefs);
  return list;
}

List<WorkoutPlanExercise> _orderDay(List<WorkoutPlanExercise> exs) {
  final sorted = List<WorkoutPlanExercise>.from(exs);
  sorted.sort((a, b) {
    final mi = _muscleIndex(a.primary).compareTo(_muscleIndex(b.primary));
    if (mi != 0) return mi;
    // compounds (main) before isolation inside the same muscle: keep the
    // original pick order which already favours main lifts first.
    return 0;
  });
  return sorted;
}

/// Estimates seconds needed for an exercise: work + rest per set + transition.
int _estSeconds(WorkoutPlanExercise e) {
  final work = e.repsMax != null && e.repsMax! >= 10 ? 35 : 45;
  final rest = e.restSeconds ?? 60;
  return e.sets * (work + rest) + 15;
}

int _daySeconds(List<WorkoutPlanExercise> exs) =>
    exs.fold(0, (s, e) => s + _estSeconds(e));

List<WorkoutPlanExercise> _fitTime(List<WorkoutPlanExercise> exs, WorkoutPrefs prefs) {
  final budget = prefs.durationMinutes * 60;
  var list = List<WorkoutPlanExercise>.from(exs);
  if (list.length <= 1) return list;

  var seconds = _daySeconds(list);
  // First reduce sets on the tail exercises (isolation/accessories).
  var guard = 200;
  while (seconds > budget && guard > 0 && list.length > 1) {
    guard--;
    final last = list.last;
    if (last.sets > 2) {
      final reduced = last.copyWith(sets: last.sets - 1);
      seconds -= _estSeconds(last) - _estSeconds(reduced);
      list[list.length - 1] = reduced;
    } else {
      seconds -= _estSeconds(last);
      list.removeLast();
    }
  }
  // Still over? Drop tail exercises until it fits (never leave an empty day).
  while (seconds > budget && list.length > 1) {
    seconds -= _estSeconds(list.last);
    list.removeLast();
  }
  return list;
}

List<WorkoutPlanExercise> _lastResort(List<Exercise> pool, List<String> muscles, WorkoutPrefs prefs) {
  final out = <WorkoutPlanExercise>[];
  final used = <String>{};
  for (final m in muscles) {
    final e = _pickFor(pool, m, prefs, used, const {});
    if (e == null) continue;
    used.add(e.id);
    out.add(_makeExercise(e, m, prefs));
  }
  return out;
}

/// Replaces a single exercise with a different valid one for the same muscle,
/// honouring the current preferences. Returns null when nothing else fits.
WorkoutPlanExercise? replaceOneGenExercise(
  GenRequest req,
  List<Exercise> pool,
  String muscle,
  String currentId,
) {
  final all = _candidates(pool, muscle)
      .where((e) => _equipmentOk(e, req.prefs.equipment) && _difficultyOk(e, req.prefs.difficulty))
      .toList();
  final avoid = {...req.avoidIds, currentId};
  Exercise? best;
  var bestScore = -1 << 30;
  for (final e in all) {
    if (e.id == currentId) continue;
    var s = _rank(e, muscle, req.prefs, req.context.usedExerciseIds, avoid);
    s = s * 1000 + _rng.nextInt(1000);
    if (s > bestScore) {
      bestScore = s;
      best = e;
    }
  }
  if (best == null) return null;
  return _makeExercise(best, muscle, req.prefs);
}