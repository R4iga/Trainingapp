import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../models/generator.dart';
import '../models/workout_plan.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/body_map.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';

class PlanGeneratorScreen extends StatefulWidget {
  const PlanGeneratorScreen({super.key});

  @override
  State<PlanGeneratorScreen> createState() => _PlanGeneratorScreenState();
}

class _PlanGeneratorScreenState extends State<PlanGeneratorScreen> {
  int? _openDay;
  bool _busy = false;
  int _stage = 0;
  Timer? _stageTimer;

  static const List<int> _lengths = [20, 30, 45, 60, 75, 90];

  @override
  void dispose() {
    _stageTimer?.cancel();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: AppTheme.s(13, color: context.gc.text)),
        backgroundColor: context.gc.bgRaised,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _runBusy(VoidCallback gen, {bool week = false}) async {
    _stageTimer?.cancel();
    setState(() {
      _busy = true;
      _stage = 0;
    });
    _stageTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (mounted) setState(() => _stage = (_stage + 1) % 4);
    });
    await Future<void>.delayed(
        week ? const Duration(milliseconds: 1400) : const Duration(milliseconds: 1000));
    _stageTimer?.cancel();
    gen();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _generateDay(int w) async {
    final muscles = fit.genMuscles[w] ?? const [];
    if (muscles.isEmpty) {
      _toast(t.genAddMusclesFirst);
      return;
    }
    setState(() => _openDay = w);
    await _runBusy(() => fit.generateGenDay(w));
    final day = fit.genDraftDay(w);
    if (day != null && day.exercises.isEmpty) _toast(t.genLoadError);
  }

  Future<void> _generateAll() async {
    if (fit.genMuscles.isEmpty) {
      _toast(t.genAddMusclesFirst);
      return;
    }
    await _runBusy(fit.generateGenWeek, week: true);
    final has = fit.genDraft?.days.any((d) => d.exercises.isNotEmpty) ?? false;
    if (!has) _toast(t.genLoadError);
  }

  bool get _hasGenerated => fit.genDraft?.days.any((d) => d.exercises.isNotEmpty) ?? false;

  void _save() {
    final id = fit.saveGenAsPlan();
    if (id.isEmpty) {
      _toast(t.genAddMusclesFirst);
      return;
    }
    fit.openPlan(id);
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ScreenHeader(title: t.genTitle, onBack: fit.backFromGenerator, titleSize: 22),
          ),
          Expanded(
            child: Stack(
              children: [
                IgnorePointer(
                  ignoring: _busy,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 150),
                    children: [
                      _prefsCard(gc),
                      const SizedBox(height: 20),
                      _presetSection(gc),
                      const SizedBox(height: 24),
                      _weekHeader(gc),
                      const SizedBox(height: 12),
                      for (final w in kWeekdays) _dayCard(gc, w),
                    ],
                  ),
                ),
                if (_busy) _generatingOverlay(gc),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: PrimaryButton(
              label: t.genSavePlan,
              icon: Ic.layers,
              onTap: _hasGenerated ? _save : () => _toast(t.genAddMusclesFirst),
            ),
          ),
        ],
      ),
    );
  }

  Widget _generatingOverlay(GymColors gc) {
    final stages = [t.genMsgBuilding, t.genMsgBalancing, t.genMsgSelecting, t.genMsgFinalizing];
    return Positioned.fill(
      child: Container(
        color: gc.pageBg.withValues(alpha: 0.7),
        child: Center(
          child: SoftCard(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: gc.ember),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 220,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      stages[_stage],
                      key: ValueKey(_stage),
                      textAlign: TextAlign.center,
                      style: AppTheme.s(13.5, weight: FontWeight.w600, color: gc.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Preferences ----------------------------------------------------------

  Widget _prefsCard(GymColors gc) {
    final prefs = fit.genPrefs;
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(gc, t.genGoal),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in PlanGoal.values)
                _chip(gc, t.planGoalName(g.name), prefs.goal == g,
                    () => fit.setGenPrefs(prefs.copyWith(goal: g))),
            ],
          ),
          const SizedBox(height: 14),
          _label(gc, t.genExperience),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in kPlanDifficulties)
                _chip(gc, t.difficulty(d), prefs.difficulty == d,
                    () => fit.setGenPrefs(prefs.copyWith(difficulty: d))),
            ],
          ),
          const SizedBox(height: 14),
          _label(gc, t.genLength),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _lengths)
                _chip(gc, t.genMinutes(m), prefs.durationMinutes == m,
                    () => fit.setGenPrefs(prefs.copyWith(durationMinutes: m))),
            ],
          ),
          const SizedBox(height: 14),
          _label(gc, t.genEquipment),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(gc, t.genEquipFullGym, prefs.equipment == GenEquipment.fullGym,
                  () => fit.setGenPrefs(prefs.copyWith(equipment: GenEquipment.fullGym))),
              _chip(gc, t.genEquipBasic, prefs.equipment == GenEquipment.basic,
                  () => fit.setGenPrefs(prefs.copyWith(equipment: GenEquipment.basic))),
              _chip(gc, t.genEquipHome, prefs.equipment == GenEquipment.home,
                  () => fit.setGenPrefs(prefs.copyWith(equipment: GenEquipment.home))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetSection(GymColors gc) {
    const presets = [
      (GenStyle.ppl, 'genStylePpl'),
      (GenStyle.upperLower, 'genStyleUpperLower'),
      (GenStyle.fullBody, 'genStyleFullBody'),
      (GenStyle.bro, 'genStyleBro'),
      (GenStyle.arnold, 'genStyleArnold'),
      (GenStyle.custom, 'genStyleCustom'),
    ];
    String label(GenStyle s) => switch (s) {
          GenStyle.ppl => t.genStylePpl,
          GenStyle.upperLower => t.genStyleUpperLower,
          GenStyle.fullBody => t.genStyleFullBody,
          GenStyle.bro => t.genStyleBro,
          GenStyle.arnold => t.genStyleArnold,
          GenStyle.custom => t.genStyleCustom,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(gc, t.genPreset),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (style, _) in presets)
              _chip(gc, label(style), fit.genPrefs.style == style,
                  () => fit.applyGenPreset(style)),
          ],
        ),
      ],
    );
  }

  Widget _label(GymColors gc, String text) =>
      Text(text, style: AppTheme.d(12, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 3));

  Widget _chip(GymColors gc, String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? gc.ember : gc.bgRaised2,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? gc.ember : gc.border),
        ),
        child: Text(text,
            style: AppTheme.s(12.5, weight: FontWeight.w600,
                color: selected ? gc.onEmber : gc.textSecondary)),
      ),
    );
  }

  // ---- Week ---------------------------------------------------------------

  Widget _weekHeader(GymColors gc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(t.genWeek,
                style: AppTheme.d(16, weight: FontWeight.w700, color: gc.text, letterSpacing: 2)),
            const Spacer(),
            Expanded(
              flex: 2,
              child: Text(t.genWeekHint,
                  textAlign: TextAlign.right,
                  style: AppTheme.s(11.5, color: gc.textTertiary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                label: t.genClearWeek,
                icon: PhosphorIconsRegular.trash,
                onTap: () {
                  fit.clearGenMuscles();
                  if (mounted) setState(() => _openDay = null);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: _generateAllLabel,
                height: 46,
                onTap: _generateAll,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String get _generateAllLabel =>
      fit.genDraft?.days.any((d) => d.exercises.isNotEmpty) ?? false
          ? t.genRegenerateWeek
          : t.genGenerateWeek;

  String _muscleSummary(GymColors gc, List<String> muscles) {
    if (muscles.isEmpty) return t.genNoMuscles;
    return muscles.map(muscleLabel).join(' · ');
  }

  Widget _dayCard(GymColors gc, int w) {
    final rest = fit.genRestDays.contains(w);
    final muscles = List<String>.from(fit.genMuscles[w] ?? const []);
    final open = _openDay == w;
    final day = fit.genDraftDay(w);
    final exercises = day?.exercises ?? const <WorkoutPlanExercise>[];

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
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _openDay = open ? null : w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.weekday(w),
                              style: AppTheme.s(15, weight: FontWeight.w700, color: gc.text)),
                          const SizedBox(height: 2),
                          Text(
                            rest ? t.genRest : _muscleSummary(gc, muscles),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.s(12, color: gc.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => fit.toggleGenRest(w),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: rest ? gc.ember : gc.bgRaised2,
                    shape: BoxShape.circle,
                    border: Border.all(color: rest ? gc.ember : gc.border),
                  ),
                  child: Icon(
                    rest ? PhosphorIconsFill.moon : PhosphorIconsRegular.moon,
                    size: 17,
                    color: rest ? gc.onEmber : gc.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _openDay = open ? null : w),
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
            if (rest)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(t.genRestHint, style: AppTheme.s(12.5, color: gc.textSecondary)),
              )
            else ...[
              Row(
                children: [
                  Text(t.genMusclesLabel,
                      style: AppTheme.d(11, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 2)),
                  const Spacer(),
                  Text(t.genTapMuscles, style: AppTheme.s(10.5, color: gc.textTertiary)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: BodyMap(selected: muscles.toSet(), onToggle: (m) => fit.toggleGenMuscle(w, m))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in kMuscles)
                    _muscleChip(gc, m, fit.genDayHas(w, m.id),
                        () => fit.toggleGenMuscle(w, m.id)),
                ],
              ),
              const SizedBox(height: 14),
              if (exercises.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(t.genNoMuscles, style: AppTheme.s(12.5, color: gc.textTertiary)),
                )
              else ...[
                Text(t.planExercisesCount(exercises.length),
                    style: AppTheme.s(11.5, weight: FontWeight.w600, color: gc.textSecondary)),
                const SizedBox(height: 8),
                if (exercises.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(t.planReorderHint, style: AppTheme.s(10.5, color: gc.textTertiary)),
                  ),
                ReorderableListView(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorder: (from, to) => fit.reorderGenExercise(w, from, to),
                  children: [
                    for (int i = 0; i < exercises.length; i++)
                      _genExerciseRow(gc, w, exercises[i], i),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _generateDay(w),
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: gc.ember,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIconsRegular.arrowsClockwise, size: 15, color: gc.onEmber),
                            const SizedBox(width: 7),
                            Text(
                              exercises.isNotEmpty ? t.genRegenerateDay : t.genGenerateDay,
                              style: AppTheme.d(12, weight: FontWeight.w600, color: gc.onEmber, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => fit.clearGenDay(w),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: gc.border),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(t.genClearDay,
                          style: AppTheme.s(12, weight: FontWeight.w600, color: gc.textSecondary)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _muscleChip(GymColors gc, Muscle m, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? gc.ember : gc.bgRaised2,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? gc.ember : gc.border),
        ),
        child: Text(muscleLabel(m.id),
            style: AppTheme.s(11, weight: FontWeight.w600, color: selected ? gc.onEmber : gc.textSecondary)),
      ),
    );
  }

  Widget _genExerciseRow(GymColors gc, int w, WorkoutPlanExercise pe, int index) {
    final ex = fit.exerciseById(pe.exerciseId);
    final label = ex != null ? exerciseName(ex) : pe.name;
    return Container(
      key: ValueKey('$w-${pe.exerciseId}-$index'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        ReorderableDragStartListener(
          index: index,
          child: SizedBox(
            width: 30,
            height: 40,
            child: Icon(PhosphorIconsRegular.dotsSixVertical, size: 16, color: gc.textTertiary),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _showConfigSheet(w, index, pe),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                const SizedBox(height: 2),
                Text(_genConfigSummary(pe), style: AppTheme.s(12, color: gc.textSecondary)),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => fit.replaceGenExercise(w, index),
          child: SizedBox(
            width: 36,
            height: 40,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: gc.bgRaised, shape: BoxShape.circle),
                child: Icon(PhosphorIconsRegular.arrowsClockwise, size: 14, color: gc.ember),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _showConfigSheet(w, index, pe),
          child: SizedBox(
            width: 36,
            height: 40,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: gc.bgRaised, shape: BoxShape.circle),
                child: Icon(PhosphorIconsRegular.pencilSimple, size: 14, color: gc.textSecondary),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => fit.removeGenExercise(w, index),
          child: SizedBox(
            width: 36,
            height: 40,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: gc.bgRaised, shape: BoxShape.circle),
                child: SvgPathIcon(Ic.close, size: 12, color: gc.textSecondary),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  String _genConfigSummary(WorkoutPlanExercise pe) {
    final parts = [
      '${pe.sets} × ${pe.repRange}',
      if (pe.restSeconds != null) '${pe.restSeconds}s',
      if (pe.warmup) 'warmup',
    ];
    return parts.join(' · ');
  }

  void _showConfigSheet(int w, int index, WorkoutPlanExercise pe) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.gc.bgRaised,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GenConfigSheet(dayIndex: w, exIndex: index, exercise: pe),
    );
  }
}

class _GenConfigSheet extends StatefulWidget {
  const _GenConfigSheet({required this.dayIndex, required this.exIndex, required this.exercise});

  final int dayIndex;
  final int exIndex;
  final WorkoutPlanExercise exercise;

  @override
  State<_GenConfigSheet> createState() => _GenConfigSheetState();
}

class _GenConfigSheetState extends State<_GenConfigSheet> {
  late int _sets = widget.exercise.sets;
  late int _reps = widget.exercise.reps;
  late bool _hasMax = widget.exercise.repsMax != null;
  late int _repsMax = widget.exercise.repsMax ?? widget.exercise.reps;
  late int _rest = widget.exercise.restSeconds ?? 90;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 12),
            Text(widget.exercise.name, style: AppTheme.s(16, weight: FontWeight.w700, color: gc.text)),
            const SizedBox(height: 14),
            ToolRow(
              label: t.planConfigSets,
              control: StepperControl(
                value: '$_sets',
                onDec: () => setState(() => _sets = (_sets - 1).clamp(1, 10)),
                onInc: () => setState(() => _sets = (_sets + 1).clamp(1, 10)),
              ),
            ),
            const SizedBox(height: 8),
            ToolRow(
              label: t.planConfigReps,
              control: StepperControl(
                value: '$_reps',
                onDec: () => setState(() => _reps = (_reps - 1).clamp(1, 40)),
                onInc: () => setState(() => _reps = (_reps + 1).clamp(1, 40)),
              ),
            ),
            const SizedBox(height: 8),
            ToolRow(
              label: t.genMax,
              control: StepperControl(
                value: _hasMax ? '$_repsMax' : '–',
                onDec: () => setState(() => _repsMax = (_repsMax - 1).clamp(1, 40)),
                onInc: () => setState(() {
                  _hasMax = true;
                  _repsMax = (_repsMax + 1).clamp(1, 40);
                }),
              ),
            ),
            const SizedBox(height: 8),
            ToolRow(
              label: t.planConfigRest,
              control: StepperControl(
                value: '$_rest',
                onDec: () => setState(() => _rest = (_rest - 15).clamp(0, 600)),
                onInc: () => setState(() => _rest = (_rest + 15).clamp(0, 600)),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: t.done,
              onTap: () {
                fit.updateGenExercise(widget.dayIndex, widget.exIndex, (pe) => pe.copyWith(
                      sets: _sets,
                      reps: _reps,
                      repsMax: _hasMax ? _repsMax : null,
                      restSeconds: _rest,
                    ));
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}