import 'package:anchor/data/dtos/habit_dto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  Future<DocumentSnapshot<Map<String, dynamic>>> writeDoc(
    Map<String, dynamic> data,
  ) async {
    final ref = firestore.collection('habits').doc('h1');
    await ref.set(data);
    return ref.get();
  }

  group('HabitDto.toEntity', () {
    test('maps all fields, converting the timestamp to a DateTime', () async {
      final createdAt = DateTime(2026, 7, 5, 9, 30);
      final doc = await writeDoc({
        'name': 'Read',
        'createdAt': Timestamp.fromDate(createdAt),
        'archived': false,
        'sortOrder': 2,
        'color': '#3A5A78',
      });

      final habit = HabitDto.toEntity(doc);

      expect(habit.id, 'h1');
      expect(habit.name, 'Read');
      expect(habit.createdAt, createdAt);
      expect(habit.archived, false);
      expect(habit.sortOrder, 2);
      expect(habit.color, '#3A5A78');
    });

    test('leaves createdAt null when the timestamp is unresolved', () async {
      final doc = await writeDoc({
        'name': 'Walk',
        'archived': false,
        'sortOrder': 0,
        'color': null,
      });

      final habit = HabitDto.toEntity(doc);

      expect(habit.createdAt, isNull);
      expect(habit.color, isNull);
    });
  });

  group('HabitDto.toCreate', () {
    test('stamps a server timestamp and defaults archived to false', () {
      final payload = HabitDto.toCreate(
        name: 'Meditate',
        color: null,
        sortOrder: 3,
      );

      expect(payload['name'], 'Meditate');
      expect(payload['color'], isNull);
      expect(payload['archived'], false);
      expect(payload['sortOrder'], 3);
      expect(payload['createdAt'], isA<FieldValue>());
    });
  });
}
