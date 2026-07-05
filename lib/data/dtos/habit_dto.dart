import 'package:anchor/domain/entities/habit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore habit documents to [Habit] entities and back (spec §4).
///
/// Firestore types (`Timestamp`, `FieldValue`) never cross into the domain;
/// conversion happens only here.
abstract final class HabitDto {
  /// Reads a habit document. `createdAt` is `null` until the server resolves
  /// its timestamp, which a freshly written local snapshot reflects.
  static Habit toEntity(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Habit(
      id: doc.id,
      name: data['name'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      archived: data['archived'] as bool? ?? false,
      sortOrder: data['sortOrder'] as int? ?? 0,
      color: data['color'] as String?,
    );
  }

  /// Payload for a new habit; `createdAt` is stamped by the server.
  static Map<String, dynamic> toCreate({
    required String name,
    required String? color,
    required int sortOrder,
  }) {
    return {
      'name': name,
      'color': color,
      'archived': false,
      'sortOrder': sortOrder,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
