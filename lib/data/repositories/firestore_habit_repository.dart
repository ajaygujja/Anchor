import 'package:anchor/core/failures.dart';
import 'package:anchor/data/dtos/habit_dto.dart';
import 'package:anchor/domain/entities/habit.dart';
import 'package:anchor/domain/repositories/habit_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore implementation of [HabitRepository].
///
/// All data is scoped under `users/{uid}/habits`, the uid read from the
/// signed-in Firebase user; habit screens are reachable only when
/// authenticated (router redirect, spec §8.3). Raw [FirebaseException]s are
/// translated to sealed [Failure]s at this boundary.
class FirestoreHabitRepository implements HabitRepository {
  FirestoreHabitRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _habits {
    final uid = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(uid).collection('habits');
  }

  @override
  Stream<List<Habit>> watchActiveHabits() => _watch(archived: false);

  @override
  Stream<List<Habit>> watchArchivedHabits() => _watch(archived: true);

  Stream<List<Habit>> _watch({required bool archived}) {
    return _habits
        .where('archived', isEqualTo: archived)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(HabitDto.toEntity).toList())
        .handleError((Object error) => throw _mapException(error));
  }

  @override
  Future<void> addHabit({required String name, String? color}) {
    return _guard(() async {
      final sortOrder = await _nextSortOrder();
      await _habits.add(
        HabitDto.toCreate(name: name, color: color, sortOrder: sortOrder),
      );
    });
  }

  @override
  Future<void> renameHabit({required String id, required String name}) {
    return _guard(() => _habits.doc(id).update({'name': name}));
  }

  @override
  Future<void> setArchived({required String id, required bool archived}) {
    return _guard(() => _habits.doc(id).update({'archived': archived}));
  }

  @override
  Future<void> reorder(List<String> orderedIds) {
    return _guard(() async {
      final batch = _firestore.batch();
      for (var i = 0; i < orderedIds.length; i++) {
        batch.update(_habits.doc(orderedIds[i]), {'sortOrder': i});
      }
      await batch.commit();
    });
  }

  /// One greater than the highest existing `sortOrder` across all habits, so a
  /// new habit appends after active and archived alike.
  Future<int> _nextSortOrder() async {
    final snapshot = await _habits
        .orderBy('sortOrder', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return 0;
    return (snapshot.docs.first.data()['sortOrder'] as int? ?? -1) + 1;
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseException catch (e) {
      throw _mapException(e);
    } on Object catch (e) {
      throw UnknownFailure(e);
    }
  }

  Failure _mapException(Object error) {
    if (error is Failure) return error;
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => const PermissionFailure(),
        'unavailable' => const NetworkFailure(),
        _ => UnknownFailure(error),
      };
    }
    return UnknownFailure(error);
  }
}
