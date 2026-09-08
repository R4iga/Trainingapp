import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/models/profile.dart';
import 'package:gymmane/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sync service never throws and stays offline without Firebase config', () async {
    await SyncService.instance.init();
    expect(SyncService.instance.online, isFalse);
    await SyncService.instance.pushProfile('AB12', Profile());
    await SyncService.instance.pushFriends('AB12', const []);
    await SyncService.instance.pushGroups('AB12', const []);
    await SyncService.instance.pushPosts('AB12', const []);
  });
}