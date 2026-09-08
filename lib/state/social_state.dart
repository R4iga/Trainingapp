part of 'fit_state.dart';

int _friendSeq = 0;

mixin SocialState on FitCore {
  static const _inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// A short, human-typable code others can use to find this user.
  /// Generated lazily the first time it's read, then persisted.
  String get myInviteCode {
    if (inviteCode.isEmpty) {
      final rnd = math.Random();
      inviteCode = List.generate(
        4,
        (_) => _inviteAlphabet[rnd.nextInt(_inviteAlphabet.length)],
      ).join();
      _persist();
    }
    return inviteCode;
  }

  void goFriends() => pushRoute('friends');

  void backFromFriends() => popRoute();

  /// Adds a friend by invite code. Returns a status so the UI can toast.
  ///
  /// 0 = ok, 1 = missing code, 2 = own code, 3 = duplicate.
  int addFriend(String name, String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return 1;
    if (normalized == myInviteCode) return 2;
    if (friends.any((f) => f.code == normalized)) return 3;
    friends.add(Friend(
      id: 'f-${_friendSeq++}-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? '···' : name.trim(),
      code: normalized,
      addedAt: DateTime.now(),
    ));
    _persist();
    notifyListeners();
    return 0;
  }

  void removeFriend(String id) {
    friends.removeWhere((f) => f.id == id);
    _persist();
    notifyListeners();
  }

  /// Share text for inviting a friend (used with the system share sheet).
  String inviteShareText() =>
      t.friendsInviteBody(myInviteCode);
}