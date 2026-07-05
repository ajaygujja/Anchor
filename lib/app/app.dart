import 'package:flutter/material.dart';

/// Root of the Anchor application.
///
/// A placeholder shell for Phase 0. Later phases replace [MaterialApp] with
/// `MaterialApp.router` (go_router), real light/dark themes, and the auth
/// redirect wired through `AuthBloc`.
class AnchorApp extends StatelessWidget {
  const AnchorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anchor',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A5A78)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A5A78),
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(
        body: Center(child: Text('Anchor — never miss twice.')),
      ),
    );
  }
}
