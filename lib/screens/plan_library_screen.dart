import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../catalog/workout_programs.dart';
import '../l10n/l10n.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

class PlanLibraryScreen extends StatelessWidget {
  const PlanLibraryScreen({super.key});

  String _categoryLabel(String cat) => switch (cat) {
        'lemon' => t.libraryLemon,
        'beginner' => t.libraryBeginner,
        'hypertrophy' => t.libraryHypertrophy,
        'strength' => t.libraryStrength,
        'general' => t.libraryGeneral,
        _ => t.libraryHome,
      };

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(title: t.planLibrary, onBack: fit.backFromLibrary, titleSize: 22),
            const SizedBox(height: 20),
            for (final cat in kProgramCategories)
              if (programsInCategory(cat).isNotEmpty) ...[
                Text(_categoryLabel(cat),
                    style: AppTheme.d(12, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 3)),
                const SizedBox(height: 10),
                for (final p in programsInCategory(cat)) _programCard(gc, p),
                const SizedBox(height: 22),
              ],
          ],
        ),
      ),
    );
  }

  Widget _programCard(GymColors gc, ProgramDef p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: p.category == 'lemon' ? gc.brass : gc.border),
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
                decoration: BoxDecoration(
                  color: p.category == 'lemon' ? gc.brass.withValues(alpha: 0.18) : gc.emberSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(PhosphorIconsRegular.barbell, size: 22, color: gc.ember),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: AppTheme.s(15, weight: FontWeight.w600, color: gc.text)),
                    const SizedBox(height: 2),
                    Text(
                      '${t.programDays(p.daysPerWeek)} · ${t.difficulty(p.difficulty)}',
                      style: AppTheme.s(12, color: gc.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(p.description, style: AppTheme.s(12.5, color: gc.textSecondary)),
          const SizedBox(height: 8),
          Scrollbar(
            thumbVisibility: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final d in p.days) _dayChip(gc, d.name),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _import(p),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: gc.ember,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(t.importPlan,
                  style: AppTheme.d(13, weight: FontWeight.w600, color: gc.onEmber, letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayChip(GymColors gc, String name) {
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

  void _import(ProgramDef p) {
    final plan = fit.importLibraryPlan('lib-${p.id}');
    fit.openPlan(plan.id);
  }
}
