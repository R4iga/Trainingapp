import '../models/workout_plan.dart';

/// A built-in program definition stored as structured local data.
///
/// Exercises are referenced by name and resolved against the exercise catalog
/// through the existing fuzzy matcher, so the library is robust to catalog
/// naming differences. Programs do not require generation — they are curated,
/// machine-first structured data that ships with the app.
class ProgramDef {
  const ProgramDef({
    required this.id,
    required this.name,
    required this.category,
    required this.goal,
    required this.difficulty,
    required this.daysPerWeek,
    required this.description,
    required this.days,
  });

  final String id;
  final String name;
  final String category; // beginner | hypertrophy | strength | general | home | lemon
  final PlanGoal goal;
  final String difficulty;
  final int daysPerWeek;
  final String description;

  /// Each entry: (day name, list of (exercise name, sets, reps, restSeconds)).
  final List<ProgramDay> days;
}

class ProgramDay {
  const ProgramDay(this.name, this.exercises);
  final String name;
  final List<ProgramExercise> exercises;
}

class ProgramExercise {
  const ProgramExercise(this.name, this.sets, this.reps, this.repsMax, this.restSeconds);
  final String name;
  final int sets;
  final int reps;
  final int? repsMax;
  final int? restSeconds;

  String get repRange => repsMax == null ? '$reps' : '$reps-$repsMax';
}

const int _r120 = 120;
const int _r90 = 90;
const int _r75 = 75;
const int _r60 = 60;

