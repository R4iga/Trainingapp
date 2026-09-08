import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../catalog/exercise_catalog.dart';
import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final equipped = fit.userEquipment;
    final count = fit.exercisableCount;
    final total = fit.allExercises.length;
    final coverage = total > 0 ? (count / total * 100).round() : 0;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: [
          _header(gc),
          const SizedBox(height: 18),
          _statsBar(gc, count, total, coverage),
          const SizedBox(height: 22),
          _sectionLabel(gc, t.equipmentPresetLabel),
          const SizedBox(height: 10),
          _presets(gc),
          const SizedBox(height: 24),
          _sectionLabel(gc, t.equipmentYourGear),
          const SizedBox(height: 10),
          _gearGrid(gc, equipped),
          const SizedBox(height: 24),
          _sectionLabel(gc, t.equipmentCoverageLabel),
          const SizedBox(height: 10),
          _coverageBar(gc, coverage),
          const SizedBox(height: 12),
          _muscleCoverage(gc),
          const SizedBox(height: 24),
          _sectionLabel(gc, t.equipmentSuggestedLabel),
          const SizedBox(height: 10),
          _suggestedSplit(gc),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _header(GymColors gc) {
    return Row(children: [
      RoundBtn(icon: Ic.chevronLeft, onTap: fit.popRoute),
      const SizedBox(width: 12),
      ScreenTitle(t.equipmentTitle),
    ]);
  }

  Widget _statsBar(GymColors gc, int count, int total, int coverage) {
    return SoftCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(gc, '$count', t.equipmentStatExercises),
          Container(width: 1, height: 24, color: gc.border),
          _stat(gc, '${fit.userEquipment.length}', t.equipmentStatGear),
          Container(width: 1, height: 24, color: gc.border),
          _stat(gc, '$coverage%', t.equipmentStatCoverage),
        ],
      ),
    );
  }

  Widget _stat(GymColors gc, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: AppTheme.d(22, weight: FontWeight.w700, color: gc.ember)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTheme.s(11, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 1)),
      ],
    );
  }

  Widget _sectionLabel(GymColors gc, String text) {
    return Text(text,
        style: AppTheme.d(12, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 3));
  }

  Widget _presets(GymColors gc) {
    return Column(
      children: [
        _presetRow(gc, t.equipmentPresetHome, ['Bodyweight', 'Dumbbell', 'Kettlebell', 'Band', 'Weighted']),
        const SizedBox(height: 8),
        _presetRow(gc, t.equipmentPresetFullGym, kEquipment),
        const SizedBox(height: 8),
        _presetRow(gc, t.equipmentPresetMinimal, ['Bodyweight', 'Dumbbell', 'Band']),
      ],
    );
  }

  Widget _presetRow(GymColors gc, String label, List<String> preset) {
    final match = preset.every(fit.hasEquipment) && fit.userEquipment.length <= preset.length;
    return GestureDetector(
      onTap: () => _applyPreset(preset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: match ? gc.ember.withAlpha(30) : gc.bgRaised,
          border: Border.all(color: match ? gc.ember : gc.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(
            match ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
            size: 20,
            color: match ? gc.ember : gc.textTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
          ),
          Text('${preset.length}',
              style: AppTheme.s(12, color: gc.textSecondary)),
        ]),
      ),
    );
  }

  void _applyPreset(List<String> preset) {
    fit.applyEquipmentPreset(preset.toSet());
  }

  Widget _gearGrid(GymColors gc, Set<String> equipped) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final eq in kFilterEquipment) _gearChip(gc, eq, equipped.contains(eq)),
      ],
    );
  }

  Widget _gearChip(GymColors gc, String eq, bool selected) {
    final count = fit.allExercises.where((e) => e.equipment == eq).length;
    return GestureDetector(
      onTap: () => fit.toggleUserEquipment(eq),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? gc.ember : gc.bgRaised,
          border: Border.all(color: selected ? gc.ember : gc.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.equipment(eq),
                style: AppTheme.s(13,
                    weight: FontWeight.w600,
                    color: selected ? gc.onEmber : gc.text)),
            const SizedBox(height: 2),
            Text('$count ${t.exercises.toLowerCase()}',
                style: AppTheme.s(10,
                    color: selected ? gc.onEmber.withAlpha(180) : gc.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _coverageBar(GymColors gc, int coverage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: coverage / 100,
            minHeight: 8,
            backgroundColor: gc.bgRaised2,
            valueColor: AlwaysStoppedAnimation<Color>(gc.ember),
          ),
        ),
        const SizedBox(height: 6),
        Text(t.equipmentCoverageText(coverage),
            style: AppTheme.s(12, color: gc.textSecondary)),
      ],
    );
  }

  Widget _muscleCoverage(GymColors gc) {
    final covered = fit.availableMuscleCoverage;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in kFilterMuscles)
          _musclePill(gc, m, covered.contains(m)),
      ],
    );
  }

  Widget _musclePill(GymColors gc, String muscle, bool covered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: covered ? gc.ember.withAlpha(30) : gc.bgRaised2,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            covered ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
            size: 14,
            color: covered ? gc.ember : gc.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(muscleLabel(muscle),
              style: AppTheme.s(11,
                  weight: FontWeight.w600,
                  color: covered ? gc.ember : gc.textSecondary)),
        ],
      ),
    );
  }

  Widget _suggestedSplit(GymColors gc) {
    final split = fit.suggestSplit();
    if (split.isEmpty) {
      return Text(t.equipmentNoSuggestions,
          style: AppTheme.s(13, color: gc.textTertiary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (focus, exs) in split) _splitDay(gc, focus, exs),
      ],
    );
  }

  Widget _splitDay(GymColors gc, String focus, List<Exercise> exs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(focus.toUpperCase(),
              style: AppTheme.d(11, weight: FontWeight.w600, color: gc.brass, letterSpacing: 2)),
          const SizedBox(height: 8),
          for (final ex in exs)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(PhosphorIconsRegular.caretRight, size: 14, color: gc.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(exerciseName(ex),
                      style: AppTheme.s(13, color: gc.text)),
                ),
                Text(muscleLabel(ex.primary),
                    style: AppTheme.s(10, color: gc.textSecondary)),
              ]),
            ),
        ],
      ),
    );
  }
}
