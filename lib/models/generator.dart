import 'workout_plan.dart';

/// Style presets that pre-fill a whole week of muscle selections.
enum GenStyle { ppl, upperLower, fullBody, bro, arnold, custom }

GenStyle genStyleFrom(Object? raw, {GenStyle fallback = GenStyle.custom}) {
  final s = raw as String?;
  for (final g in GenStyle.values) {
    if (g.name == s) return g;
  }
  return fallback;
}

/// Equipment availability for generated workouts.
enum GenEquipment { fullGym, basic, home }

GenEquipment genEquipmentFrom(Object? raw, {GenEquipment fallback = GenEquipment.fullGym}) {
  final s = raw as String?;
  for (final g in GenEquipment.values) {
    if (g.name == s) return g;
  }
  return fallback;
}

/// User preferences for the workout plan generator.
class WorkoutPrefs {
  const WorkoutPrefs({
    this.goal = PlanGoal.muscleGain,
    this.difficulty = 'Intermediate',
    this.durationMinutes = 60,
    this.equipment = GenEquipment.fullGym,
    this.style = GenStyle.custom,
  });

  static const defaults = WorkoutPrefs();

  final PlanGoal goal;
  final String difficulty;
  final int durationMinutes;
  final GenEquipment equipment;
  final GenStyle style;

  WorkoutPrefs copyWith({
    PlanGoal? goal,
    String? difficulty,
    int? durationMinutes,
    GenEquipment? equipment,
    GenStyle? style,
  }) =>
      WorkoutPrefs(
        goal: goal ?? this.goal,
        difficulty: difficulty ?? this.difficulty,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        equipment: equipment ?? this.equipment,
        style: style ?? this.style,
      );

  Map<String, dynamic> toJson() => {
        'g': goal.name,
        'd': difficulty,
        'l': durationMinutes,
        'e': equipment.name,
        's': style.name,
      };

  factory WorkoutPrefs.fromJson(Map<String, dynamic> j) => WorkoutPrefs(
        goal: planGoalFrom(j['g'], fallback: PlanGoal.muscleGain),
        difficulty: (j['d'] as String?) ?? 'Intermediate',
        durationMinutes: (j['l'] as num?)?.toInt() ?? 60,
        equipment: genEquipmentFrom(j['e']),
        style: genStyleFrom(j['s']),
      );
}

/// Weekly context the generator uses to keep the whole week coherent.
///
/// Tracks which exercises were already used, the per-muscle weekly set volume
/// and the last day each muscle was trained so the generator can avoid
/// back-to-back excessive volume and exercise duplication across the week.
class GenContext {
  const GenContext({
    this.usedExerciseIds = const {},
    this.weeklySets = const {},
    this.lastTrainedDay = const {},
    this.currentDay = 1,
  });

  final Set<String> usedExerciseIds;
  final Map<String, int> weeklySets;
  final Map<String, int> lastTrainedDay;
  final int currentDay;
}

/// A single generation request for one training day.
class GenRequest {
  const GenRequest({
    required this.prefs,
    required this.muscles,
    this.context = const GenContext(),
    this.avoidIds = const {},
  });

  final WorkoutPrefs prefs;
  final List<String> muscles;
  final GenContext context;

  /// Exercise ids to steer away from (e.g. a current draft) so regenerating
  /// produces a visibly different workout.
  final Set<String> avoidIds;
}

/// Weekday numbers used across the planner (DateTime weekday numbering:
/// Monday = 1 … Sunday = 7).
const List<int> kWeekdays = [1, 2, 3, 4, 5, 6, 7];

/// Grouped muscle order used to balance exercise count between muscles.
const List<String> kGenMuscleOrder = [
  'chest',
  'back',
  'quads',
  'shoulders',
  'glutes',
  'hamstrings',
  'biceps',
  'triceps',
  'calves',
  'abdomen',
  'obliques',
  'forearm',
  'trapezius',
];

