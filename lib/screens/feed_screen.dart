import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/l10n.dart';
import '../models/post.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/svg_icon.dart';
import '../widgets/ui_kit.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  void _post() {
    if (_composer.text.trim().isEmpty) return;
    fit.addPost(_composer.text);
    setState(() => _composer.clear());
    FocusScope.of(context).unfocus();
  }

  Future<void> _share(Post p) async {
    try {
      await SharePlus.instance
          .share(ShareParams(text: '${p.author}: ${p.text}'));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final items = fit.feedWithSessionActivity();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _header(gc),
          const SizedBox(height: 16),
          _composerCard(gc),
          const SizedBox(height: 22),
          if (items.isEmpty)
            Text(t.feedEmpty,
                style: AppTheme.s(13, color: gc.textSecondary))
          else
            for (int i = 0; i < items.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i < items.length - 1 ? 12 : 0),
                child: _postCard(gc, items[i]),
              ),
        ],
      ),
    );
  }

  Widget _header(GymColors gc) {
    return Row(children: [
      RoundBtn(icon: Ic.chevronLeft, onTap: fit.popRoute),
      const SizedBox(width: 12),
      ScreenTitle(t.feedTitle),
    ]);
  }

  Widget _composerCard(GymColors gc) {
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _composer,
            minLines: 1,
            maxLines: 3,
            autofocus: false,
            onSubmitted: (_) => _post(),
            decoration: InputDecoration(
              hintText: t.feedComposeHint,
              filled: true,
              fillColor: gc.bgRaised,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _post,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: gc.emberSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPathIcon(Ic.barbell, size: 16, color: gc.ember),
                    const SizedBox(width: 6),
                    Text(t.feedPost,
                        style: AppTheme.d(12, weight: FontWeight.w800, color: gc.ember, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard(GymColors gc, Post p) {
    final isMine = p.author == fit.profile.name;
    final initial = (p.author.isEmpty ? '?' : p.author[0]).toUpperCase();
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Row(children: [
                      Flexible(
                        child: Text(p.author,
                            style: AppTheme.s(14, weight: FontWeight.w700, color: gc.text)),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 6),
                        Text(t.feedYou,
                            style: AppTheme.s(11, weight: FontWeight.w700, color: gc.textTertiary)),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    if (p.code.isNotEmpty)
                      Text('#${p.code}',
                          style: AppTheme.s(11, color: gc.textTertiary)),
                  ],
                ),
              ),
              Text(t.shortDateYear(p.createdAt),
                  style: AppTheme.s(11, color: gc.textTertiary)),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 10),
            child: Text(p.text,
                style: AppTheme.s(14, weight: FontWeight.w400, color: gc.text, height: 1.4)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (p.id.isEmpty) return;
                  setState(() => fit.toggleLike(p.id));
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(
                        p.liked ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
                        size: 17,
                        color: p.liked ? gc.ember : gc.textTertiary,
                      ),
                      const SizedBox(width: 5),
                      Text(p.likes > 0 ? '${p.likes}' : '',
                          style: AppTheme.s(12, weight: FontWeight.w600, color: gc.textSecondary)),
                    ],
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _share(p),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(PhosphorIconsRegular.shareNetwork,
                      size: 17, color: gc.textTertiary),
                ),
              ),
              const Spacer(),
              if (isMine)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (p.id.isEmpty) return;
                    setState(() => fit.removePost(p.id));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(PhosphorIconsRegular.trashSimple, size: 17, color: gc.textTertiary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}