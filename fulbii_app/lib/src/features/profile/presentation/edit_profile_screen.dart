import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../auth/session_controller.dart';
import '../../clubs/data/clubs_repository.dart';
import '../data/profile_repository.dart';
import 'profile_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nickController;
  late final TextEditingController _heightController;
  
  DateTime? _selectedBirthDate;
  String _selectedSex = 'M';
  File? _avatarFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionControllerProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _nickController = TextEditingController(text: user?.nick ?? '');
    _heightController = TextEditingController(
      text: user?.alturaCm != null ? '${user!.alturaCm}' : '',
    );
    _selectedSex = user?.sexo ?? 'M';
    if (user?.fecNac != null) {
      _selectedBirthDate = DateTime.tryParse(user!.fecNac!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nickController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto con la cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;
    final image = await ImagePicker().pickImage(source: source, imageQuality: 75);
    if (image == null) return;

    setState(() {
      _avatarFile = File(image.path);
    });
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    
    final payload = {
      'name': _nameController.text.trim(),
      'nick': _nickController.text.trim(),
      'sexo': _selectedSex,
      if (_selectedBirthDate != null)
        'fec_nac': DateFormat('yyyy-MM-dd').format(_selectedBirthDate!),
      'altura_cm': int.tryParse(_heightController.text.trim()),
    };

    try {
      await ref.read(profileRepositoryProvider).updateProfileWithAvatar(
            payload: payload,
            avatarFile: _avatarFile,
          );
      await ref.read(sessionControllerProvider.notifier).refreshMe();
      ref.invalidate(pichangaHistoryProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Perfil actualizado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el perfil: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).user;
    final config = ref.watch(appConfigProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ImageProvider? avatarImage;
    if (_avatarFile != null) {
      avatarImage = FileImage(_avatarFile!);
    } else if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      final resolved = resolveClubImageUrl(user.avatarUrl, config);
      if (resolved != null) {
        avatarImage = NetworkImage(resolved);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          if (!_saving)
            TextButton(
              onPressed: _save,
              child: Text(
                'Guardar',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          backgroundImage: avatarImage,
                          child: avatarImage == null
                              ? Text(
                                  user?.nick?.substring(0, 1).toUpperCase() ?? 'U',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: colorScheme.primary,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: IconButton(
                              onPressed: _pickAvatar,
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Información Personal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nickController,
                    decoration: InputDecoration(
                      labelText: 'Nick (usuario)',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'El nick es obligatorio';
                      }
                      if (!RegExp(r'^[A-Za-z0-9_\-]{3,20}$').hasMatch(val.trim())) {
                        return '3-20 caracteres alfanuméricos, guión o subguión';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Altura (cm)',
                      prefixIcon: const Icon(Icons.height),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return null;
                      final parsed = int.tryParse(val.trim());
                      if (parsed == null || parsed < 90 || parsed > 260) {
                        return 'Ingresa una altura válida (90-260 cm)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectBirthDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _selectedBirthDate == null
                            ? 'Seleccionar fecha'
                            : DateFormat('dd/MM/yyyy').format(_selectedBirthDate!),
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedBirthDate == null
                              ? Colors.grey.shade600
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSex,
                    decoration: InputDecoration(
                      labelText: 'Sexo',
                      prefixIcon: const Icon(Icons.wc_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('Hombre')),
                      DropdownMenuItem(value: 'F', child: Text('Mujer')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSex = value);
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Guardar Cambios',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
