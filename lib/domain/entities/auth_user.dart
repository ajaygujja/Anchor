import 'package:equatable/equatable.dart';

/// The authenticated identity of the single Anchor user.
///
/// Carries only the Firebase UID; the domain never depends on Firebase's
/// `User` type (spec §5.1). All Firestore data is scoped under [uid] by path.
class AuthUser extends Equatable {
  const AuthUser({required this.uid});

  /// The stable Firebase account identifier.
  final String uid;

  @override
  List<Object?> get props => [uid];
}
