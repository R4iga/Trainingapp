import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/friend.dart';
import '../models/group.dart';
import '../models/post.dart';
import '../models/profile.dart';

/// Cloud sync backbone for the social features (friends, groups, feed).
///
/// The app works fully offline until Firebase is configured. To connect:
///   1. Add your Firebase project to `android/google-services.json`.
///   2. `SyncService.instance.init()` in main() connects and `online` flips.
class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  bool _online = false;
  bool get online => _online;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _online = true;
    } catch (_) {
      _online = false;
    }
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  String _userId(String inviteCode) =>
      inviteCode.isEmpty ? 'local' : inviteCode;

  Future<void> pushProfile(String inviteCode, Profile p) async {
    if (!_online) return;
    await _users.doc(_userId(inviteCode)).set({
      'name': p.name,
      'sex': p.sex,
      'age': p.age,
      'heightCm': p.heightCm,
      'weightKg': p.weightKg,
      'activity': p.activity,
      'weeklyGoal': p.weeklyGoal,
      'code': inviteCode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> pushFriends(String inviteCode, List<Friend> friends) async {
    if (!_online) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final f in friends) {
      batch.set(_users.doc(_userId(inviteCode)).collection('friends').doc(f.id), {
        'name': f.name,
        'code': f.code,
        'addedAt': f.addedAt,
      });
    }
    await batch.commit();
  }

  Future<void> pushGroups(String inviteCode, List<Group> groups) async {
    if (!_online) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final g in groups) {
      batch.set(_users.doc(_userId(inviteCode)).collection('groups').doc(g.id), {
        'name': g.name,
        'members': g.members,
        'createdAt': g.createdAt,
      });
    }
    await batch.commit();
  }

  Future<void> pushPosts(String inviteCode, List<Post> posts) async {
    if (!_online) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final p in posts) {
      batch.set(
          _users.doc(_userId(inviteCode)).collection('posts').doc(p.id), {
        'author': p.author,
        'code': p.code,
        'text': p.text,
        'likes': p.likes,
        'createdAt': p.createdAt,
      });
    }
    await batch.commit();
  }
}