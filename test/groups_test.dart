import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fit.friends.clear();
    fit.groups.clear();
    fit.inviteCode = '';
  });

  test('a group stores its roster and can be removed', () {
    fit.addFriend('Ava', 'aaaa');
    final g = fit.createGroup('Chest day', ['Ava']);
    expect(fit.groups.length, 1);
    expect(g.members, ['Ava']);
    expect(fit.groups.first.name, 'Chest day');

    fit.removeGroup(g.id);
    expect(fit.groups, isEmpty);
  });

  test('renaming a group updates only that group', () {
    final a = fit.createGroup('A', []);
    fit.createGroup('B', []);
    fit.renameGroup(a.id, 'Push power');
    expect(fit.groups.map((g) => g.name), ['Push power', 'B']);
  });

  test('groups survive an export/import round trip', () {
    fit.addFriend('Leo', 'xyz1');
    fit.createGroup('Leg day', ['Leo', 'Ava']);
    final backup = fit.exportJson();
    expect(fit.groups.length, 1);
    expect(fit.importJson(backup), true);
    expect(fit.groups.length, 1);
    expect(fit.groups.first.name, 'Leg day');
    expect(fit.groups.first.members, ['Leo', 'Ava']);
  });
}