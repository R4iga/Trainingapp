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
const int _r45 = 45;
const int _r180 = 180;

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
        ProgramExercise('Dumbbell Incline Bench Press', 3, 10, 12, _r90),
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
        ProgramExercise('Dumbbell Incline Bench Press', 3, 8, 12, _r90),
        ProgramExercise('Pec Deck', 3, 10, 15, _r90),
        ProgramExercise('Machine Shoulder Press', 3, 8, 12, _r120),
        ProgramExercise('Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Triceps Pushdown', 3, 10, 15, _r60),
      ]),
      ProgramDay('Pull', [
        ProgramExercise('Lat Pulldown', 4, 8, 12, _r120),
        ProgramExercise('Seated Cable Row', 3, 8, 12, _r90),
        ProgramExercise('Lever Seated Row', 3, 8, 12, _r90),
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
        ProgramExercise('Dumbbell Incline Bench Press', 3, 8, 12, _r90),
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
        ProgramExercise('Dumbbell Incline Bench Press', 4, 8, 12, _r120),
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
        ProgramExercise('Dumbbell Incline Bench Press', 3, 8, 12, _r120),
        ProgramExercise('Pec Deck', 3, 10, 15, _r90),
        ProgramExercise('Machine Shoulder Press', 3, 8, 12, _r120),
        ProgramExercise('Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Triceps Pushdown', 3, 10, 15, _r75),
      ]),
      ProgramDay('Back + Biceps', [
        ProgramExercise('Lat Pulldown', 3, 8, 12, _r120),
        ProgramExercise('Seated Cable Row', 3, 8, 12, _r120),
        ProgramExercise('Lever Seated Row', 3, 8, 12, _r120),
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
        ProgramExercise('Dumbbell Incline Bench Press', 4, 8, 12, _r120),
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

  // ------------------------------------------------------------ CLASICOS
  ProgramDef(
    id: 'lib-stronglifts-5x5',
    name: 'StrongLifts 5x5',
    category: 'beginner',
    goal: PlanGoal.strength,
    difficulty: 'Beginner',
    daysPerWeek: 3,
    description: 'The internet\'s favourite barbell beginner program. Five sets of five, three times a week.',
    days: [
      ProgramDay('Workout A', [
        ProgramExercise('Barbell Full Squat', 5, 5, 5, _r180),
        ProgramExercise('Barbell Bench Press', 5, 5, 5, _r180),
        ProgramExercise('Barbell Pendlay Row', 5, 5, 5, _r180),
      ]),
      ProgramDay('Workout B', [
        ProgramExercise('Barbell Full Squat', 5, 5, 5, _r180),
        ProgramExercise('Barbell Standing Wide Military Press', 5, 5, 5, _r180),
        ProgramExercise('Barbell Deadlift', 5, 5, 5, _r180),
      ]),
      ProgramDay('Workout C', [
        ProgramExercise('Barbell Full Squat', 5, 5, 5, _r180),
        ProgramExercise('Barbell Bench Press', 5, 5, 5, _r180),
        ProgramExercise('Barbell Pendlay Row', 5, 5, 5, _r180),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-starting-strength',
    name: 'Starting Strength',
    category: 'beginner',
    goal: PlanGoal.beginner,
    difficulty: 'Beginner',
    daysPerWeek: 3,
    description: 'The classic Mark Rippetoe program. Three heavy lifts, three days a week.',
    days: [
      ProgramDay('Workout A', [
        ProgramExercise('Barbell Full Squat', 3, 5, 5, _r180),
        ProgramExercise('Barbell Bench Press', 3, 5, 5, _r180),
        ProgramExercise('Barbell Deadlift', 1, 5, 5, _r180),
      ]),
      ProgramDay('Workout B', [
        ProgramExercise('Barbell Full Squat', 3, 5, 5, _r180),
        ProgramExercise('Barbell Standing Wide Military Press', 3, 5, 5, _r180),
        ProgramExercise('Pull-up', 3, 6, 8, _r90),
      ]),
      ProgramDay('Workout C', [
        ProgramExercise('Barbell Full Squat', 3, 5, 5, _r180),
        ProgramExercise('Barbell Bench Press', 3, 5, 5, _r180),
        ProgramExercise('Barbell Deadlift', 1, 5, 5, _r180),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-icf-5x5',
    name: 'Ice Cream Fitness 5x5',
    category: 'beginner',
    goal: PlanGoal.muscleGain,
    difficulty: 'Intermediate',
    daysPerWeek: 3,
    description: 'StrongLifts 5x5 with added iso work for a full-body pump on a cut or bulk.',
    days: [
      ProgramDay('Workout A', [
        ProgramExercise('Barbell Full Squat', 5, 5, 5, _r180),
        ProgramExercise('Barbell Bench Press', 5, 5, 5, _r180),
        ProgramExercise('Barbell Pendlay Row', 5, 5, 5, _r180),
        ProgramExercise('Barbell Standing Wide Military Press', 3, 8, 8, _r90),
        ProgramExercise('Barbell Reverse Wrist Curl', 3, 10, 15, _r60),
      ]),
      ProgramDay('Workout B', [
        ProgramExercise('Barbell Full Squat', 5, 5, 5, _r180),
        ProgramExercise('Barbell Deadlift', 5, 5, 5, _r180),
        ProgramExercise('Barbell Standing Wide Military Press', 5, 5, 5, _r180),
        ProgramExercise('Pull-up', 3, 8, 8, _r90),
        ProgramExercise('Barbell Shrug', 3, 8, 8, _r90),
      ]),
      ProgramDay('Workout C', [
        ProgramExercise('Barbell Full Squat', 5, 5, 5, _r180),
        ProgramExercise('Barbell Bench Press', 5, 5, 5, _r180),
        ProgramExercise('Barbell Pendlay Row', 5, 5, 5, _r180),
        ProgramExercise('Barbell Standing Wide Military Press', 3, 8, 8, _r90),
        ProgramExercise('Barbell Reverse Wrist Curl', 3, 10, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-reddit-ppl',
    name: 'Reddit PPL',
    category: 'hypertrophy',
    goal: PlanGoal.muscleGain,
    difficulty: 'Advanced',
    daysPerWeek: 6,
    description: 'The famous six-day push/pull/legs from /r/fitness. High volume, high results.',
    days: [
      ProgramDay('Push A', [
        ProgramExercise('Barbell Bench Press', 4, 6, 8, _r120),
        ProgramExercise('Dumbbell Incline Bench Press', 3, 8, 12, _r90),
        ProgramExercise('Chest Dip', 3, 8, 12, _r90),
        ProgramExercise('Cable Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Barbell Lying Triceps Extension', 3, 10, 15, _r60),
      ]),
      ProgramDay('Pull A', [
        ProgramExercise('Pull-up', 4, 6, 8, _r120),
        ProgramExercise('Barbell Pendlay Row', 4, 6, 10, _r90),
        ProgramExercise('Face Pull', 3, 12, 15, _r75),
        ProgramExercise('Barbell Curl', 3, 10, 15, _r60),
        ProgramExercise('Dumbbell Hammer Curl', 3, 10, 12, _r60),
      ]),
      ProgramDay('Legs A', [
        ProgramExercise('Barbell Full Squat', 4, 6, 8, _r120),
        ProgramExercise('Barbell Romanian Deadlift', 3, 8, 12, _r90),
        ProgramExercise('Dumbbell Lunge', 3, 10, 12, _r75),
        ProgramExercise('Barbell Standing Calf Raise', 4, 10, 15, _r60),
      ]),
      ProgramDay('Push B', [
        ProgramExercise('Barbell Standing Wide Military Press', 4, 6, 8, _r120),
        ProgramExercise('Barbell Bench Press', 3, 6, 8, _r90),
        ProgramExercise('Dumbbell Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Triceps Dip', 3, 8, 12, _r75),
        ProgramExercise('Cable Overhead Triceps Extension (Rope Attachment)', 3, 10, 12, _r60),
      ]),
      ProgramDay('Pull B', [
        ProgramExercise('Chin-up', 4, 6, 10, _r120),
        ProgramExercise('Barbell Incline Row', 4, 8, 10, _r90),
        ProgramExercise('Face Pull', 3, 12, 15, _r75),
        ProgramExercise('Dumbbell Biceps Curl', 3, 10, 15, _r60),
        ProgramExercise('Dumbbell Hammer Curl', 3, 10, 12, _r60),
      ]),
      ProgramDay('Legs B', [
        ProgramExercise('Barbell Sumo Deadlift', 4, 6, 8, _r120),
        ProgramExercise('Barbell Front Squat', 3, 6, 8, _r120),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
        ProgramExercise('Cable Standing Crunch', 3, 12, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-arnold-split',
    name: 'Arnold Split',
    category: 'hypertrophy',
    goal: PlanGoal.muscleGain,
    difficulty: 'Advanced',
    daysPerWeek: 6,
    description: 'The body-part split made famous by the Austrian Oak. High intensity, six days a week.',
    days: [
      ProgramDay('Chest & Back A', [
        ProgramExercise('Barbell Bench Press', 4, 8, 10, _r120),
        ProgramExercise('Barbell Pendlay Row', 4, 8, 10, _r120),
        ProgramExercise('Dumbbell Incline Bench Press', 3, 8, 12, _r90),
        ProgramExercise('Pull-up', 3, 8, 12, _r90),
      ]),
      ProgramDay('Shoulders & Arms A', [
        ProgramExercise('Barbell Standing Wide Military Press', 4, 8, 10, _r120),
        ProgramExercise('Dumbbell Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Barbell Curl', 3, 10, 15, _r60),
        ProgramExercise('Barbell Lying Triceps Extension', 3, 10, 15, _r60),
      ]),
      ProgramDay('Legs A', [
        ProgramExercise('Barbell Full Squat', 4, 8, 10, _r120),
        ProgramExercise('Barbell Romanian Deadlift', 3, 8, 12, _r90),
        ProgramExercise('Dumbbell Lunge', 3, 10, 12, _r75),
        ProgramExercise('Barbell Standing Calf Raise', 3, 12, 15, _r60),
      ]),
      ProgramDay('Chest & Back B', [
        ProgramExercise('Barbell Bench Press', 3, 8, 12, _r90),
        ProgramExercise('Barbell Pendlay Row', 3, 8, 12, _r90),
        ProgramExercise('Chest Dip', 3, 10, 15, _r75),
        ProgramExercise('Chin-up', 3, 8, 12, _r90),
      ]),
      ProgramDay('Shoulders & Arms B', [
        ProgramExercise('Barbell Standing Wide Military Press', 3, 8, 12, _r90),
        ProgramExercise('Cable Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Dumbbell Hammer Curl', 3, 10, 15, _r60),
        ProgramExercise('Cable Overhead Triceps Extension (Rope Attachment)', 3, 10, 12, _r60),
      ]),
      ProgramDay('Legs B', [
        ProgramExercise('Barbell Front Squat', 3, 8, 10, _r120),
        ProgramExercise('Barbell Sumo Deadlift', 3, 6, 8, _r120),
        ProgramExercise('Barbell Standing Calf Raise', 3, 12, 15, _r60),
        ProgramExercise('Cable Standing Crunch', 3, 12, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-arnold-golden-six',
    name: 'Arnold\'s Golden Six',
    category: 'hypertrophy',
    goal: PlanGoal.muscleGain,
    difficulty: 'Beginner',
    daysPerWeek: 3,
    description: 'The six-lift full-body classic Arnold used to grow: squat, bench, row, press, curl and calves.',
    days: [
      ProgramDay('Golden Six A', [
        ProgramExercise('Barbell Full Squat', 3, 10, 10, _r90),
        ProgramExercise('Barbell Bench Press', 3, 10, 10, _r90),
        ProgramExercise('Barbell Pendlay Row', 3, 10, 10, _r90),
        ProgramExercise('Barbell Standing Wide Military Press', 3, 10, 10, _r90),
        ProgramExercise('Barbell Curl', 3, 10, 10, _r60),
        ProgramExercise('Barbell Standing Calf Raise', 3, 12, 15, _r60),
      ]),
      ProgramDay('Golden Six B', [
        ProgramExercise('Barbell Full Squat', 3, 10, 10, _r90),
        ProgramExercise('Dumbbell Bench Press', 3, 10, 10, _r90),
        ProgramExercise('Barbell Deadlift', 3, 10, 10, _r90),
        ProgramExercise('Barbell Standing Wide Military Press', 3, 10, 10, _r90),
        ProgramExercise('Dumbbell Hammer Curl', 3, 10, 12, _r60),
        ProgramExercise('Crunch Floor', 3, 15, 20, _r45),
      ]),
      ProgramDay('Golden Six C', [
        ProgramExercise('Barbell Full Squat', 3, 10, 10, _r90),
        ProgramExercise('Barbell Bench Press', 3, 10, 10, _r90),
        ProgramExercise('Barbell Pendlay Row', 3, 10, 10, _r90),
        ProgramExercise('Barbell Standing Wide Military Press', 3, 10, 10, _r90),
        ProgramExercise('Barbell Curl', 3, 10, 10, _r60),
        ProgramExercise('Barbell Standing Calf Raise', 3, 12, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-phul',
    name: 'PHUL',
    category: 'hypertrophy',
    goal: PlanGoal.muscleGain,
    difficulty: 'Intermediate',
    daysPerWeek: 4,
    description: 'Power Hypertrophy Upper Lower. Heavy strength upper/lower twice, then a hypertrophy rematch.',
    days: [
      ProgramDay('Power Upper', [
        ProgramExercise('Barbell Bench Press', 4, 4, 6, _r120),
        ProgramExercise('Barbell Pendlay Row', 4, 4, 6, _r120),
        ProgramExercise('Barbell Standing Wide Military Press', 3, 6, 8, _r120),
        ProgramExercise('Barbell Lying Triceps Extension', 3, 6, 10, _r90),
        ProgramExercise('Barbell Curl', 3, 6, 10, _r90),
      ]),
      ProgramDay('Power Lower', [
        ProgramExercise('Barbell Full Squat', 4, 4, 6, _r120),
        ProgramExercise('Barbell Deadlift', 4, 4, 6, _r120),
        ProgramExercise('Dumbbell Lunge', 3, 8, 10, _r90),
        ProgramExercise('Barbell Standing Calf Raise', 3, 10, 15, _r60),
      ]),
      ProgramDay('Hypertrophy Upper', [
        ProgramExercise('Dumbbell Bench Press', 3, 8, 12, _r90),
        ProgramExercise('Dumbbell Incline Bench Press', 3, 8, 12, _r90),
        ProgramExercise('Face Pull', 3, 12, 15, _r75),
        ProgramExercise('Dumbbell Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Triceps Dip', 3, 10, 15, _r75),
        ProgramExercise('Cable Curl', 3, 10, 15, _r60),
      ]),
      ProgramDay('Hypertrophy Lower', [
        ProgramExercise('Barbell Front Squat', 3, 8, 12, _r90),
        ProgramExercise('Barbell Romanian Deadlift', 3, 8, 12, _r90),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
        ProgramExercise('Dumbbell Goblet Squat', 3, 10, 15, _r90),
        ProgramExercise('Barbell Standing Calf Raise', 4, 10, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-phat',
    name: 'PHAT',
    category: 'hypertrophy',
    goal: PlanGoal.muscleGain,
    difficulty: 'Advanced',
    daysPerWeek: 5,
    description: 'Layne Norton\'s Power Hypertrophy Adaptive Training: two power days plus three hypertrophy days.',
    days: [
      ProgramDay('Power Upper', [
        ProgramExercise('Barbell Bench Press', 4, 4, 6, _r120),
        ProgramExercise('Barbell Pendlay Row', 4, 4, 6, _r120),
        ProgramExercise('Barbell Standing Wide Military Press', 3, 6, 8, _r120),
        ProgramExercise('Barbell Lying Triceps Extension', 3, 6, 10, _r90),
        ProgramExercise('Barbell Curl', 3, 6, 10, _r90),
      ]),
      ProgramDay('Power Lower', [
        ProgramExercise('Barbell Full Squat', 4, 4, 6, _r120),
        ProgramExercise('Barbell Deadlift', 4, 4, 6, _r120),
        ProgramExercise('Dumbbell Lunge', 3, 8, 10, _r90),
        ProgramExercise('Barbell Standing Calf Raise', 3, 10, 15, _r60),
      ]),
      ProgramDay('Back & Shoulders', [
        ProgramExercise('Pull-up', 4, 6, 10, _r90),
        ProgramExercise('Barbell Pendlay Row', 4, 8, 10, _r90),
        ProgramExercise('Face Pull', 3, 12, 15, _r75),
        ProgramExercise('Dumbbell Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Barbell Rear Delt Row', 3, 12, 15, _r75),
      ]),
      ProgramDay('Chest & Arms', [
        ProgramExercise('Barbell Bench Press', 4, 6, 10, _r90),
        ProgramExercise('Dumbbell Incline Bench Press', 3, 8, 12, _r90),
        ProgramExercise('Chest Dip', 3, 10, 15, _r75),
        ProgramExercise('Barbell Curl', 3, 10, 15, _r60),
        ProgramExercise('Dumbbell Hammer Curl', 3, 10, 12, _r60),
      ]),
      ProgramDay('Legs & Core', [
        ProgramExercise('Barbell Front Squat', 3, 8, 12, _r90),
        ProgramExercise('Barbell Romanian Deadlift', 3, 8, 12, _r90),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
        ProgramExercise('Dumbbell Goblet Squat', 3, 10, 15, _r90),
        ProgramExercise('Cable Standing Crunch', 3, 12, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-gvt',
    name: 'German Volume Training',
    category: 'hypertrophy',
    goal: PlanGoal.muscleGain,
    difficulty: 'Advanced',
    daysPerWeek: 3,
    description: 'An old-school ten-sets-of-ten shock program for serious size. Bring a spotter.',
    days: [
      ProgramDay('GVT A', [
        ProgramExercise('Barbell Bench Press', 10, 10, 10, _r90),
        ProgramExercise('Barbell Pendlay Row', 10, 10, 10, _r90),
        ProgramExercise('Barbell Full Squat', 10, 10, 10, _r90),
      ]),
      ProgramDay('GVT B', [
        ProgramExercise('Barbell Deadlift', 10, 10, 10, _r90),
        ProgramExercise('Barbell Standing Wide Military Press', 10, 10, 10, _r90),
        ProgramExercise('Pull-up', 10, 6, 8, _r90),
      ]),
      ProgramDay('GVT C', [
        ProgramExercise('Dumbbell Bench Press', 10, 10, 10, _r90),
        ProgramExercise('Barbell Incline Row', 10, 10, 10, _r90),
        ProgramExercise('Barbell Front Squat', 10, 10, 10, _r90),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-531',
    name: '5/3/1',
    category: 'strength',
    goal: PlanGoal.strength,
    difficulty: 'Intermediate',
    daysPerWeek: 4,
    description: 'Jim Wendler\'s 5/3/1. A slow, boring, proven climb on the big four lifts.',
    days: [
      ProgramDay('Squat Day', [
        ProgramExercise('Barbell Full Squat', 3, 5, 5, _r180),
        ProgramExercise('Barbell Front Squat', 3, 6, 8, _r120),
        ProgramExercise('Seated Leg Curl', 3, 8, 12, _r90),
        ProgramExercise('Cable Standing Crunch', 3, 12, 15, _r60),
      ]),
      ProgramDay('Bench Day', [
        ProgramExercise('Barbell Bench Press', 3, 5, 5, _r180),
        ProgramExercise('Barbell Incline Bench Press', 3, 6, 8, _r120),
        ProgramExercise('Dumbbell Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Triceps Dip', 3, 10, 15, _r75),
      ]),
      ProgramDay('Deadlift Day', [
        ProgramExercise('Barbell Deadlift', 3, 5, 5, _r180),
        ProgramExercise('Barbell Sumo Deadlift', 3, 6, 8, _r120),
        ProgramExercise('Pull-up', 3, 8, 12, _r90),
        ProgramExercise('Barbell Shrug', 3, 8, 12, _r90),
      ]),
      ProgramDay('Press Day', [
        ProgramExercise('Barbell Standing Wide Military Press', 3, 5, 5, _r180),
        ProgramExercise('Dumbbell Bench Press', 3, 6, 8, _r120),
        ProgramExercise('Face Pull', 3, 12, 15, _r75),
        ProgramExercise('Barbell Curl', 3, 10, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-bbb',
    name: 'Boring But Big',
    category: 'strength',
    goal: PlanGoal.strength,
    difficulty: 'Advanced',
    daysPerWeek: 4,
    description: '5/3/1 main lifts with five sets of ten as the anchor. Simple, brutal, effective.',
    days: [
      ProgramDay('Squat Day', [
        ProgramExercise('Barbell Full Squat', 3, 5, 5, _r180),
        ProgramExercise('Barbell Full Squat', 5, 10, 10, _r120),
        ProgramExercise('Cable Standing Crunch', 3, 12, 15, _r60),
        ProgramExercise('Barbell Standing Calf Raise', 4, 10, 15, _r60),
      ]),
      ProgramDay('Bench Day', [
        ProgramExercise('Barbell Bench Press', 3, 5, 5, _r180),
        ProgramExercise('Barbell Bench Press', 5, 10, 10, _r120),
        ProgramExercise('Dumbbell Lateral Raise', 3, 12, 15, _r75),
        ProgramExercise('Barbell Lying Triceps Extension', 3, 10, 15, _r60),
      ]),
      ProgramDay('Deadlift Day', [
        ProgramExercise('Barbell Deadlift', 3, 5, 5, _r180),
        ProgramExercise('Barbell Deadlift', 5, 10, 10, _r120),
        ProgramExercise('Pull-up', 3, 8, 12, _r90),
        ProgramExercise('Barbell Curl', 3, 10, 15, _r60),
      ]),
      ProgramDay('Press Day', [
        ProgramExercise('Barbell Standing Wide Military Press', 3, 5, 5, _r180),
        ProgramExercise('Barbell Standing Wide Military Press', 5, 10, 10, _r120),
        ProgramExercise('Face Pull', 3, 12, 15, _r75),
        ProgramExercise('Triceps Dip', 3, 10, 15, _r75),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-nsuns-5',
    name: 'nSuns 5-Day',
    category: 'strength',
    goal: PlanGoal.strength,
    difficulty: 'Advanced',
    daysPerWeek: 5,
    description: 'The 5-day nSuns LP: two compound lifts mean a brutal but fast strength progression.',
    days: [
      ProgramDay('Bench Focus', [
        ProgramExercise('Barbell Bench Press', 6, 3, 5, _r120),
        ProgramExercise('Barbell Incline Bench Press', 3, 5, 7, _r90),
        ProgramExercise('Chest Dip', 3, 8, 12, _r75),
        ProgramExercise('Dumbbell Lateral Raise', 3, 12, 15, _r60),
      ]),
      ProgramDay('Squat Focus', [
        ProgramExercise('Barbell Full Squat', 7, 3, 5, _r120),
        ProgramExercise('Barbell Front Squat', 3, 6, 8, _r90),
        ProgramExercise('Seated Leg Curl', 3, 10, 15, _r75),
        ProgramExercise('Cable Standing Crunch', 3, 12, 15, _r60),
      ]),
      ProgramDay('Press Focus', [
        ProgramExercise('Barbell Standing Wide Military Press', 6, 3, 5, _r120),
        ProgramExercise('Barbell Bench Press', 3, 5, 7, _r90),
        ProgramExercise('Triceps Dip', 3, 8, 12, _r75),
        ProgramExercise('Dumbbell Lateral Raise', 3, 12, 15, _r60),
      ]),
      ProgramDay('Deadlift Focus', [
        ProgramExercise('Barbell Sumo Deadlift', 6, 3, 5, _r120),
        ProgramExercise('Barbell Romanian Deadlift', 3, 6, 8, _r90),
        ProgramExercise('Pull-up', 3, 8, 12, _r75),
        ProgramExercise('Barbell Curl', 3, 10, 12, _r60),
      ]),
      ProgramDay('Squat Volume', [
        ProgramExercise('Barbell Front Squat', 6, 3, 5, _r120),
        ProgramExercise('Dumbbell Goblet Squat', 3, 10, 12, _r90),
        ProgramExercise('Dumbbell Lunge', 3, 10, 12, _r75),
        ProgramExercise('Barbell Standing Calf Raise', 3, 12, 15, _r60),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-gzclp',
    name: 'GZCLP',
    category: 'strength',
    goal: PlanGoal.strength,
    difficulty: 'Beginner',
    daysPerWeek: 4,
    description: 'Cody Lefever\'s intuitive linear progression: Tier 1, Tier 2 and pump work.',
    days: [
      ProgramDay('A Squat/Bench', [
        ProgramExercise('Barbell Full Squat', 5, 3, 3, _r180),
        ProgramExercise('Barbell Bench Press', 3, 10, 10, _r120),
        ProgramExercise('Barbell Pendlay Row', 3, 12, 15, _r90),
      ]),
      ProgramDay('B Press/Deadlift', [
        ProgramExercise('Barbell Standing Wide Military Press', 5, 3, 3, _r180),
        ProgramExercise('Barbell Deadlift', 3, 10, 10, _r120),
        ProgramExercise('Lat Pulldown', 3, 12, 15, _r90),
      ]),
      ProgramDay('C Bench/Squat', [
        ProgramExercise('Barbell Bench Press', 5, 3, 3, _r180),
        ProgramExercise('Barbell Full Squat', 3, 10, 10, _r120),
        ProgramExercise('Barbell Pendlay Row', 3, 12, 15, _r90),
      ]),
      ProgramDay('D Deadlift/Press', [
        ProgramExercise('Barbell Deadlift', 5, 3, 3, _r180),
        ProgramExercise('Barbell Standing Wide Military Press', 3, 10, 10, _r120),
        ProgramExercise('Pull-up', 3, 12, 15, _r90),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-madcow-5x5',
    name: 'Madcow 5x5',
    category: 'strength',
    goal: PlanGoal.strength,
    difficulty: 'Intermediate',
    daysPerWeek: 3,
    description: 'The intermediate answer to StrongLifts: three heavy-compound days with weekly ramp-ups.',
    days: [
      ProgramDay('Madcow A', [
        ProgramExercise('Barbell Full Squat', 5, 5, 5, _r180),
        ProgramExercise('Barbell Bench Press', 5, 5, 5, _r180),
        ProgramExercise('Barbell Pendlay Row', 5, 5, 5, _r180),
      ]),
      ProgramDay('Madcow B', [
        ProgramExercise('Barbell Full Squat', 5, 5, 5, _r180),
        ProgramExercise('Barbell Standing Wide Military Press', 5, 5, 5, _r180),
        ProgramExercise('Barbell Deadlift', 5, 5, 5, _r180),
      ]),
      ProgramDay('Madcow C', [
        ProgramExercise('Barbell Full Squat', 5, 5, 5, _r180),
        ProgramExercise('Barbell Bench Press', 5, 5, 5, _r180),
        ProgramExercise('Barbell Pendlay Row', 5, 5, 5, _r180),
      ]),
    ],
  ),

  // ------------------------------------------------------------------ HOME
  ProgramDef(
    id: 'lib-home-fullbody',
    name: 'Home Full Body',
    category: 'home',
    goal: PlanGoal.generalFitness,
    difficulty: 'Beginner',
    daysPerWeek: 3,
    description: 'A no-equipment full-body burner for home. Push, squat, plank and repeat.',
    days: [
      ProgramDay('Home A', [
        ProgramExercise('Bodyweight Squat', 3, 12, 15, _r60),
        ProgramExercise('Push-up', 3, 10, 15, _r60),
        ProgramExercise('Crunch Floor', 3, 15, 20, _r45),
        ProgramExercise('Plank Shoulder Tap', 3, 15, 20, _r45),
      ]),
      ProgramDay('Home B', [
        ProgramExercise('Incline Push-up', 3, 12, 15, _r60),
        ProgramExercise('Reverse Lunge', 3, 10, 12, _r60),
        ProgramExercise('Chair Dip', 3, 10, 15, _r60),
        ProgramExercise('Weighted Front Plank', 3, 10, 12, _r45),
      ]),
      ProgramDay('Home C', [
        ProgramExercise('Bodyweight Squat', 3, 12, 15, _r60),
        ProgramExercise('Push-up', 3, 10, 15, _r60),
        ProgramExercise('Crunch Floor', 3, 15, 20, _r45),
        ProgramExercise('Plank Shoulder Tap', 3, 15, 20, _r45),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-home-ppl',
    name: 'Home PPL',
    category: 'home',
    goal: PlanGoal.muscleGain,
    difficulty: 'Intermediate',
    daysPerWeek: 3,
    description: 'Push, pull and legs using only your body and a bar. A three-day home split.',
    days: [
      ProgramDay('Push', [
        ProgramExercise('Push-up', 3, 12, 15, _r60),
        ProgramExercise('Chair Dip', 3, 10, 15, _r60),
        ProgramExercise('Incline Push-up', 3, 12, 15, _r60),
        ProgramExercise('Plank Shoulder Tap', 3, 15, 20, _r45),
      ]),
      ProgramDay('Pull', [
        ProgramExercise('Pull-up', 3, 6, 10, _r90),
        ProgramExercise('Chin-up', 3, 6, 10, _r90),
        ProgramExercise('Biceps Narrow Pull-ups', 3, 6, 10, _r90),
        ProgramExercise('Bodyweight Squatting Row', 3, 10, 12, _r60),
      ]),
      ProgramDay('Legs', [
        ProgramExercise('Bodyweight Squat', 3, 15, 20, _r60),
        ProgramExercise('Reverse Lunge', 3, 10, 12, _r60),
        ProgramExercise('Sissy Squat', 3, 10, 15, _r60),
        ProgramExercise('Bodyweight Standing Calf Raise', 3, 15, 20, _r45),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-home-core',
    name: 'Core & Total Body',
    category: 'home',
    goal: PlanGoal.generalFitness,
    difficulty: 'Beginner',
    daysPerWeek: 3,
    description: 'A core-and-conditioning circuit that needs zero equipment and promises a sore stomach.',
    days: [
      ProgramDay('Core A', [
        ProgramExercise('Crunch Floor', 3, 15, 20, _r45),
        ProgramExercise('Bicycle Crunch', 3, 12, 15, _r45),
        ProgramExercise('Plank Shoulder Tap', 3, 15, 20, _r45),
        ProgramExercise('Bodyweight Squat', 3, 12, 15, _r45),
      ]),
      ProgramDay('Core B', [
        ProgramExercise('Bicycle Crunch', 3, 12, 15, _r45),
        ProgramExercise('Side Plank Hip Dip', 3, 10, 12, _r45),
        ProgramExercise('Squat Thrust', 3, 12, 15, _r45),
        ProgramExercise('Crunch Floor', 3, 15, 20, _r45),
      ]),
      ProgramDay('Core C', [
        ProgramExercise('Plank Shoulder Tap', 3, 15, 20, _r45),
        ProgramExercise('Weighted Front Plank', 3, 10, 12, _r45),
        ProgramExercise('Sissy Squat', 3, 10, 15, _r45),
        ProgramExercise('Bodyweight Standing Calf Raise', 3, 15, 20, _r45),
      ]),
    ],
  ),

  // -------------------------------------------------------- GENERAL FITNESS
  ProgramDef(
    id: 'lib-fat-loss',
    name: 'Fat Loss Full Body',
    category: 'general',
    goal: PlanGoal.fatLoss,
    difficulty: 'Intermediate',
    daysPerWeek: 3,
    description: 'A metabolic full-body circuit with short rests to keep the heart rate up.',
    days: [
      ProgramDay('Burn A', [
        ProgramExercise('Squat Thrust', 3, 12, 15, _r45),
        ProgramExercise('Dumbbell Lunge', 3, 10, 12, _r45),
        ProgramExercise('Push-up', 3, 12, 15, _r45),
        ProgramExercise('Kettlebell Swing', 3, 12, 15, _r45),
        ProgramExercise('Crunch Floor', 3, 15, 20, _r45),
      ]),
      ProgramDay('Burn B', [
        ProgramExercise('Kettlebell Swing', 3, 12, 15, _r45),
        ProgramExercise('Bodyweight Squat', 3, 15, 20, _r45),
        ProgramExercise('Incline Push-up', 3, 12, 15, _r45),
        ProgramExercise('Reverse Lunge', 3, 10, 12, _r45),
        ProgramExercise('Bicycle Crunch', 3, 12, 15, _r45),
      ]),
      ProgramDay('Burn C', [
        ProgramExercise('Squat Thrust', 3, 12, 15, _r45),
        ProgramExercise('Kettlebell Goblet Squat', 3, 10, 12, _r45),
        ProgramExercise('Push-up', 3, 12, 15, _r45),
        ProgramExercise('Bodyweight Standing Calf Raise', 3, 15, 20, _r45),
        ProgramExercise('Crunch Floor', 3, 15, 20, _r45),
      ]),
    ],
  ),
  ProgramDef(
    id: 'lib-conditioning',
    name: 'Conditioning Circuit',
    category: 'general',
    goal: PlanGoal.generalFitness,
    difficulty: 'Intermediate',
    daysPerWeek: 3,
    description: 'Kettlebell-and-bodyweight conditioning for work capacity and a tired but happy you.',
    days: [
      ProgramDay('Conditioning A', [
        ProgramExercise('Kettlebell Goblet Squat', 3, 15, 20, _r45),
        ProgramExercise('Kettlebell Swing', 3, 15, 20, _r45),
        ProgramExercise('Bodyweight Squat', 3, 20, 20, _r45),
        ProgramExercise('Squat Thrust', 3, 15, 20, _r45),
        ProgramExercise('Crunch Floor', 3, 20, 20, _r45),
      ]),
      ProgramDay('Conditioning B', [
        ProgramExercise('Kettlebell Swing', 3, 15, 20, _r45),
        ProgramExercise('Push-up', 3, 15, 20, _r45),
        ProgramExercise('Reverse Lunge', 3, 12, 15, _r45),
        ProgramExercise('Plank Shoulder Tap', 3, 15, 20, _r45),
        ProgramExercise('Bodyweight Standing Calf Raise', 3, 20, 20, _r45),
      ]),
      ProgramDay('Conditioning C', [
        ProgramExercise('Kettlebell Goblet Squat', 3, 15, 20, _r45),
        ProgramExercise('Squat Thrust', 3, 15, 20, _r45),
        ProgramExercise('Incline Push-up', 3, 15, 20, _r45),
        ProgramExercise('Bicycle Crunch', 3, 15, 20, _r45),
        ProgramExercise('Treadmill Incline Walk', 3, 20, 20, _r45),
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
