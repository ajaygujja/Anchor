import 'package:anchor/core/copy.dart';
import 'package:anchor/features/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The daily home screen.
///
/// Phase 1 stub: authenticated landing with a sign-out affordance. The habit
/// list, quote card, and check-in controls land in later phases (spec §11).
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Copy.appName),
        actions: [
          IconButton(
            tooltip: Copy.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
      body: const Center(child: Text(Copy.dashboardComingSoon)),
    );
  }
}
