import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/l10n.dart';
import '../models/friend.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  String _inviteText() => fit.inviteShareText();

  Future<void> _shareInvite() async {
    try {
      await SharePlus.instance.share(ShareParams(text: _inviteText()));
    } catch (_) {}
  }

  Future<void> _addFriend() async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddFriendSheet(),
    );
    if (result == null || !mounted) return;
    final (name, code) = result;
    final status = fit.addFriend(name, code);
    if (!mounted) return;
    final message = switch (status) {
      1 => t.friendsMissingCode,
      2 => t.friendsSelfToast,
      3 => t.friendsDuplicateToast,
      _ => t.friendsAddedToast,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _header(gc),
          const SizedBox(height: 18),
          _inviteCard(gc),
          const SizedBox(height: 24),
          _sectionLabel(gc, t.friendsList),
          const SizedBox(height: 10),
          if (fit.friends.isEmpty)
            Text(t.friendsEmpty,
                style: AppTheme.s(13, color: gc.textSecondary))
          else
            _friendList(gc),
        ],
      ),
    );
  }

  Widget _header(GymColors gc) {
    return Row(children: [
      RoundBtn(icon: Ic.chevronLeft, onTap: fit.popRoute),
      const SizedBox(width: 12),
      Expanded(child: ScreenTitle(t.friendsTitle)),
      RoundBtn(
        icon: Ic.plus,
        onTap: _addFriend,
      ),
    ]);
  }

  Widget _inviteCard(GymColors gc) {
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.friendsInviteLabel,
                    style: AppTheme.d(11, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 2)),
                const SizedBox(height: 6),
                Text(fit.myInviteCode,
                    style: AppTheme.d(30, weight: FontWeight.w800, color: gc.ember, letterSpacing: 6)),
                const SizedBox(height: 6),
                Text(t.friendsInviteHint,
                    style: AppTheme.s(12, color: gc.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _shareInvite,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: gc.emberSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  SvgPathIcon(Ic.barbell, size: 20, color: gc.ember),
                  const SizedBox(height: 4),
                  Text(t.share,
                      style: AppTheme.d(11, weight: FontWeight.w700, color: gc.ember, letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(GymColors gc, String text) {
    return Text(text,
        style: AppTheme.d(12, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 3));
  }

  Widget _friendList(GymColors gc) {
    final list = fit.friends;
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        children: [
          for (int i = 0; i < list.length; i++) _friendRow(gc, list[i], i < list.length - 1),
        ],
      ),
    );
  }

  Widget _friendRow(GymColors gc, Friend f, bool border) {
    final initial = f.name.isEmpty ? '?' : f.name[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: border ? Border(bottom: BorderSide(color: gc.border)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: gc.emberSoft, shape: BoxShape.circle),
            child: Center(
              child: Text(initial,
                  style: AppTheme.d(15, weight: FontWeight.w700, color: gc.ember)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name,
                    style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text)),
                const SizedBox(height: 2),
                Text('#${f.code}',
                    style: AppTheme.s(12, color: gc.textSecondary)),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              fit.removeFriend(f.id);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${f.name} · ${t.delete}'), behavior: SnackBarBehavior.floating));
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(PhosphorIconsRegular.trashSimple,
                  size: 16, color: gc.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFriendSheet extends StatefulWidget {
  const _AddFriendSheet();

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final _name = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop((_name.text.trim(), _code.text.trim().toUpperCase()));
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: gc.bg,
          border: Border.all(color: gc.border),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHandle(color: gc.border, margin: const EdgeInsets.only(bottom: 16)),
            Text(t.friendsAddTitle,
                style: AppTheme.d(18, weight: FontWeight.w700, color: gc.text)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: t.friendsNameHint,
                filled: true,
                fillColor: gc.bgRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _code,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: t.friendsCodeHint,
                filled: true,
                fillColor: gc.bgRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: t.friendsAddCta,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}