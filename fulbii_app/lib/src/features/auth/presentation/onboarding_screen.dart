import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nickController = TextEditingController();
  String _sexo = 'M';

  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final controller = ref.read(sessionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Completa tu perfil')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Antes de continuar, define tu nick y sexo.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nickController,
                  decoration: const InputDecoration(
                    labelText: 'Nick',
                    hintText: 'pichanguero21',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.length < 3) return 'Mínimo 3 caracteres';
                    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(v)) {
                      return 'Solo letras, números, _ y -';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _sexo,
                  decoration: const InputDecoration(
                    labelText: 'Sexo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Hombre')),
                    DropdownMenuItem(value: 'F', child: Text('Mujer')),
                  ],
                  onChanged: session.loading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _sexo = value);
                          }
                        },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: session.loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }

                          await controller.completeOnboarding(
                            nick: _nickController.text.trim(),
                            sexo: _sexo,
                          );
                        },
                  child: session.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar y continuar'),
                ),
                const SizedBox(height: 12),
                if (session.errorMessage != null)
                  Text(
                    session.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
