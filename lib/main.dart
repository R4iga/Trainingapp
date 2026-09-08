import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/gymmane_app.dart';
import 'services/alarm_store.dart';
import 'services/home_widget_bridge.dart';
import 'services/local_store.dart';
import 'services/media_store.dart';
import 'services/rest_alarm.dart';
import 'services/sync_service.dart';
import 'state/fit_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  await initializeDateFormatting();
  await Store.instance.init();
  await MediaStore.init();
  await AlarmStore.init();
  fit.loadFromStore();
  await RestAlarm.instance.init();
  fit.syncPhotoReminder();

  await SyncService.instance.init();
  _pushLocalToCloud();

  fit.onWidgetsShouldUpdate = HomeWidgetBridge.update;
  runApp(const GymManeApp());

  WidgetsBinding.instance.addPostFrameCallback((_) => HomeWidgetBridge.update());
}

void _pushLocalToCloud() {
  if (!SyncService.instance.online) return;
  final code = fit.myInviteCode;
  SyncService.instance.pushProfile(code, fit.profile);
  SyncService.instance.pushFriends(code, fit.friends);
  SyncService.instance.pushGroups(code, fit.groups);
  SyncService.instance.pushPosts(code, fit.posts);
}
