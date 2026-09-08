import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../catalog/exercise_catalog.dart';
import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../services/exercise_match.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';

class PlanEditScreen extends StatefulWidget {
  const PlanEditScreen({super.key});

  @override
  State<PlanEditScreen> createState() => _PlanEditScreenState();
}

class _PlanEditScreenState extends State<PlanEditScreen> {
  late final String _id = fit.activePlanId!;
  late final TextEditingController _name =
      TextEditingController(text: fit.activePlan?.name ?? '');
  late final TextEditingController _desc =
      TextEditingController(text: fit.activePlan?.description ?? '');
  final TextEditingController _search = TextEditingController();
  String _q = '';
  int? _openDay;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _search.dispose();
    super.dispose();
  }

  List<Exercise> get _filtered {
    if (_q.trim().isEmpty) return kExercises;
    return kExercises.where(exerciseSearch(_q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final plan = fit.activePlan;
    if (plan == null) return const SizedBox.shrink();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                _header(gc, plan),
                const SizedBox(height: 18),
                _details(gc, plan),
                const SizedBox(height: 22),
                _daysLabel(gc),
                const SizedBox(height: 10),
                for (int i = 0; i < plan.days.length; i++) _dayCard(gc, plan, i),
                const SizedBox(height: 10),
                GhostButton(label: t.addDay, icon: PhosphorIconsRegular.plus,
                    onTap: () => fit.addPlanDay(plan.id)),
                const SizedBox(height: 26),
                _searchField(gc, plan),
              ],
            ),
          ),
          if (_openDay != null && _openDay! < plan.days.length && plan.days[_openDay!].exercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: t.startPlan,
                icon: Ic.play,
                onTap: () => fit.startPlanDay(plan, _openDay!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(GymColors gc, WorkoutPlan plan) {
    return Column(
      children: [
        Row(children: [
          RoundBtn(icon: Ic.chevronLeft, onTap: fit.closePlanEdit),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _name,
              autofocus: plan.name.isEmpty,
              style: AppTheme.d(22, weight: FontWeight.w700, color: gc.text, letterSpacing: 0.5),
              cursorColor: gc.accent,
              textCapitalization: TextCapitalization.words,
              onChanged: (v) => fit.renamePlan(_id, v),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: t.planNameHint,
                hintStyle: AppTheme.d(22, weight: FontWeight.w700, color: gc.textTertiary),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => fit.togglePlanFavorite(plan.id),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                plan.favorite ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                size: 20,
                color: plan.favorite ? gc.brass : gc.textTertiary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showPlanMenu(plan),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(PhosphorIconsRegular.dotsThreeVertical, size: 20, color: gc.textTertiary),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _desc,
          style: AppTheme.s(13.5, color: gc.text),
          cursorColor: gc.accent,
          maxLines: null,
          onChanged: (v) => fit.setPlanDescription(_id, v),
          decoration: InputDecoration(
            isCollapsed: true,
            hintText: t.planDescriptionHint,
            hintStyle: AppTheme.s(13.5, color: gc.textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _details(GymColors gc, WorkoutPlan plan) {
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.planDetails, style: AppTheme.d(12, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 3)),
          const SizedBox(height: 10),
          Text(t.planGoalLabel, style: AppTheme.s(11, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in PlanGoal.values) _goalChip(gc, plan, g),
            ],
          ),
          const SizedBox(height: 14),
          Text(t.planDifficultyLabel, style: AppTheme.s(11, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in kPlanDifficulties) _diffChip(gc, plan, d),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goalChip(GymColors gc, WorkoutPlan plan, PlanGoal g) {
    final selected = plan.goal == g;
    return GestureDetector(
      onTap: () => fit.setPlanGoal(plan.id, g),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? gc.ember : gc.bgRaised2,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(t.planGoalName(g.name),
            style: AppTheme.s(12, weight: FontWeight.w600, color: selected ? gc.onEmber : gc.textSecondary)),
      ),
    );
  }

  Widget _diffChip(GymColors gc, WorkoutPlan plan, String d) {
    final selected = plan.difficulty == d;
    return GestureDetector(
      onTap: () => fit.setPlanDifficulty(plan.id, d),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? gc.ember : gc.bgRaised2,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(t.difficulty(d),
            style: AppTheme.s(12, weight: FontWeight.w600, color: selected ? gc.onEmber : gc.textSecondary)),
      ),
    );
  }

  Widget _daysLabel(GymColors gc) {
    return Row(
      children: [
        Text(t.planDaysLabel, style: AppTheme.d(12, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 3)),
        const Spacer(),
        if ((fit.activePlan?.days.length ?? 0) > 1)
          Text(t.planReorderHint, style: AppTheme.s(11, color: gc.textTertiary)),
      ],
    );
  }

  Widget _dayCard(GymColors gc, WorkoutPlan plan, int index) {
    final day = plan.days[index];
    final open = _openDay == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: open ? gc.ember : gc.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final name = await _promptDayName(day.name);
                  if (name != null && name.trim().isNotEmpty) {
                    fit.renamePlanDay(plan.id, index, name);
                  }
                },
                child: SizedBox(
                  width: 30,
                  height: 36,
                  child: Icon(PhosphorIconsRegular.pencilSimple, size: 18, color: gc.textTertiary),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _openDay = open ? null : index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.name, style: AppTheme.s(15, weight: FontWeight.w600, color: gc.text)),
                      const SizedBox(height: 2),
                      Text(t.planExercisesCount(day.exercises.length),
                          style: AppTheme.s(12, color: gc.textSecondary)),
                    ],
                  ),
                ),
              ),
              if (plan.days.length > 1)
                GestureDetector(
                  onTap: () => fit.removePlanDay(plan.id, index),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(PhosphorIconsRegular.trash, size: 18, color: gc.textTertiary),
                  ),
                ),
              GestureDetector(
                onTap: () => setState(() => _openDay = open ? null : index),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(open ? PhosphorIconsRegular.caretUp : PhosphorIconsRegular.caretDown,
                      size: 16, color: gc.textTertiary),
                ),
              ),
            ],
          ),
          if (open) ...[
            const Divider(color: Colors.transparent, height: 16),
            if (day.exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(t.planAddExercises, style: AppTheme.s(12, color: gc.textTertiary)),
              )
            else ...[
              if (day.exercises.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(t.planReorderHint, style: AppTheme.s(11, color: gc.textTertiary)),
                ),
              ReorderableListView(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (from, to) => fit.reorderPlanExercise(plan.id, index, from, to),
                children: [
                  for (int i = 0; i < day.exercises.length; i++)
                    _exerciseRow(gc, plan, index, day.exercises[i], i),
                ],
              ),
            ],
            const SizedBox(height: 8),
            _addToDayBar(gc, plan, index),
          ],
        ],
      ),
    );
  }

  Widget _exerciseRow(GymColors gc, WorkoutPlan plan, int dayIndex, WorkoutPlanExercise pe, int exIndex) {
    return Container(
      key: ValueKey('$dayIndex-${pe.exerciseId}-$exIndex'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        ReorderableDragStartListener(
          index: exIndex,
          child: SizedBox(
            width: 30,
            height: 40,
            child: Icon(PhosphorIconsRegular.dotsSixVertical, size: 16, color: gc.textTertiary),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _showConfigSheet(plan, dayIndex, exIndex),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pe.name, style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                const SizedBox(height: 2),
                Text(_configSummary(pe), style: AppTheme.s(12, color: gc.textSecondary)),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _showConfigSheet(plan, dayIndex, exIndex),
          child: SizedBox(
            width: 38,
            height: 40,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(8)),
                child: Text(t.set, style: AppTheme.s(10, weight: FontWeight.w600, color: gc.ember)),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => fit.removePlanExercise(plan.id, dayIndex, exIndex),
          child: SizedBox(
            width: 38,
            height: 40,
            child: Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: gc.bgRaised, shape: BoxShape.circle),
                child: SvgPathIcon(Ic.close, size: 12, color: gc.textSecondary),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  String _configSummary(WorkoutPlanExercise pe) {
    final parts = [
      '${pe.sets} × ${pe.repRange}',
      if (pe.restSeconds != null) '${pe.restSeconds}s',
      if (pe.warmup) 'warmup',
      if (pe.toFailure) 'AMRAP',
    ];
    return parts.join(' · ');
  }

  Widget _addToDayBar(GymColors gc, WorkoutPlan plan, int dayIndex) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        border: Border.all(color: gc.border),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(children: [
        SvgPathIcon(Ic.search, size: 16, color: gc.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _q = v),
            style: AppTheme.s(13, color: gc.text),
            cursorColor: gc.accent,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: t.addExercises,
              hintStyle: AppTheme.s(13, color: gc.textSecondary),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _searchField(GymColors gc, WorkoutPlan plan) {
    final list = _filtered;
    if (_q.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.results, style: AppTheme.d(12, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 3)),
        const SizedBox(height: 8),
        for (final ex in list.take(12)) _pickRow(gc, plan, ex),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _pickRow(GymColors gc, WorkoutPlan plan, Exercise ex) {
    final inDay = _openDay != null &&
        _openDay! < plan.days.length &&
        plan.days[_openDay!].exercises.any((pe) => pe.exerciseId == ex.id);
    return GestureDetector(
      onTap: () {
        if (_openDay == null) return;
        if (inDay) return;
        fit.addPlanExercise(plan.id, _openDay!, ex.id);
        setState(() {});
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          border: Border.all(color: inDay ? gc.ember : gc.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exerciseName(ex), style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                const SizedBox(height: 2),
                Text('${muscleLabel(ex.primary)} · ${t.equipment(ex.equipment)}',
                    style: AppTheme.s(12, color: gc.textSecondary)),
              ],
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: inDay ? gc.ember : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: inDay ? gc.ember : gc.border, width: 2),
            ),
            child: inDay
                ? SvgPathIcon(Ic.checkBold, size: 14, color: gc.onEmber)
                : Icon(PhosphorIconsRegular.plus, size: 15, color: gc.textSecondary),
          ),
        ]),
      ),
    );
  }

  void _showConfigSheet(WorkoutPlan plan, int dayIndex, int exIndex) {
    final pe = plan.days[dayIndex].exercises[exIndex];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.gc.bgRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ExerciseConfigSheet(plan: plan, dayIndex: dayIndex, exIndex: exIndex, exercise: pe),
    );
  }

  Future<String?> _promptDayName(String current) {
    final controller = TextEditingController(text: current);
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.gc.bgRaised,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final gc = ctx.gc;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.dayNamePrompt, style: AppTheme.s(15, weight: FontWeight.w600, color: gc.text)),
              const SizedBox(height: 14),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: gc.bgRaised2,
                  border: Border.all(color: gc.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: AppTheme.s(15, color: gc.text),
                  cursorColor: gc.accent,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (v) => Navigator.pop(ctx, v),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: t.dayNameHint,
                    hintStyle: AppTheme.s(13, color: gc.textTertiary),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: t.save,
                onTap: () => Navigator.pop(ctx, controller.text),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlanMenu(WorkoutPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.gc.bgRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _menuItem(context, t.duplicatePlan, PhosphorIconsRegular.copy, () {
                Navigator.pop(context);
                final copy = fit.duplicatePlan(plan.id);
                fit.openPlan(copy.id);
              }),
              _menuItem(context, t.shareCode, PhosphorIconsRegular.export,
                  () { Navigator.pop(context); _showShareCode(plan); }),
              _menuItem(context, t.archivePlan, PhosphorIconsRegular.archive, () {
                Navigator.pop(context);
                fit.archivePlan(plan.id);
                fit.closePlanEdit();
              }),
              _menuItem(context, t.deletePlan, PhosphorIconsRegular.trash, () {
                Navigator.pop(context);
                _confirmDelete(plan);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final gc = context.gc;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, size: 18, color: gc.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
        ]),
      ),
    );
  }

  void _showShareCode(WorkoutPlan plan) {
    final code = fit.planImportCode(plan.id);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.gc.bgRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.shareCode, style: AppTheme.d(13, weight: FontWeight.w600, color: context.gc.brass, letterSpacing: 3)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: BoxDecoration(
                  color: context.gc.bgRaised2,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: SelectableText(code,
                    style: AppTheme.d(30, weight: FontWeight.w700, color: context.gc.text, letterSpacing: 3)),
              ),
              const SizedBox(height: 6),
              Text(t.importCodeHint,
                  textAlign: TextAlign.center, style: AppTheme.s(12, color: context.gc.textTertiary)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: context.gc.ember, borderRadius: BorderRadius.circular(100)),
                  child: Text(t.done,
                      style: AppTheme.d(13, weight: FontWeight.w600, color: context.gc.onEmber, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(WorkoutPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.gc.bgRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.confirmDeletePlan, style: AppTheme.s(15, weight: FontWeight.w600, color: context.gc.text)),
              const SizedBox(height: 18),
              PrimaryButton(
                label: t.deleteCaps,
                bg: context.gc.accent,
                onTap: () {
                  Navigator.pop(context);
                  fit.deletePlan(plan.id);
                  fit.closePlanEdit();
                },
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  child: Text(t.cancelCaps,
                      style: AppTheme.d(14, weight: FontWeight.w600, color: context.gc.textSecondary, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseConfigSheet extends StatefulWidget {
  const _ExerciseConfigSheet({
    required this.plan,
    required this.dayIndex,
    required this.exIndex,
    required this.exercise,
  });

  final WorkoutPlan plan;
  final int dayIndex;
  final int exIndex;
  final WorkoutPlanExercise exercise;

  @override
  State<_ExerciseConfigSheet> createState() => _ExerciseConfigSheetState();
}

class _ExerciseConfigSheetState extends State<_ExerciseConfigSheet> {
  late int _sets = widget.exercise.sets;
  late int _reps = widget.exercise.reps;
  late int _rest = widget.exercise.restSeconds ?? 90;
  late bool _warmup = widget.exercise.warmup;
  late bool _failure = widget.exercise.toFailure;

  void _save() {
    fit.updatePlanExercise(
      widget.plan.id,
      widget.dayIndex,
      widget.exIndex,
      (e) => e.copyWith(sets: _sets, reps: _reps, restSeconds: _rest, warmup: _warmup, toFailure: _failure),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.exercise.name, style: AppTheme.s(17, weight: FontWeight.w600, color: gc.text)),
            const SizedBox(height: 6),
            Text(t.planConfigTitle, style: AppTheme.d(12, weight: FontWeight.w600, color: gc.brass, letterSpacing: 3)),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.planConfigSets, style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                StepperControl(
                  value: '$_sets',
                  onDec: () => setState(() => _sets = (_sets - 1).clamp(1, 12)),
                  onInc: () => setState(() => _sets = (_sets + 1).clamp(1, 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.planConfigReps, style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                StepperControl(
                  value: '$_reps',
                  onDec: () => setState(() => _reps = (_reps - 1).clamp(1, 30)),
                  onInc: () => setState(() => _reps = (_reps + 1).clamp(1, 30)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.planConfigRest, style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                StepperControl(
                  value: '$_rest',
                  btnSize: 26,
                  onDec: () => setState(() => _rest = (_rest - 15).clamp(15, 600)),
                  onInc: () => setState(() => _rest = (_rest + 15).clamp(15, 600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.planConfigWarmup, style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                Switch(
                  value: _warmup,
                  activeTrackColor: gc.ember,
                  onChanged: (v) => setState(() => _warmup = v),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.planConfigFailure, style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                Switch(
                  value: _failure,
                  activeTrackColor: gc.ember,
                  onChanged: (v) => setState(() => _failure = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: t.save, onTap: _save),
          ],
        ),
      ),
    );
  }
}
