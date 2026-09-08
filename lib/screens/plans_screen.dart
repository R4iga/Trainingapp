import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../l10n/l10n.dart';
import '../models/workout_plan.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final plans = fit.visiblePlans;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(title: t.plans, onBack: fit.backFromPlans, titleSize: 22),
            const SizedBox(height: 14),
            PrimaryButton(
              label: t.browseLibrary,
              icon: Ic.layers,
              onTap: fit.openLibrary,
            ),
            const SizedBox(height: 26),
            Text(t.myPlans,
                style: AppTheme.d(12, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 3)),
            const SizedBox(height: 10),
            if (plans.isEmpty)
              _emptyState(gc)
            else
              for (final p in plans) _planCard(gc, p),
            const SizedBox(height: 16),
            PrimaryButton(
              label: t.newPlan,
              icon: Ic.plus,
              onTap: () => fit.openPlan(fit.createPlan()),
            ),
            if (fit.archivedPlans.isNotEmpty) ...[
              const SizedBox(height: 26),
              Text(t.archivedPlans,
                  style: AppTheme.d(12, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 3)),
              const SizedBox(height: 10),
              for (final p in fit.archivedPlans) _planCard(gc, p, archived: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(GymColors gc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(PhosphorIconsRegular.notebook, size: 40, color: gc.textTertiary),
          const SizedBox(height: 14),
          Text(t.emptyPlans,
              textAlign: TextAlign.center, style: AppTheme.s(13, color: gc.textSecondary)),
        ],
      ),
    );
  }

  Widget _planCard(GymColors gc, WorkoutPlan p, {bool archived = false}) {
    return GestureDetector(
      onTap: () => fit.openPlan(p.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          border: Border.all(color: archived ? gc.border : (p.favorite ? gc.brass : gc.border)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: gc.emberSoft, borderRadius: BorderRadius.circular(12)),
                  child: Icon(p.favorite ? PhosphorIconsFill.bookmarkSimple : PhosphorIconsRegular.bookmarkSimple,
                      size: 22, color: gc.ember),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: AppTheme.s(15, weight: FontWeight.w600, color: gc.text)),
                      const SizedBox(height: 2),
                      Text('${t.planDaysCount(p.dayCount)} · ${t.planExercisesCount(p.totalExercises)}',
                          style: AppTheme.s(12, color: gc.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chip(gc, t.planGoalName(p.goal.name)),
                _chip(gc, t.difficulty(p.difficulty)),
                _chip(gc, _sourceLabel(p)),
              ],
            ),
            const SizedBox(height: 8),
            if (p.days.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final d in p.days) _dayPill(gc, d.name),
                  ],
                ),
              )
            else
              Text(t.planNameHint, style: AppTheme.s(12, color: gc.textTertiary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => fit.togglePlanFavorite(p.id),
                  child: Icon(
                    p.favorite ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                    size: 20,
                    color: p.favorite ? gc.brass : gc.textTertiary,
                  ),
                ),
                Row(children: [
                  _iconAction(gc, Ic.layers, t.duplicatePlan, () => _duplicate(p)),
                  const SizedBox(width: 14),
                  _iconAction(gc, Ic.close, archived ? t.unarchivePlan : t.archivePlan,
                      () => archived ? fit.unarchivePlan(p.id) : fit.archivePlan(p.id)),
                  const SizedBox(width: 10),
                  if (p.days.isNotEmpty)
                    GestureDetector(
                      onTap: () => fit.startPlanDay(p, _firstDayWithExercises(p)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: gc.ember,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(children: [
                          Icon(PhosphorIconsFill.play, size: 15, color: gc.onEmber),
                          const SizedBox(width: 6),
                          Text(t.startPlan,
                              style: AppTheme.d(12, weight: FontWeight.w600, color: gc.onEmber, letterSpacing: 1)),
                        ]),
                      ),
                    ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _firstDayWithExercises(WorkoutPlan p) {
    for (var i = 0; i < p.days.length; i++) {
      if (p.days[i].exercises.isNotEmpty) return i;
    }
    return 0;
  }

  String _sourceLabel(WorkoutPlan p) => switch (p.source) {
        'library' => t.planSourceLibrary,
        'imported' => t.planSourceImported,
        'shared' => t.planSourceShared,
        _ => t.planSourceCustom,
      };

  void _duplicate(WorkoutPlan p) {
    final copy = fit.duplicatePlan(p.id);
    fit.openPlan(copy.id);
  }

  Widget _chip(GymColors gc, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: AppTheme.s(11.5, weight: FontWeight.w600, color: gc.textSecondary)),
    );
  }

  Widget _dayPill(GymColors gc, String name) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: gc.border),
      ),
      child: Text(name, style: AppTheme.s(12, weight: FontWeight.w600, color: gc.text)),
    );
  }

  Widget _iconAction(GymColors gc, List<IconPath> icon, String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: gc.bgRaised2, shape: BoxShape.circle),
          child: Center(child: SvgPathIcon(icon, size: 16, color: gc.textSecondary)),
        ),
      ),
    );
  }
}
