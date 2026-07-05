import 'package:flutter/material.dart';

/// Neutral loading screen shown while the restored auth session resolves
/// (`AuthStatus.unknown`), so a returning user never flashes the sign-in
/// screen (spec §2.2A).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