/// Signature exercise names per muscle, used to anchor each day with classic
/// movements before filling out variety.
const Map<String, List<String>> kGenSignatures = {
  'chest': [
    'bench press',
    'incline bench',
    'machine chest press',
    'dumbbell bench',
    'chest dip',
    'push-up',
    'push up',
    'pec deck',
    'cable fly',
    'dumbbell fly',
  ],
  'back': [
    'deadlift',
    'pull-up',
    'pull up',
    'lat pulldown',
    'seated cable row',
    'bent over row',
    't-bar row',
    'chest-supported row',
    'single-arm row',
    'pullover',
  ],
  'shoulders': [
    'overhead press',
    'arnold press',
    'lateral raise',
    'rear delt',
    'face pull',
    'front raise',
  ],
  'biceps': ['curl', 'preacher', 'chin-up', 'chin up', 'spider'],
  'triceps': [
    'pushdown',
    'triceps extension',
    'skull crusher',
    'close-grip bench',
    'dip',
    'kickback',
  ],
  'forearm': ['wrist curl', 'reverse curl', 'farmer', 'carry', 'pinch', 'wrist'],
  'quads': ['squat', 'leg press', 'leg extension', 'lunge', 'split squat', 'hack squat', 'step-up', 'step up'],
  'hamstrings': ['romanian', 'deadlift', 'good morning', 'leg curl', 'nordic'],
  'glutes': [
    'hip thrust',
    'glute bridge',
    'kickback',
    'bulgarian',
    'sumo',
    'deadlift',
    'lunge',
    'pull through',
  ],
  'calves': ['calf raise', 'calf press'],
  'abdomen': [
    'crunch',
    'plank',
    'leg raise',
    'ab wheel',
    'hollow',
    'sit-up',
    'sit up',
    'cable crunch',
    'toe tap',
  ],
  'obliques': ['russian twist', 'wood chop', 'side plank', 'side bend', 'windmill', 'twist'],
  'trapezius': ['shrug', 'upright row', 'face pull', 'trap'],
};

/// The quick week presets: weekday (1-7) -> muscle ids for that day.
Map<int, List<String>> kGenPresetFor(GenStyle style) => switch (style) {
      GenStyle.ppl => {
          1: ['chest', 'shoulders', 'triceps'],
          2: ['back', 'trapezius', 'biceps', 'forearm'],
          3: ['quads', 'hamstrings', 'glutes', 'calves'],
          4: ['chest', 'shoulders', 'triceps'],
          5: ['back', 'trapezius', 'biceps', 'forearm'],
          6: ['quads', 'hamstrings', 'glutes', 'calves'],
          7: const [],
        },
      GenStyle.upperLower => {
          1: ['chest', 'back', 'shoulders', 'biceps', 'triceps'],
          2: ['quads', 'hamstrings', 'glutes', 'calves'],
          3: const [],
          4: ['chest', 'back', 'shoulders', 'biceps', 'triceps'],
          5: ['quads', 'hamstrings', 'glutes', 'calves'],
          6: const [],
          7: const [],
        },
      GenStyle.fullBody => {
          1: ['chest', 'back', 'shoulders', 'quads', 'hamstrings', 'glutes', 'biceps', 'triceps'],
          2: const [],
          3: ['chest', 'back', 'shoulders', 'quads', 'hamstrings', 'glutes', 'biceps', 'triceps'],
          4: const [],
          5: ['chest', 'back', 'shoulders', 'quads', 'hamstrings', 'glutes', 'biceps', 'triceps'],
          6: const [],
          7: const [],
        },
      GenStyle.bro => {
          1: ['chest', 'abdomen'],
          2: ['back', 'trapezius'],
          3: ['shoulders', 'abdomen'],
          4: ['biceps', 'triceps', 'forearm'],
          5: ['quads', 'hamstrings', 'glutes', 'calves'],
          6: const [],
          7: const [],
        },
      GenStyle.arnold => {
          1: ['chest', 'back'],
          2: ['shoulders', 'biceps', 'triceps'],
          3: ['quads', 'hamstrings', 'glutes', 'calves', 'abdomen'],
          4: ['chest', 'back'],
          5: ['shoulders', 'biceps', 'triceps'],
          6: ['quads', 'hamstrings', 'glutes', 'calves', 'abdomen'],
          7: const [],
        },
      GenStyle.custom => {},
    };