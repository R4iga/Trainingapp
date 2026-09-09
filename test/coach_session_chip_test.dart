import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    fit.resetAllData();
    fit.setUnits('kg');
    fit.onboarded = true;
    fit.sessions.add(LoggedSession(DateTime(2026, 9, 7), 1200, [
      LoggedExercise('EIeI8Vf', 'Barbell Bench Press', 'chest', [
        LoggedSet(10, 60),
      ]),
    ]));
    fit.startWorkout();
    fit.toggleMuscle('chest');
    fit.trainContinue();
    fit.startSession();
    fit.session!.currentIndex =
        fit.session!.exercises.indexWhere((e) => e.id == 'EIeI8Vf');
    fit.route = 'session';
  });

  testWidgets('session shows a tappable smart-weight chip', (tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('62.5'), findsOneWidget, reason: 'bump a 62.5 kg');
  });

  testWidgets('tapping the chip pre-fills the next set', (tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.textContaining('62.5').first);
    await tester.pump(const Duration(milliseconds: 500));
    final ex = fit.session!.exercises.firstWhere((e) => e.id == 'EIeI8Vf');
    expect(ex.sets.first.weight, closeTo(62.5, 0.001));
  });
}
