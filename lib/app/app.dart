import 'package:anchor/app/di.dart';
import 'package:anchor/app/router.dart';
import 'package:anchor/core/copy.dart';
import 'package:anchor/core/theme/theme.dart';
import 'package:anchor/domain/repositories/auth_repository.dart';
import 'package:anchor/features/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Root of the Anchor application: provides [AuthBloc] above the router and
/// configures `MaterialApp.router` with the light/dark themes.
class AnchorApp extends StatelessWidget {
  const AnchorApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>.value(
      value: dependencies.authRepository,
      child: BlocProvider(
        create: (context) =>
            AuthBloc(dependencies.authRepository)
              ..add(const AuthSubscriptionRequested()),
        child: const _AnchorView(),
      ),
    );
  }
}

class _AnchorView extends StatefulWidget {
  const _AnchorView();

  @override
  State<_AnchorView> createState() => _AnchorViewState();
}

class _AnchorViewState extends State<_AnchorView> {
  late final GoRouter _router = createRouter(context.read<AuthBloc>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: Copy.appName,
      theme: AnchorTheme.light,
      darkTheme: AnchorTheme.dark,
      routerConfig: _router,
    );
  }
}
