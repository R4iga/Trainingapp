/// Saved workout plan model.
///
/// A `WorkoutPlan` is a day-split program the user can build, save and start.
/// It extends the app's routine concept with metadata (goal, difficulty,
/// schedule) and per-day, per-exercise configuration (sets, reps, rest, RPE).
///
/// Plans are immutable-friendly value objects serialized with short keys,
/// matching the conventions used by the other models in this app.
library;

/// Goal of a plan. Stored as a stable id for localization.
enum PlanGoal { muscleGain, strength, generalFitness, beginner, fatLoss, maintenance }

PlanGoal planGoalFrom(Object? raw, {PlanGoal fallback = PlanGoal.generalFitness}) {
  final s = raw as String?;
  for (final g in PlanGoal.values) {
    if (g.name == s) return g;
  }
  return fallback;
}

/// Difficulty of a plan, aligned with the exercise difficulty ids.
const List<String> kPlanDifficulties = ['Beginner', 'Intermediate', 'Advanced'];

/// A single configured exercise inside a plan day.
class WorkoutPlanExercise {
  const WorkoutPlanExercise({
    required this.exerciseId,
    required this.name,
    required this.primary,
    this.sets = 3,
    this.reps = 10,
    this.repsMax,
    this.weight,
    this.rpe,
    this.restSeconds,
    this.warmup = false,
    this.dropSet = false,
    this.toFailure = false,
    this.notes = '',
  });

  final String exerciseId;
  final String name;
  final String primary;
  final int sets;
  final int reps;
  final int? repsMax;
  final double? weight;
  final double? rpe;
  final int? restSeconds;
  final bool warmup;
  final bool dropSet;
  final bool toFailure;
  final String notes;

  int get repsTarget => repsMax ?? reps;
  String get repRange => repsMax == null ? '$reps' : '$reps-$repsMax';

  WorkoutPlanExercise copyWith({
    int? sets,
    int? reps,
    int? repsMax,
    double? weight,
    double? rpe,
    int? restSeconds,
    bool? warmup,
    bool? dropSet,
    bool? toFailure,
    String? notes,
  }) =>
      WorkoutPlanExercise(
        exerciseId: exerciseId,
        name: name,
        primary: primary,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        repsMax: repsMax ?? this.repsMax,
        weight: weight ?? this.weight,
        rpe: rpe ?? this.rpe,
        restSeconds: restSeconds ?? this.restSeconds,
        warmup: warmup ?? this.warmup,
        dropSet: dropSet ?? this.dropSet,
        toFailure: toFailure ?? this.toFailure,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': exerciseId,
        'n': name,
        'p': primary,
        's': sets,
        'r': reps,
        if (repsMax != null) 'rm': repsMax,
        if (weight != null) 'w': weight,
        if (rpe != null) 'rpe': rpe,
        if (restSeconds != null) 'rest': restSeconds,
        if (warmup) 'wu': true,
        if (dropSet) 'ds': true,
        if (toFailure) 'tf': true,
        if (notes.isNotEmpty) 'no': notes,
      };

  factory WorkoutPlanExercise.fromJson(Map<String, dynamic> j) => WorkoutPlanExercise(
        exerciseId: j['id'] as String,
        name: (j['n'] as String?) ?? '',
        primary: (j['p'] as String?) ?? 'other',
        sets: (j['s'] as num?)?.toInt() ?? 3,
        reps: (j['r'] as num?)?.toInt() ?? 10,
        repsMax: (j['rm'] as num?)?.toInt(),
        weight: (j['w'] as num?)?.toDouble(),
        rpe: (j['rpe'] as num?)?.toDouble(),
        restSeconds: (j['rest'] as num?)?.toInt(),
        warmup: j['wu'] == true,
        dropSet: j['ds'] == true,
        toFailure: j['tf'] == true,
        notes: (j['no'] as String?) ?? '',
      );
}

/// A single day within a plan (e.g. "Push", "Pull", "Legs").
class WorkoutPlanDay {
  WorkoutPlanDay({
    required this.name,
    required this.exercises,
  });

  String name;
  List<WorkoutPlanExercise> exercises;

  Map<String, dynamic> toJson() => {
        'n': name,
        'ex': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutPlanDay.fromJson(Map<String, dynamic> j) => WorkoutPlanDay(
        name: (j['n'] as String?) ?? '',
        exercises: ((j['ex'] as List?) ?? const [])
            .map((e) => WorkoutPlanExercise.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// A complete saved workout plan.
class WorkoutPlan {
  WorkoutPlan({
    required this.id,
    required this.name,
    this.description = '',
    this.goal = PlanGoal.generalFitness,
    this.difficulty = 'Beginner',
    this.days = const [],
    this.archived = false,
    this.favorite = false,
    this.createdAt,
    this.updatedAt,
    this.creator = '',
    this.source = 'custom',
    this.importCode = '',
  });

  final String id;
  String name;
  String description;
  PlanGoal goal;
  String difficulty;
  List<WorkoutPlanDay> days;
  bool archived;
  bool favorite;
  DateTime? createdAt;
  DateTime? updatedAt;
  String creator;
  String source; // 'custom' | 'library' | 'imported' | 'shared'
  String importCode;

  int get dayCount => days.length;
  int get totalExercises => days.fold(0, (s, d) => s + d.exercises.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'n': name,
        if (description.isNotEmpty) 'd': description,
        'g': goal.name,
        'df': difficulty,
        'days': days.map((d) => d.toJson()).toList(),
        if (archived) 'a': true,
        if (favorite) 'f': true,
        if (createdAt != null) 'c': createdAt!.toIso8601String(),
        if (updatedAt != null) 'u': updatedAt!.toIso8601String(),
        if (creator.isNotEmpty) 'cr': creator,
        if (source != 'custom') 'src': source,
        if (importCode.isNotEmpty) 'ic': importCode,
      };

  factory WorkoutPlan.fromJson(Map<String, dynamic> j) => WorkoutPlan(
        id: (j['id'] as String?) ?? 'p${DateTime.now().microsecondsSinceEpoch}',
        name: (j['n'] as String?) ?? '',
        description: (j['d'] as String?) ?? '',
        goal: planGoalFrom(j['g']),
        difficulty: (j['df'] as String?) ?? 'Beginner',
        days: ((j['days'] as List?) ?? const [])
            .map((e) => WorkoutPlanDay.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        archived: j['a'] == true,
        favorite: j['f'] == true,
        createdAt: j['c'] != null ? DateTime.tryParse(j['c'] as String) : null,
        updatedAt: j['u'] != null ? DateTime.tryParse(j['u'] as String) : null,
        creator: (j['cr'] as String?) ?? '',
        source: (j['src'] as String?) ?? 'custom',
        importCode: (j['ic'] as String?) ?? '',
      );
}
