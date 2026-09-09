import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/services/today_widget.dart';
import 'package:gymmane/theme/app_colors.dart';
import 'package:gymmane/widgets/home_widget_views.dart';

void main() {
  Future<void> draw(WidgetTester tester, Widget view) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: view),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  for (final (name, gc) in [('dark', GymColors.dark), ('light', GymColors.light)]) {
    testWidgets('the three home widgets draw in $name without overflowing', (tester) async {
      await draw(tester, HeatmapWidgetView(gc: gc, levels: List.filled(182, 2), streak: 12));
      await draw(tester,
          StatsWidgetView(gc: gc, streak: 12, sessionsThisWeek: 3, goalPct: 75));
      await draw(
          tester,
          BodyWidgetView(
            gc: gc,
            days: 7,
            intensity: const {'chest': 1.0, 'back': 0.5, 'quads': 0.1},
          ));
      await draw(
        tester,
        TodayWidgetView(
          gc: gc,
          data: const TodayCardData(
            live: false,
            rest: false,
            dayName: 'Push',
            streak: 12,
            todaySets: 6,
            lifts: [
              LiftHintRow(name: 'Bench', weightLabel: '62.5 kg', repLabel: '8-10', lastReps: 10),
              LiftHintRow(name: 'Shoulder Press', weightLabel: '40 kg', repLabel: '8', lastReps: 8),
            ],
          ),
        ),
      );
      await draw(
        tester,
        NextUpWidgetView(
          gc: gc,
          data: const TodayCardData(
            live: false,
            rest: false,
            dayName: 'Push',
            streak: 0,
            todaySets: 0,
            lifts: [
              LiftHintRow(name: 'Bench', weightLabel: '62.5 kg', repLabel: '8-10', lastReps: 10),
            ],
          ),
        ),
      );
    });
  }

  testWidgets('the muscle map widget survives an empty history', (tester) async {
    await draw(tester,
        const BodyWidgetView(gc: GymColors.dark, days: 7, intensity: {}));
  });

  testWidgets('the today widgets hold up against empty data', (tester) async {
    const empty = TodayCardData(
      live: false,
      rest: false,
      dayName: null,
      streak: 0,
      todaySets: 0,
      lifts: [],
    );
    await draw(tester, const TodayWidgetView(gc: GymColors.dark, data: empty));
    await draw(tester, const NextUpWidgetView(gc: GymColors.dark, data: empty));
  });
}
