import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/group.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  Future<void> _newGroup(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewGroupSheet(),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.groupsCreatedToast), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _header(gc, context),
          const SizedBox(height: 18),
          if (fit.groups.isEmpty)
            Text(t.groupsEmpty,
                style: AppTheme.s(13, color: gc.textSecondary))
          else
            for (int i = 0; i < fit.groups.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i < fit.groups.length - 1 ? 12 : 0),
                child: _groupCard(gc, fit.groups[i], context),
              ),
        ],
      ),
    );
  }

  Widget _header(GymColors gc, BuildContext context) {
    return Row(children: [
      RoundBtn(icon: Ic.chevronLeft, onTap: fit.popRoute),
      const SizedBox(width: 12),
      Expanded(child: ScreenTitle(t.groupsTitle)),
      RoundBtn(icon: Ic.plus, onTap: () => _newGroup(context)),
    ]);
  }

  Widget _groupCard(GymColors gc, Group g, BuildContext context) {
    final initials = <String>[];
    for (final m in g.members) {
      if (m.isNotEmpty) initials.add(m[0].toUpperCase());
    }
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: gc.emberSoft, borderRadius: BorderRadius.circular(14)),
            child: Center(
              child: Text(g.name.isEmpty ? ':' : g.name[0].toUpperCase(),
                  style: AppTheme.d(20, weight: FontWeight.w800, color: gc.ember)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.name,
                    style: AppTheme.s(15, weight: FontWeight.w700, color: gc.text)),
                const SizedBox(height: 3),
                Text('${g.members.length} ${t.groupsMembersLabel}',
                    style: AppTheme.s(12, color: gc.textSecondary)),
              ],
            ),
          ),
          if (initials.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SizedBox(
                height: 30,
                width: 26 + 14 * (initials.length - 1).clamp(0, 3).toDouble(),
                child: Stack(
                  children: [
                    for (int i = 0; i < initials.length && i < 4; i++)
                      Positioned(
                        left: i * 14,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: gc.bgRaised,
                            shape: BoxShape.circle,
                            border: Border.all(color: gc.border),
                          ),
                          child: Center(
                            child: Text(initials[i],
                                style: AppTheme.s(10, weight: FontWeight.w700, color: gc.ember)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          IconButton(
            onPressed: () {
              fit.removeGroup(g.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${g.name} · ${t.delete}'),
                  behavior: SnackBarBehavior.floating));
            },
            icon: Icon(Icons.more_vert_rounded, size: 18, color: gc.textTertiary),
            tooltip: t.delete,
          ),
        ],
      ),
    );
  }
}

class _NewGroupSheet extends StatefulWidget {
  const _NewGroupSheet();

  @override
  State<_NewGroupSheet> createState() => _NewGroupSheetState();
}

class _NewGroupSheetState extends State<_NewGroupSheet> {
  final _name = TextEditingController();
  final Set<String> _members = {};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    fit.createGroup(_name.text, _members.toList());
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final friends = fit.friends;
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHandle(color: gc.border, margin: const EdgeInsets.only(bottom: 16)),
              Text(t.groupsNewTitle,
                  style: AppTheme.d(18, weight: FontWeight.w700, color: gc.text)),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                autocorrect: false,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: t.groupsNameHint,
                  filled: true,
                  fillColor: gc.bgRaised,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(t.groupsRoster,
                  style: AppTheme.s(13, weight: FontWeight.w600, color: gc.textSecondary)),
              const SizedBox(height: 8),
              if (friends.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(t.groupsNoFriendsHint,
                      style: AppTheme.s(12, color: gc.textTertiary)),
                )
              else
                for (final f in friends)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() {
                      if (!_members.add(f.name)) _members.remove(f.name);
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            _members.contains(f.name)
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 20,
                            color: _members.contains(f.name) ? gc.ember : gc.textTertiary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text('#${f.code} · ${f.name}',
                                  style: AppTheme.s(13, weight: FontWeight.w500, color: gc.text))),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: t.groupsCreate,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}