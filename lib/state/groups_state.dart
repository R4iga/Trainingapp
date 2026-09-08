part of 'fit_state.dart';

int _groupSeq = 0;

mixin GroupsState on FitCore, SocialState {
  void goGroups() => pushRoute('groups');

  void backFromGroups() => popRoute();

  /// Creates a group. `members` holds friend names invited to the group.
  Group createGroup(String name, List<String> members) {
    final g = Group(
      id: 'g-${_groupSeq++}-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? '···' : name.trim(),
      members: List.of(members),
      createdAt: DateTime.now(),
    );
    groups.add(g);
    _persist();
    notifyListeners();
    return g;
  }

  void renameGroup(String id, String name) {
    final g = groups.where((x) => x.id == id).firstOrNull;
    if (g == null) return;
    g.name = name.trim().isEmpty ? g.name : name.trim();
    _persist();
    notifyListeners();
  }

  void removeGroup(String id) {
    groups.removeWhere((g) => g.id == id);
    _persist();
    notifyListeners();
  }
}