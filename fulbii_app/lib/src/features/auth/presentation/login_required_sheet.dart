import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session_controller.dart';

/// Requests authentication without taking guests away from the screen they are exploring.
Future<bool> requireSignIn(
  BuildContext context,
  WidgetRef ref, {
  required String action,
}) async {
  if (ref.read(sessionControllerProvider).isAuthenticated) {
    return true;
  }

  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _LoginRequiredSheet(action: action),
      ) ??
      false;
}

class _LoginRequiredSheet extends ConsumerWidget {
  const _LoginRequiredSheet({required this.action});

  final String action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (session.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop(true);
      });
    }

    final isLoading = session.loading;
    final isAppleAvailable = defaultTargetPlatform == TargetPlatform.iOS;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Icon(Icons.lock_outline, size: 34),
          const SizedBox(height: 12),
          Text(
            'Inicia sesión para $action',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Explora Fulbii libremente. Para continuar con esta acción necesitas una cuenta.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: isLoading
                ? null
                : () => ref
                      .read(sessionControllerProvider.notifier)
                      .signInWithGoogle(),
            icon: const Text(
              'G',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            label: const Text('Continuar con Google'),
          ),
          if (isAppleAvailable) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => ref
                        .read(sessionControllerProvider.notifier)
                        .signInWithApple(),
              icon: const Icon(Icons.apple),
              label: const Text('Continuar con Apple'),
            ),
          ],
          if (session.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              session.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
