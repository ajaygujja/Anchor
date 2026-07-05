import 'package:equatable/equatable.dart';

/// A single habit the user tracks (spec §4).
///
/// Cosmetic-only [color] and display-only [sortOrder] are stored; everything
/// derived (streaks, totals) is computed at read time and never lives here.
class Habit extends Equatable {
  const Habit({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.archived,
    required this.sortOrder,
    this.color,
  });

  /// Firestore document id under `users/{uid}/habits`.
  final String id;

  /// Display name, 1–60 characters (enforced by security rules, spec §6.1).
  final String name;

  /// Server creation time, or `null` while the server timestamp is pending
  /// (the local write reflects the write before the server resolves it).
  final DateTime? createdAt;

  /// Archived habits are hidden from the dashboard but keep their entries.
  final bool archived;

  /// Ascending position on the dashboard and Manage screens.
  final int sortOrder;

  /// Hex swatch (e.g. `#3A5A78`), or `null` for the default tint.
  final String? color;

  @override
  List<Object?> get props => [id, name, createdAt, archived, sortOrder, color];
}
