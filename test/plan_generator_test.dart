import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/catalog/workout_programs.dart';
import 'package:gymmane/services/exercise_match.dart';

void main() {
  test('the library has a big, high quality program selection', () {
    expect(kProgramLibrary.length, greaterThan(30), reason: 'a ton of programs');
    expect(programsInCategory('home'), isNotEmpty);
    expect(programsInCategory('general'), isNotEmpty);

    var total = 0;
    final unresolved = <String>[];
    for (final p in kProgramLibrary) {
      expect(p.daysPerWeek, p.days.length, reason: '${p.id} day count mismatch');
      for (final d in p.days) {
        expect(d.exercises, isNotEmpty, reason: '${p.id} has an empty day');
        for (final pe in d.exercises) {
          total++;
          if (matchExercise(pe.name, kExercises) == null) {
            unresolved.add('${p.id} :: ${pe.name}');
          }
        }
      }
    }
    expect(total, greaterThan(400));
    expect(unresolved, isEmpty, reason: 'unresolved library exercises:\n${unresolved.join("\n")}');
  });
}