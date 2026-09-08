import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('Bodyweight is always available regardless of gear', () {
    fit.userEquipment.clear();
    expect(fit.hasEquipment('Bodyweight'), isTrue);
    expect(fit.hasEquipment('Barbell'), isFalse);
  });

  test('toggleUserEquipment adds and removes gear', () {
    fit.userEquipment.clear();
    fit.toggleUserEquipment('Dumbbell');
    expect(fit.userEquipment, contains('Dumbbell'));
    fit.toggleUserEquipment('Dumbbell');
    expect(fit.userEquipment, isNot(contains('Dumbbell')));
  });

  test('the recommendation engine only returns exercisable exercises', () {
    fit.userEquipment
      ..clear()
      ..addAll(const ['Bodyweight', 'Dumbbell']);
    for (final muscle in kFilterMuscles) {
      for (final ex in fit.recommendForMuscle(muscle)) {
        expect(fit.canDoExercise(ex), isTrue, reason: '${ex.name} needs ${ex.equipment}');
        expect(ex.primary == muscle || ex.secondary.contains(muscle), isTrue);
      }
    }
  });

  test('favourites rank first in a muscle recommendation', () {
    fit.userEquipment
      ..clear()
      ..addAll(const ['Barbell', 'Bodyweight', 'Dumbbell']);
    final pool = kExercises.where((e) => e.primary == 'chest').toList();
    expect(pool, isNotEmpty);
    final fav = pool.first;
    fit.favorites[fav.id] = true;
    final recs = fit.recommendForMuscle('chest');
    expect(recs.first.id, fav.id);
    fit.favorites.clear();
  });

  test('planEquipmentIssues flags exercises the user cannot do', () {
    final plan = fit.duplicatePlan('lib-lib-lemon-beginner');
    fit.userEquipment.clear();
    final issues = fit.planEquipmentIssues(plan);
    expect(issues, isNotEmpty);
    for (final (_, name, missing) in issues) {
      expect(missing, isNotEmpty, reason: name);
    }
    fit.userEquipment.addAll(kEquipment);
    expect(fit.planEquipmentIssues(plan), isEmpty);
  });

  test('equipmentAlternatives returns only doable alternatives for the same muscle', () {
    final barbellBench = kExercises.firstWhere((e) => e.id == 'EIeI8Vf');
    fit.userEquipment
      ..clear()
      ..addAll(const ['Bodyweight', 'Dumbbell']);
    final alts = fit.equipmentAlternatives(barbellBench);
    expect(alts, isNotEmpty);
    for (final a in alts) {
      expect(fit.canDoExercise(a), isTrue);
      expect(a.primary, 'chest');
    }
  });

  test('compatibleLibraryPlans only returns plans the user can fully perform', () {
    fit.userEquipment.clear();
    for (final plan in fit.compatibleLibraryPlans()) {
      expect(fit.planEquipmentIssues(plan), isEmpty,
          reason: '${plan.name} is not compatible');
    }
    // With no gear, bodyweight-only programs should be the only compatible ones.
    final bwOnly = fit.compatibleLibraryPlans();
    for (final p in bwOnly) {
      for (final day in p.days) {
        for (final pe in day.exercises) {
          final ex = fit.exerciseById(pe.exerciseId);
          expect(ex?.equipment ?? 'Bodyweight', 'Bodyweight',
              reason: '${p.name}: ${pe.name}');
        }
      }
    }
    fit.userEquipment.addAll(kEquipment);
    expect(fit.compatibleLibraryPlans().length, greaterThanOrEqualTo(bwOnly.length));
  });
}