/// The built-in program library, grouped by category. Lemon Gym programs are
/// machine-and-cable-first to match common commercial gym equipment.
const List<ProgramDef> kProgramLibrary = [
  // ---------------------------------------------------------------- BEGINNER
  ProgramDef(
    id: 'lib-fullbody-2',
    name: 'Full Body 2x',
    category: 'beginner',
    goal: PlanGoal.beginner,
    difficulty: 'Beginner',
    daysPerWeek: 2,
    description: 'A simple full-body program twice a week. Perfect to start.',
    days: [
      ProgramDay('Full Body A', [
        ProgramExercise('Machine Chest Press', 3, 10, 12, _r90),
        ProgramExercise('Lat Pulldown', 3, 10, 12, _r90),
        ProgramExercise('Seated Cable Row', 3, 10, 12, _r90),
        ProgramExercise('Leg Press', 3, 10, 12, _r90),
        ProgramExercise('Leg Extension', 3, 12, 15, _r75),
        ProgramExercise('Machine Shoulder Press', 3, 10, 12, _r90),
      ]),
      ProgramDay('Full Body B', [
        ProgramExercise('Machine Chest Press', 3, 10, 12, _r90),
        ProgramExercise('Lat Pulldown', 3, 10, 12, _r90),
        ProgramExercise('Leg Press', 3, 10, 12, _r90),
        ProgramExercise('Seated Leg Curl', 3, 10, 12, _r90),
        ProgramExercise('Cable Curl', 3, 10, 15, _r60),
        ProgramExercise('Triceps Pushdown', 3, 10, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-fullbody-3',
    name: 'Full Body 3x',
    category: 'beginner',
    goal: PlanGoal.beginner,
    difficulty: 'Beginner',
    daysPerWeek: 3,
    description: 'A three-day full-body program for steady beginner progress.',
    days: [
      ProgramDay('Full Body A', [
        ProgramExercise('Machine Chest Press', 3, 10, 12, _r90),
        ProgramExercise('Seated Cable Row', 3, 10, 12, _r90),
        ProgramExercise('Leg Press', 3, 10, 12, _r90),
        ProgramExercise('Machine Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Cable Curl', 3, 10, 15, _r60),
      ]),
      ProgramDay('Full Body B', [
        ProgramExercise('Lat Pulldown', 3, 10, 12, _r90),
        ProgramExercise('Machine Chest Press', 3, 10, 12, _r90),
        ProgramExercise('Leg Extension', 3, 12, 15, _r75),
        ProgramExercise('Seated Leg Curl', 3, 10, 12, _r90),
        ProgramExercise('Triceps Pushdown', 3, 10, 15, _r60),
      ]),
      ProgramDay('Full Body C', [
        ProgramExercise('Machine Shoulder Press', 3, 10, 12, _r90),
        ProgramExercise('Lat Pulldown', 3, 10, 12, _r90),
        ProgramExercise('Seated Cable Row', 3, 10, 12, _r90),
        ProgramExercise('Leg Press', 3, 10, 12, _r90),
        ProgramExercise('Machine Chest Press', 3, 10, 12, _r90),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-beginner-3',
    name: 'Beginner 3-Day',
    category: 'beginner',
    goal: PlanGoal.beginner,
    difficulty: 'Beginner',
    daysPerWeek: 3,
    description: 'A balanced beginner split across three gym days.',
    days: [
      ProgramDay('Push', [
        ProgramExercise('Machine Chest Press', 3, 10, 12, _r90),
        ProgramExercise('Incline Chest Press', 3, 10, 12, _r90),
        ProgramExercise('Machine Shoulder Press', 3, 10, 12, _r90),
        ProgramExercise('Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Triceps Pushdown', 3, 10, 15, _r60),
      ]),
      ProgramDay('Pull', [
        ProgramExercise('Lat Pulldown', 3, 10, 12, _r90),
        ProgramExercise('Seated Cable Row', 3, 10, 12, _r90),
        ProgramExercise('Reverse Pec Deck', 3, 12, 15, _r75),
        ProgramExercise('Cable Curl', 3, 10, 15, _r60),
      ]),
      ProgramDay('Legs', [
        ProgramExercise('Leg Press', 3, 10, 12, _r90),
        ProgramExercise('Leg Extension', 3, 12, 15, _r75),
        ProgramExercise('Seated Leg Curl', 3, 10, 12, _r90),
        ProgramExercise('Calf Raise', 3, 12, 15, _r60),
        ProgramExercise('Machine Chest Press', 2, 10, 12, _r90),
      ]),
    ],
  ),

  // ------------------------------------------------------------ HYPERTROPHY
  ProgramDef(
    id: 'lib-ppl',
    name: 'Push Pull Legs',
    category: 'hypertrophy',
    goal: PlanGoal.muscleGain,
    difficulty: 'Intermediate',
    daysPerWeek: 6,
    description: 'The classic PPL split, run twice a week.',
    days: [
      ProgramDay('Push', [
        ProgramExercise('Machine Chest Press', 4, 8, 12, _r120),
        ProgramExercise('Incline Chest Press', 3, 8, 12, _r90),
        ProgramExercise('Pec Deck', 3, 10, 15, _r90),
        ProgramExercise('Machine Shoulder Press', 3, 8, 12, _r120),
        ProgramExercise('Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Triceps Pushdown', 3, 10, 15, _r60),
      ]),
      ProgramDay('Pull', [
        ProgramExercise('Lat Pulldown', 4, 8, 12, _r120),
        ProgramExercise('Seated Cable Row', 3, 8, 12, _r90),
        ProgramExercise('Chest-Supported Row', 3, 8, 12, _r90),
        ProgramExercise('Reverse Pec Deck', 3, 12, 15, _r75),
        ProgramExercise('Cable Curl', 3, 10, 15, _r60),
      ]),
      ProgramDay('Legs', [
        ProgramExercise('Leg Press', 4, 8, 12, _r120),
        ProgramExercise('Leg Extension', 3, 10, 15, _r75),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
        ProgramExercise('Calf Raise', 4, 10, 15, _r60),
      ]),
      ProgramDay('Push 2', [
        ProgramExercise('Machine Chest Press', 4, 8, 12, _r120),
        ProgramExercise('Machine Shoulder Press', 3, 8, 12, _r120),
        ProgramExercise('Pec Deck', 3, 10, 15, _r90),
        ProgramExercise('Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Triceps Pushdown', 3, 10, 15, _r60),
      ]),
      ProgramDay('Pull 2', [
        ProgramExercise('Lat Pulldown', 4, 8, 12, _r120),
        ProgramExercise('Seated Cable Row', 3, 8, 12, _r90),
        ProgramExercise('Reverse Pec Deck', 3, 12, 15, _r75),
        ProgramExercise('Cable Curl', 3, 10, 15, _r60),
      ]),
      ProgramDay('Legs 2', [
        ProgramExercise('Leg Press', 4, 8, 12, _r120),
        ProgramExercise('Leg Extension', 3, 10, 15, _r75),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
        ProgramExercise('Calf Raise', 4, 10, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-upper-lower-4',
    name: 'Upper Lower 4D',
    category: 'hypertrophy',
    goal: PlanGoal.muscleGain,
    difficulty: 'Intermediate',
    daysPerWeek: 4,
    description: 'A four-day upper/lower split for straight-forward gains.',
    days: [
      ProgramDay('Upper A', [
        ProgramExercise('Machine Chest Press', 4, 8, 12, _r120),
        ProgramExercise('Lat Pulldown', 4, 8, 12, _r120),
        ProgramExercise('Incline Chest Press', 3, 8, 12, _r90),
        ProgramExercise('Seated Cable Row', 3, 8, 12, _r90),
        ProgramExercise('Machine Shoulder Press', 3, 8, 12, _r120),
        ProgramExercise('Cable Curl', 3, 10, 15, _r60),
      ]),
      ProgramDay('Lower A', [
        ProgramExercise('Leg Press', 4, 8, 12, _r120),
        ProgramExercise('Leg Extension', 3, 10, 15, _r75),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
        ProgramExercise('Calf Raise', 4, 10, 15, _r60),
      ]),
      ProgramDay('Upper B', [
        ProgramExercise('Machine Chest Press', 4, 8, 12, _r120),
        ProgramExercise('Lat Pulldown', 4, 8, 12, _r120),
        ProgramExercise('Pec Deck', 3, 10, 15, _r90),
        ProgramExercise('Seated Cable Row', 3, 8, 12, _r90),
        ProgramExercise('Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Triceps Pushdown', 3, 10, 15, _r60),
      ]),
      ProgramDay('Lower B', [
        ProgramExercise('Leg Press', 4, 8, 12, _r120),
        ProgramExercise('Hack Squat', 3, 8, 12, _r120),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
        ProgramExercise('Calf Raise', 4, 10, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-bro-split',
    name: 'Bro Split',
    category: 'hypertrophy',
    goal: PlanGoal.muscleGain,
    difficulty: 'Intermediate',
    daysPerWeek: 5,
    description: 'The classic five-day body-part split for dedicated lifters.',
    days: [
      ProgramDay('Chest', [
        ProgramExercise('Machine Chest Press', 4, 8, 12, _r120),
        ProgramExercise('Incline Chest Press', 4, 8, 12, _r120),
        ProgramExercise('Pec Deck', 3, 10, 15, _r90),
      ]),
      ProgramDay('Back', [
        ProgramExercise('Lat Pulldown', 4, 8, 12, _r120),
        ProgramExercise('Seated Cable Row', 4, 8, 12, _r120),
        ProgramExercise('Reverse Pec Deck', 3, 12, 15, _r75),
      ]),
      ProgramDay('Shoulders', [
        ProgramExercise('Machine Shoulder Press', 4, 8, 12, _r120),
        ProgramExercise('Lateral Raise', 4, 12, 15, _r75),
        ProgramExercise('Reverse Pec Deck', 3, 12, 15, _r75),
      ]),
      ProgramDay('Arms', [
        ProgramExercise('Cable Curl', 4, 10, 15, _r60),
        ProgramExercise('Triceps Pushdown', 4, 10, 15, _r60),
        ProgramExercise('Preacher Curl', 3, 10, 12, _r60),
      ]),
      ProgramDay('Legs', [
        ProgramExercise('Leg Press', 4, 8, 12, _r120),
        ProgramExercise('Leg Extension', 3, 10, 15, _r75),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
        ProgramExercise('Calf Raise', 4, 10, 15, _r60),
      ]),
    ],
  ),

  // -------------------------------------------------------------- STRENGTH
  ProgramDef(
    id: 'lib-strength-3',
    name: '3-Day Strength',
    category: 'strength',
    goal: PlanGoal.strength,
    difficulty: 'Intermediate',
    daysPerWeek: 3,
    description: 'A compact strength-focused program, three days a week.',
    days: [
      ProgramDay('Strength A', [
        ProgramExercise('Machine Chest Press', 4, 6, 8, _r120),
        ProgramExercise('Lat Pulldown', 4, 6, 8, _r120),
        ProgramExercise('Leg Press', 4, 6, 8, _r120),
        ProgramExercise('Machine Shoulder Press', 3, 8, 10, _r120),
      ]),
      ProgramDay('Strength B', [
        ProgramExercise('Seated Cable Row', 4, 6, 8, _r120),
        ProgramExercise('Machine Chest Press', 4, 6, 8, _r120),
        ProgramExercise('Leg Extension', 3, 8, 10, _r90),
        ProgramExercise('Seated Leg Curl', 3, 8, 10, _r90),
      ]),
      ProgramDay('Strength C', [
        ProgramExercise('Machine Chest Press', 4, 6, 8, _r120),
        ProgramExercise('Lat Pulldown', 4, 6, 8, _r120),
        ProgramExercise('Leg Press', 4, 6, 8, _r120),
        ProgramExercise('Cable Curl', 3, 8, 10, _r90),
      ]),
    ],
  ),

  // ---------------------------------------------------------- LEMON GYM
  ProgramDef(
    id: 'lib-lemon-beginner',
    name: 'Lemon Gym Beginner',
    category: 'lemon',
    goal: PlanGoal.beginner,
    difficulty: 'Beginner',
    daysPerWeek: 3,
    description: 'A simple three-day machine-first beginner program from Lemon Gym.',
    days: [
      ProgramDay('Machine Full Body A', [
        ProgramExercise('Machine Chest Press', 3, 10, 12, _r90),
        ProgramExercise('Lat Pulldown', 3, 10, 12, _r90),
        ProgramExercise('Seated Cable Row', 3, 10, 12, _r90),
        ProgramExercise('Leg Press', 3, 10, 12, _r90),
      ]),
      ProgramDay('Machine Full Body B', [
        ProgramExercise('Machine Shoulder Press', 3, 10, 12, _r90),
        ProgramExercise('Seated Cable Row', 3, 10, 12, _r90),
        ProgramExercise('Leg Press', 3, 10, 12, _r90),
        ProgramExercise('Machine Chest Press', 3, 10, 12, _r90),
      ]),
      ProgramDay('Machine Full Body C', [
        ProgramExercise('Machine Chest Press', 3, 10, 12, _r90),
        ProgramExercise('Lat Pulldown', 3, 10, 12, _r90),
        ProgramExercise('Leg Extension', 3, 12, 15, _r75),
        ProgramExercise('Seated Leg Curl', 3, 10, 12, _r90),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-lemon-upper-lower',
    name: 'Lemon Gym Upper Lower',
    category: 'lemon',
    goal: PlanGoal.muscleGain,
    difficulty: 'Intermediate',
    daysPerWeek: 4,
    description: 'Machine-and-cable upper/lower split, four days a week.',
    days: [
      ProgramDay('Lemon Upper A', [
        ProgramExercise('Machine Chest Press', 4, 8, 12, _r120),
        ProgramExercise('Lat Pulldown', 4, 8, 12, _r120),
        ProgramExercise('Machine Shoulder Press', 3, 8, 12, _r120),
        ProgramExercise('Triceps Pushdown', 3, 10, 15, _r60),
      ]),
      ProgramDay('Lemon Lower A', [
        ProgramExercise('Leg Press', 4, 8, 12, _r120),
        ProgramExercise('Leg Extension', 3, 10, 15, _r75),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
        ProgramExercise('Calf Raise', 4, 10, 15, _r60),
      ]),
      ProgramDay('Lemon Upper B', [
        ProgramExercise('Lat Pulldown', 4, 8, 12, _r120),
        ProgramExercise('Seated Cable Row', 4, 8, 12, _r120),
        ProgramExercise('Pec Deck', 3, 10, 15, _r90),
        ProgramExercise('Cable Curl', 3, 10, 15, _r60),
      ]),
      ProgramDay('Lemon Lower B', [
        ProgramExercise('Leg Press', 4, 8, 12, _r120),
        ProgramExercise('Hack Squat', 3, 8, 12, _r120),
        ProgramExercise('Leg Extension', 3, 10, 15, _r75),
        ProgramExercise('Calf Raise', 4, 10, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-lemon-machine-hypertrophy',
    name: 'Lemon Gym Machine Hypertrophy',
    category: 'lemon',
    goal: PlanGoal.muscleGain,
    difficulty: 'Intermediate',
    daysPerWeek: 4,
    description: 'The flagship Lemon Gym machine hypertrophy program.',
    days: [
      ProgramDay('Chest + Shoulders + Triceps', [
        ProgramExercise('Machine Chest Press', 3, 8, 12, _r120),
        ProgramExercise('Incline Chest Press', 3, 8, 12, _r120),
        ProgramExercise('Pec Deck', 3, 10, 15, _r90),
        ProgramExercise('Machine Shoulder Press', 3, 8, 12, _r120),
        ProgramExercise('Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Triceps Pushdown', 3, 10, 15, _r75),
      ]),
      ProgramDay('Back + Biceps', [
        ProgramExercise('Lat Pulldown', 3, 8, 12, _r120),
        ProgramExercise('Seated Cable Row', 3, 8, 12, _r120),
        ProgramExercise('Chest-Supported Row', 3, 8, 12, _r120),
        ProgramExercise('Reverse Pec Deck', 3, 12, 15, _r75),
        ProgramExercise('Cable Curl', 3, 10, 15, _r75),
        ProgramExercise('Preacher Curl', 3, 10, 15, _r75),
      ]),
      ProgramDay('Legs', [
        ProgramExercise('Leg Press', 4, 8, 12, _r120),
        ProgramExercise('Hack Squat', 3, 8, 12, _r120),
        ProgramExercise('Leg Extension', 3, 10, 15, _r75),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
        ProgramExercise('Calf Raise', 4, 10, 15, _r60),
      ]),
      ProgramDay('Upper (Machine)', [
        ProgramExercise('Machine Chest Press', 3, 8, 12, _r120),
        ProgramExercise('Lat Pulldown', 3, 8, 12, _r120),
        ProgramExercise('Seated Cable Row', 3, 8, 12, _r120),
        ProgramExercise('Machine Shoulder Press', 3, 8, 12, _r120),
        ProgramExercise('Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Triceps Pushdown', 2, 10, 15, _r60),
        ProgramExercise('Cable Curl', 2, 10, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-lemon-machine-only',
    name: 'Lemon Gym Machine Only',
    category: 'lemon',
    goal: PlanGoal.beginner,
    difficulty: 'Beginner',
    daysPerWeek: 3,
    description: 'A beginner machine-only program for pure machine gyms.',
    days: [
      ProgramDay('Machine Upper', [
        ProgramExercise('Machine Chest Press', 3, 10, 12, _r90),
        ProgramExercise('Lat Pulldown', 3, 10, 12, _r90),
        ProgramExercise('Machine Shoulder Press', 3, 10, 12, _r90),
      ]),
      ProgramDay('Machine Lower', [
        ProgramExercise('Leg Press', 3, 10, 12, _r90),
        ProgramExercise('Leg Extension', 3, 12, 15, _r75),
        ProgramExercise('Seated Leg Curl', 3, 10, 12, _r90),
      ]),
      ProgramDay('Machine Push Pull', [
        ProgramExercise('Machine Chest Press', 3, 10, 12, _r90),
        ProgramExercise('Seated Cable Row', 3, 10, 12, _r90),
        ProgramExercise('Leg Press', 3, 10, 12, _r90),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-lemon-chest-focus',
    name: 'Lemon Gym Chest Focus',
    category: 'lemon',
    goal: PlanGoal.muscleGain,
    difficulty: 'Intermediate',
    daysPerWeek: 4,
    description: 'A chest-priority machine program for bringing up the chest.',
    days: [
      ProgramDay('Chest Heavy', [
        ProgramExercise('Machine Chest Press', 4, 8, 12, _r120),
        ProgramExercise('Incline Chest Press', 4, 8, 12, _r120),
        ProgramExercise('Pec Deck', 3, 10, 15, _r90),
        ProgramExercise('Triceps Pushdown', 3, 10, 15, _r60),
      ]),
      ProgramDay('Back + Shoulders', [
        ProgramExercise('Lat Pulldown', 3, 8, 12, _r90),
        ProgramExercise('Seated Cable Row', 3, 8, 12, _r90),
        ProgramExercise('Machine Shoulder Press', 3, 8, 12, _r120),
        ProgramExercise('Lateral Raise', 3, 12, 15, _r75),
      ]),
      ProgramDay('Chest Pump', [
        ProgramExercise('Machine Chest Press', 4, 10, 15, _r90),
        ProgramExercise('Pec Deck', 4, 12, 15, _r75),
        ProgramExercise('Cable Curl', 3, 10, 15, _r60),
      ]),
      ProgramDay('Legs', [
        ProgramExercise('Leg Press', 4, 8, 12, _r120),
        ProgramExercise('Leg Extension', 3, 10, 15, _r75),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-lemon-arms-focus',
    name: 'Lemon Gym Arms Focus',
    category: 'lemon',
    goal: PlanGoal.muscleGain,
    difficulty: 'Intermediate',
    daysPerWeek: 4,
    description: 'An arms-priority program using cables and machines.',
    days: [
      ProgramDay('Biceps + Triceps Heavy', [
        ProgramExercise('Cable Curl', 4, 10, 15, _r60),
        ProgramExercise('Triceps Pushdown', 4, 10, 15, _r60),
        ProgramExercise('Preacher Curl', 3, 10, 12, _r60),
        ProgramExercise('Triceps Pushdown', 3, 10, 12, _r60),
      ]),
      ProgramDay('Chest + Back', [
        ProgramExercise('Machine Chest Press', 3, 8, 12, _r90),
        ProgramExercise('Lat Pulldown', 3, 8, 12, _r90),
        ProgramExercise('Seated Cable Row', 3, 8, 12, _r90),
      ]),
      ProgramDay('Shoulders + Arms Pump', [
        ProgramExercise('Machine Shoulder Press', 3, 8, 12, _r90),
        ProgramExercise('Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Cable Curl', 3, 10, 15, _r60),
        ProgramExercise('Triceps Pushdown', 3, 10, 15, _r60),
      ]),
      ProgramDay('Legs', [
        ProgramExercise('Leg Press', 3, 8, 12, _r90),
        ProgramExercise('Leg Extension', 3, 10, 15, _r75),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
      ]),
    ],
  ),
];

/// Category keys that group library programs in the UI.
const List<String> kProgramCategories = [
  'lemon',
  'beginner',
  'hypertrophy',
  'strength',
  'general',
  'home',
];

List<ProgramDef> programsInCategory(String category) =>
    kProgramLibrary.where((p) => p.category == category).toList();
