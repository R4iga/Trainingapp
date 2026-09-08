import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../l10n/l10n.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final workouts = fit.sessions.length;
    final streak = fit.currentStreak;
    final split = fit.muscleSplit;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _header(gc),
          const SizedBox(height: 18),
          _identity(gc),
          const SizedBox(height: 18),
          _statsBar(gc, workouts, streak),
          const SizedBox(height: 24),
          _sectionLabel(gc, t.muscleSplit),
          const SizedBox(height: 10),
          _muscleBalance(gc, split),
          const SizedBox(height: 24),
          _sectionLabel(gc, t.profileTopLifts),
          const SizedBox(height: 10),
          _topLifts(gc),
          const SizedBox(height: 24),
          _shortcuts(gc),
        ],
      ),
    );
  }

  Widget _header(GymColors gc) {
    return Row(children: [
      RoundBtn(icon: Ic.chevronLeft, onTap: fit.popRoute),
      const SizedBox(width: 12),
      Expanded(child: ScreenTitle(t.profileTitle)),
      RoundBtn(icon: Ic.gear, onTap: fit.goSettings),
    ]);
  }

  Widget _identity(GymColors gc) {
    final name = fit.profile.name;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final photo = fit.profilePhoto;
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: photo == null ? gc.accent : null,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: photo == null
                ? Center(
                    child: Text(initial,
                        style: AppTheme.d(26, weight: FontWeight.w700, color: gc.text)))
                : Image.memory(photo, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTheme.d(20, weight: FontWeight.w700, color: gc.text)),
                const SizedBox(height: 3),
                Text('${fit.sessions.length} ${t.profileWorkouts}',
                    style: AppTheme.s(13, color: gc.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsBar(GymColors gc, int workouts, int streak) {
    return SoftCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(gc, '$workouts', t.profileWorkouts),
          Container(width: 1, height: 24, color: gc.border),
          _stat(gc, '$streak', t.streakCaps),
          Container(width: 1, height: 24, color: gc.border),
          _stat(gc, fit.volumeLabel(fit.totalVolumeKg), t.volume),
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

  Widget _muscleBalance(GymColors gc, List<({String name, int pct})> split) {
    final top = split.take(5).toList();
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: top.isEmpty
          ? Text(t.muscleMapEmpty,
              style: AppTheme.s(13, color: gc.textSecondary))
          : Column(
              children: [
                for (int i = 0; i < top.length; i++) _muscleRow(gc, top[i], i < top.length - 1),
              ],
            ),
    );
  }

  Widget _muscleRow(GymColors gc, ({String name, int pct}) m, bool border) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: border ? Border(bottom: BorderSide(color: gc.border)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(m.name,
                style: AppTheme.s(13, weight: FontWeight.w600, color: gc.text)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 8,
                color: gc.bgRaised,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (m.pct / 100).clamp(0.02, 1.0),
                  child: Container(color: gc.accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 38,
            child: Text('${m.pct}%',
                textAlign: TextAlign.right,
                style: AppTheme.s(12, weight: FontWeight.w700, color: gc.ember)),
          ),
        ],
      ),
    );
  }

  Widget _topLifts(GymColors gc) {
    final prs = fit.personalRecords.take(3).toList();
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        children: [
          if (prs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(t.prEmpty,
                  style: AppTheme.s(13, color: gc.textSecondary)),
            )
          else
            for (int i = 0; i < prs.length; i++) _prRow(gc, prs[i], i < prs.length - 1),
          const SizedBox(height: 4),
          InkWell(
            onTap: fit.goProgress,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t.profileViewAll,
                      style: AppTheme.d(11, weight: FontWeight.w700, color: gc.ember, letterSpacing: 2)),
                  const SizedBox(width: 6),
                  Icon(PhosphorIconsRegular.arrowRight,
                      size: 13, color: gc.ember),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _prRow(GymColors gc, ({String id, String name, double topWeight, double oneRm}) pr, bool border) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: border ? Border(bottom: BorderSide(color: gc.border)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(t.catalogName(pr.id, pr.name),
                  style: AppTheme.s(14, weight: FontWeight.w500, color: gc.text))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fit.weightLabel(pr.topWeight),
                  style: AppTheme.d(18, weight: FontWeight.w700, color: gc.text)),
              Text(t.oneRmEst(fit.weightLabel(pr.oneRm)),
                  style: AppTheme.s(11, color: gc.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shortcuts(GymColors gc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _shortcut(gc, Ic.star, t.friendsTitle, fit.goFriends),
        const SizedBox(height: 10),
        _shortcut(gc, Ic.trendUp, t.progress, fit.goProgress),
        const SizedBox(height: 10),
        _shortcut(gc, Ic.clock, t.timeline, () => fit.pushRoute('timeline')),
        const SizedBox(height: 10),
        _shortcut(gc, Ic.bars, t.volume, () => fit.pushRoute('measures')),
      ],
    );
  }

  Widget _shortcut(GymColors gc, List<IconPath> icon, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gc.border),
        ),
        child: Row(
          children: [
            SvgPathIcon(icon, size: 20, color: gc.ember),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text))),
            SvgPathIcon(Ic.chevronRight, size: 18, color: gc.textTertiary),
          ],
        ),
      ),
    );
  }
}