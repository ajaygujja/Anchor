import 'package:anchor/data/repositories/firestore_habit_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

Map<String, dynamic> _habit(
  String name,
  int sortOrder, {
  bool archived = false,
}) {
  return {'name': name, 'archived': archived, 'sortOrder': sortOrder};
}

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreHabitRepository repository;

  const uid = 'uid-1';

  CollectionReference<Map<String, dynamic>> habits() =>
      firestore.collection('users').doc(uid).collection('habits');

  setUp(() {
    firestore = FakeFirebaseFirestore();
    final auth = _MockFirebaseAuth();
    final user = _MockUser();
    when(() => user.uid).thenReturn(uid);
    when(() => auth.currentUser).thenReturn(user);
    repository = FirestoreHabitRepository(firestore, auth);
  });

  group('addHabit', () {
    test('appends with an incrementing sortOrder', () async {
      await repository.addHabit(name: 'Read');
      await repository.addHabit(name: 'Walk', color: '#4E7A5A');

      final docs = (await habits().orderBy('sortOrder').get()).docs;
      expect(docs.map((d) => d.data()['name']), ['Read', 'Walk']);
      expect(docs.map((d) => d.data()['sortOrder']), [0, 1]);
      expect(docs.last.data()['color'], '#4E7A5A');
      expect(docs.first.data()['archived'], false);
    });
  });

  group('renameHabit', () {
    test('updates the name only', () async {
      final ref = await habits().add({
        'name': 'Old',
        'archived': false,
        'sortOrder': 0,
      });

      await repository.renameHabit(id: ref.id, name: 'New');

      expect((await ref.get()).data()!['name'], 'New');
    });
  });

  group('setArchived', () {
    test('archives and restores', () async {
      final ref = await habits().add({
        'name': 'Read',
        'archived': false,
        'sortOrder': 0,
      });

      await repository.setArchived(id: ref.id, archived: true);
      expect((await ref.get()).data()!['archived'], true);

      await repository.setArchived(id: ref.id, archived: false);
      expect((await ref.get()).data()!['archived'], false);
    });
  });

  group('reorder', () {
    test('rewrites sortOrder to match the given order', () async {
      final a = await habits().add(_habit('A', 0));
      final b = await habits().add(_habit('B', 1));
      final c = await habits().add(_habit('C', 2));

      await repository.reorder([c.id, a.id, b.id]);

      expect((await c.get()).data()!['sortOrder'], 0);
      expect((await a.get()).data()!['sortOrder'], 1);
      expect((await b.get()).data()!['sortOrder'], 2);
    });
  });

  group('watchActiveHabits / watchArchivedHabits', () {
    test('split by the archived flag, ordered by sortOrder', () async {
      await habits().add(_habit('B', 1));
      await habits().add(_habit('A', 0));
      await habits().add(_habit('Z', 5, archived: true));

      final active = await repository.watchActiveHabits().first;
      final archived = await repository.watchArchivedHabits().first;

      expect(active.map((h) => h.name), ['A', 'B']);
      expect(archived.map((h) => h.name), ['Z']);
    });
  });
}
