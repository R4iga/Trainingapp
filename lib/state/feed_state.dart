part of 'fit_state.dart';

int _postSeq = 0;

mixin FeedState on FitCore, SocialState {
  void goFeed() => pushRoute('feed');

  void backFromFeed() => popRoute();

  /// Adds a post authored by the current user.
  Post addPost(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return _dummyPost();
    final friendly = trimmed.length > 420 ? '${trimmed.substring(0, 420)}…' : trimmed;
    final p = Post(
      id: 'p-${_postSeq++}-${DateTime.now().microsecondsSinceEpoch}',
      author: profile.name,
      code: myInviteCode,
      text: friendly,
      createdAt: DateTime.now(),
    );
    posts.insert(0, p);
    _persist();
    notifyListeners();
    return p;
  }

  Post _dummyPost() => Post(
        id: '',
        author: '',
        code: '',
        text: '',
        createdAt: DateTime.now(),
      );

  /// Allows a friend (locally represented by a Post with their code) to post.
  /// Used later by Firebase sync; for now friends post through invited names.
  void toggleLike(String id) {
    final p = posts.where((x) => x.id == id).firstOrNull;
    if (p == null) return;
    p.liked = !p.liked;
    p.likes += p.liked ? 1 : -1;
    if (p.likes < 0) p.likes = 0;
    _persist();
    notifyListeners();
  }

  void removePost(String id) {
    posts.removeWhere((p) => p.id == id);
    _persist();
    notifyListeners();
  }

  /// Feed is local-only until Firebase is configured.
  bool get feedOnline => false;

  /// Demo posts created from real local training data so the feed
  /// breathes even before a backend is wired up.
  List<Post> feedWithSessionActivity() {
    final out = List<Post>.of(posts);
    final recent = sessions.reversed.take(3).toList();
    for (final s in recent) {
      final when = t.shortDateYear(s.date);
      final text = t.feedSessionCard('${s.exercises.length}', volumeLabel(s.volume), when);
      out.add(Post(
        id: 's-${s.date.millisecondsSinceEpoch}-${s.volume.round()}',
        author: profile.name,
        code: myInviteCode,
        text: text,
        createdAt: s.date,
        likes: 0,
      ));
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }
}