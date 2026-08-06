import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_error.dart';
import '../data/clubs_repository.dart';

String createClubVisibilityLabel(bool isVisible) {
  return isVisible ? 'Grupo visible para todos' : 'Grupo no visible para todos';
}

bool canConfigureClubJoinRequests(bool isVisible) => isVisible;

class CreateClubScreen extends ConsumerStatefulWidget {
  const CreateClubScreen({super.key});

  @override
  ConsumerState<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends ConsumerState<CreateClubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isVisible = true;
  bool _linkJoinEnabled = true;
  String _pichangaScope = 'admins';
  String _renotifyScope = 'members';
  int _audienceMaxDegree = 3;
  File? _logo;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'nombre': _nameController.text.trim(),
        'descripcion': _descriptionController.text.trim(),
        'is_visible': _isVisible,
        'link_join_enabled': _linkJoinEnabled,
        'pichanga_create_scope': _pichangaScope,
        'renotify_scope': _renotifyScope,
        'audience_max_degree': _audienceMaxDegree,
        'renotify_cooldown_minutes': 30,
        'renotify_max_per_pichanga': 5,
      };
      final repository = ref.read(clubsRepositoryProvider);
      if (_logo == null) {
        await repository.createClub(payload);
      } else {
        await repository.createClubWithLogo(payload, _logo!);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
        setState(() => _isSubmitting = false);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear el grupo.')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _setVisibility(bool value) {
    setState(() {
      _isVisible = value;
      if (!value) {
        _linkJoinEnabled = false;
      }
    });
  }

  Future<void> _pickLogo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return;
    }

    final image = await ImagePicker().pickImage(source: source);
    if (image == null) {
      return;
    }

    final compressed = await _compressLogo(image);
    if (compressed != null && mounted) {
      setState(() => _logo = compressed);
    }
  }

  Future<File?> _compressLogo(XFile image) async {
    for (final quality in [82, 65, 50]) {
      final target =
          '${Directory.systemTemp.path}/fulbii_club_${DateTime.now().microsecondsSinceEpoch}_$quality.jpg';
      final output = await FlutterImageCompress.compressAndGetFile(
        image.path,
        target,
        minWidth: 1200,
        minHeight: 1200,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (output != null && await output.length() <= 2 * 1024 * 1024) {
        return File(output.path);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo comprimir la foto a menos de 2 MB.'),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear grupo'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              'Configura tu grupo',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Crea un espacio para organizar pichangas y conectar con tu comunidad.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel(
              icon: Icons.groups_outlined,
              title: 'Información básica',
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Nombre del grupo *',
                hintText: 'Ej. Los del sábado',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 3) {
                  return 'Escribe un nombre de al menos 3 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: '¿Qué tipo de grupo es?',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            _LogoCard(
              file: _logo,
              onPick: _pickLogo,
              onRemove: _logo == null
                  ? null
                  : () => setState(() => _logo = null),
            ),
            const SizedBox(height: 12),
            _SettingCard(
              icon: Icons.visibility_outlined,
              title: createClubVisibilityLabel(_isVisible),
              subtitle: _isVisible
                  ? 'Otros jugadores podrán encontrarlo.'
                  : 'Solo podrán verlo sus integrantes.',
              trailing: Switch.adaptive(
                value: _isVisible,
                onChanged: _setVisibility,
              ),
            ),
            if (canConfigureClubJoinRequests(_isVisible)) ...[
              const SizedBox(height: 10),
              _SettingCard(
                icon: Icons.link,
                title: 'Permitir solicitudes de ingreso',
                subtitle: _linkJoinEnabled
                    ? 'Los jugadores podrán pedir entrar.'
                    : 'El grupo no aceptará solicitudes públicas.',
                trailing: Switch.adaptive(
                  value: _linkJoinEnabled,
                  onChanged: (value) =>
                      setState(() => _linkJoinEnabled = value),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _SectionLabel(
              icon: Icons.sports_soccer,
              title: 'Permisos del grupo',
            ),
            const SizedBox(height: 10),
            _ChoiceCard<String>(
              title: 'Quién puede crear pichangas',
              value: _pichangaScope,
              options: const {
                'admins': 'Solo admins',
                'members': 'Admins y miembros',
              },
              onChanged: (value) => setState(() => _pichangaScope = value),
            ),
            const SizedBox(height: 10),
            _ChoiceCard<String>(
              title: 'Quién puede re-avisar',
              value: _renotifyScope,
              options: const {
                'admins': 'Solo admins',
                'members': 'Admins y miembros',
              },
              onChanged: (value) => setState(() => _renotifyScope = value),
            ),
            const SizedBox(height: 10),
            _ChoiceCard<int>(
              title: 'Alcance de audiencia',
              value: _audienceMaxDegree,
              options: const {1: '1er grado', 2: '2do grado', 3: '3er grado'},
              onChanged: (value) => setState(() => _audienceMaxDegree = value),
            ),
            const SizedBox(height: 24),
            Card(
              color: colorScheme.primaryContainer.withValues(alpha: 0.45),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Después de crear el grupo podrás invitar jugadores y organizar tu primera pichanga.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_isSubmitting ? 'Creando grupo...' : 'Crear grupo'),
          ),
        ),
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  const _LogoCard({required this.file, required this.onPick, this.onRemove});

  final File? file;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: file == null
                    ? ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.groups_outlined,
                          color: colorScheme.primary,
                        ),
                      )
                    : Image.file(file!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foto del grupo (opcional)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file == null
                        ? 'Agrega una imagen para identificar tu grupo.'
                        : 'La foto se mostrará como imagen del grupo.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (file != null)
              IconButton(
                tooltip: 'Eliminar foto',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            IconButton(
              tooltip: file == null ? 'Agregar foto' : 'Cambiar foto',
              onPressed: onPick,
              icon: Icon(
                file == null ? Icons.add_a_photo_outlined : Icons.edit_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }
}

class _ChoiceCard<T> extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.entries.map((entry) {
                final selected = entry.key == value;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (_) => onChanged(entry.key),
                  selectedColor: colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
