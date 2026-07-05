/// Sealed failure hierarchy surfaced to the presentation layer.
///
/// Repositories translate raw exceptions into these types so the UI never sees
/// a `FirebaseException` directly (spec §5.1).
sealed class Failure implements Exception {
  const Failure();
}

/// The device is offline or the request timed out.
class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// The current user is not allowed to perform the operation (rules rejection).
class PermissionFailure extends Failure {
  const PermissionFailure();
}

/// Anything not otherwise classified.
class UnknownFailure extends Failure {
  const UnknownFailure([this.cause]);

  final Object? cause;
}
