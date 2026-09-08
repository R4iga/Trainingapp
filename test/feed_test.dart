import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fit.posts.clear();
    fit.friends.clear();
    fit.groups.clear();
    fit.inviteCode = '';
  });

  test('posting inserts a post authored by the current user', () {
    final p = fit.addPost('   Big session today   ');
    expect(fit.posts.length, 1);
    expect(p.author, fit.profile.name);
    expect(p.text, 'Big session today');
    expect(p.code, isNotEmpty);
  });

  test('blank posts are rejected', () {
    final p = fit.addPost('   ');
    expect(fit.posts, isEmpty);
    expect(p.id, isEmpty);
  });

  test('long posts are truncated to a readable length', () {
    final long = 'x' * 500;
    final p = fit.addPost(long);
    expect(p.text.length, lessThanOrEqualTo(421));
    expect(p.text.endsWith('…'), isTrue);
  });

  test('liking toggles the like count', () {
    fit.addPost('PR week!');
    final p = fit.posts.first;
    expect(p.likes, 0);
    fit.toggleLike(p.id);
    expect(p.liked, isTrue);
    expect(p.likes, 1);
    fit.toggleLike(p.id);
    expect(p.liked, isFalse);
    expect(p.likes, 0);
  });

  test('removing a post only removes that one', () {
    fit.addPost('First');
    fit.addPost('Second');
    final id = fit.posts.first.id;
    fit.removePost(id);
    expect(fit.posts.length, 1);
    expect(fit.posts.first.text, 'First');
  });

  test('the feed synthesizes entries from recent sessions', () {
    final now = DateTime.now();
    final session = LoggedSession(now, 1800, const []);
    fit.sessions.add(session);
    final items = fit.feedWithSessionActivity();
    expect(items.length, greaterThanOrEqualTo(1));
    expect(items.map((p) => p.id).contains('s-${now.millisecondsSinceEpoch}-0'), isTrue);
    fit.sessions.clear();
  });

  test('posts survive an export/import round trip', () {
    fit.addPost('Hello crew');
    final backup = fit.exportJson();
    expect(fit.posts.length, 1);
    expect(fit.importJson(backup), true);
    expect(fit.posts.length, 1);
    expect(fit.posts.first.text, 'Hello crew');
  });
}