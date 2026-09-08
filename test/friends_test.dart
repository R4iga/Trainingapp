import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fit.friends.clear();
    fit.inviteCode = '';
  });

  test('invite code is generated once and persisted', () {
    final first = fit.myInviteCode;
    expect(first, matches(RegExp(r'^[A-Z2-9]{4}$')));
    expect(fit.myInviteCode, first);
  });

  test('adding a friend by code works and dedupes', () {
    expect(fit.addFriend('Ava', 'abcd'), 0);
    expect(fit.friends.length, 1);
    final f = fit.friends.first;
    expect(f.code, 'ABCD');
    expect(f.name, 'Ava');
    expect(fit.addFriend('Ava Again', 'abcd'), 3);
    expect(fit.addFriend('Self', fit.myInviteCode), 2);
    expect(fit.addFriend('No Code', '   '), 1);
    expect(fit.friends.length, 1);
  });

  test('friends survive a save/load round trip', () {
    fit.addFriend('Leo', 'xyz1');
    fit.persistNow();
    final json = fit.exportJson();

    expect(fit.importJson(json), true);
    expect(fit.friends.length, 1);
    expect(fit.friends.first.code, 'XYZ1');
    expect(fit.inviteCode, isNotEmpty);
  });

  test('removing a friend removes only that one', () {
    fit.addFriend('Ava', 'aaaa');
    fit.addFriend('Leo', 'bbbb');
    fit.removeFriend(fit.friends.first.id);
    expect(fit.friends.length, 1);
    expect(fit.friends.first.name, 'Leo');
  });
}