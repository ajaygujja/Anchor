import 'package:anchor/core/copy.dart';
import 'package:anchor/features/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The sign-in screen: app name, the philosophy line, and a single
/// Google sign-in action (spec §2.2A).
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) => current.signInFailed,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text(Copy.signInFailed)));
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(Copy.appName, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    Copy.philosophy,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),
                  FilledButton(
                    onPressed: () => context.read<AuthBloc>().add(
                      const AuthSignInRequested(),
                    ),
                    child: const Text(Copy.continueWithGoogle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
