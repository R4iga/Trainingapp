import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../widgets/home_widget_views.dart';
import 'today_widget.dart';

class HomeWidgetBridge {
  HomeWidgetBridge._();

  static const _pkg = 'com.gymmane.app';
  static const heatmapKey = 'heatmap_img';
  static const statsKey = 'stats_img';
  static const bodyKey = 'body_img';
  static const todayKey = 'today_img';
  static const nextUpKey = 'next_up_img';
  static const bodyDays = 7;
  static bool get _supported => !kIsWeb && Platform.isAndroid;

  static Future<void> update() async {
    if (!_supported) return;
    try {
      final gc = fit.dark ? GymColors.dark : GymColors.light;
      await HomeWidget.renderFlutterWidget(
        HeatmapWidgetView(
          gc: gc,
          levels: fit.heatmapLevelsFor(182),
          streak: fit.currentStreak,
          size: const Size(320, 150),
        ),
        key: heatmapKey,
        logicalSize: const Size(320, 150),
        pixelRatio: 3,
      );
      await HomeWidget.renderFlutterWidget(
        StatsWidgetView(
          gc: gc,
          streak: fit.currentStreak,
          sessionsThisWeek: fit.sessionsThisWeek,
          goalPct: fit.goalPct,
          size: const Size(155, 155),
        ),
        key: statsKey,
        logicalSize: const Size(155, 155),
        pixelRatio: 3,
      );
      await HomeWidget.renderFlutterWidget(
        BodyWidgetView(
          gc: gc,
          intensity: fit.muscleHeatOver(bodyDays),
          days: bodyDays,
          size: const Size(320, 220),
        ),
        key: bodyKey,
        logicalSize: const Size(320, 220),
        pixelRatio: 3,
      );
      final sessionDay = fit.activeSessionDay();
      final liveDone = fit.session == null || fit.session!.complete
          ? 0
          : fit.session!.exercises.fold(
              0,
              (int a, e) => a + e.sets.where((s) => s.done && s.counts).length,
            );
      final card = buildTodayCard(
        plans: fit.plans,
        liveDay: sessionDay,
        sessions: fit.sessions,
        isRepsOnly: fit.isRepsOnly,
        units: fit.units,
        streak: fit.currentStreak,
        todaySets: fit.setsToday + liveDone,
      );
      await HomeWidget.renderFlutterWidget(
        TodayWidgetView(gc: gc, data: card, size: const Size(320, 230)),
        key: todayKey,
        logicalSize: const Size(320, 230),
        pixelRatio: 3,
      );
      await HomeWidget.renderFlutterWidget(
        NextUpWidgetView(gc: gc, data: card, size: const Size(160, 155)),
        key: nextUpKey,
        logicalSize: const Size(160, 155),
        pixelRatio: 3,
      );
      await HomeWidget.updateWidget(
          qualifiedAndroidName: '$_pkg.HeatmapWidgetProvider');
      await HomeWidget.updateWidget(
          qualifiedAndroidName: '$_pkg.BodyWidgetProvider');
      await HomeWidget.updateWidget(
          qualifiedAndroidName: '$_pkg.StatsWidgetProvider');
      await HomeWidget.updateWidget(
          qualifiedAndroidName: '$_pkg.TodayWidgetProvider');
      await HomeWidget.updateWidget(
          qualifiedAndroidName: '$_pkg.NextUpWidgetProvider');
    } catch (e) {
      debugPrint('HomeWidgetBridge.update falló: $e');
    }
  }
}
