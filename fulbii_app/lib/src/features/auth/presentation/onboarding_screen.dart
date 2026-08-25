import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/app_user.dart';
import '../../../core/theme/theme_controller.dart';
import '../../profile/data/profile_repository.dart';
import '../session_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nickController = TextEditingController();
  final _heightController = TextEditingController();
  final _picker = ImagePicker();
  final _pageController = PageController();
  Timer? _nickTimer;
  String? _lastNickQuery;
  int _nickCheckGeneration = 0;
  File? _avatarFile;
  DateTime? _birthDate;
  String _sex = 'M';
  String _theme = 'light';
  int _page = 0;
  bool? _nickAvailable;
  String? _inlineError;
  final _skills = <String, double>{
    'delantero': 3,
    'mediocampo': 3,
    'defensa': 3,
    'arquero': 3,
    'fisico': 3,
  };

  static const _skillMeta =
      <({String key, String label, IconData icon, Color color})>[
        (
          key: 'delantero',
          label: 'Delantero',
          icon: Icons.sports_soccer_rounded,
          color: Color(0xFF78C86E),
        ),
        (
          key: 'mediocampo',
          label: 'Mediocampo',
          icon: Icons.hub_rounded,
          color: Color(0xFF78C86E),
        ),
        (
          key: 'defensa',
          label: 'Defensa',
          icon: Icons.shield_rounded,
          color: Color(0xFF78C86E),
        ),
        (
          key: 'arquero',
          label: 'Arquero',
          icon: Icons.sports_handball_rounded,
          color: Color(0xFF58B9D8),
        ),
        (
          key: 'fisico',
          label: 'Físico',
          icon: Icons.directions_run_rounded,
          color: Color(0xFFF0AE52),
        ),
      ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionControllerProvider).user;
    if (user != null) {
      _nickController.text = user.nick ?? '';
      _heightController.text = user.alturaCm?.toString() ?? '';
      _sex = user.sexo ?? 'M';
      _theme = user.themeMode ?? 'light';
      if (user.fecNac != null) _birthDate = DateTime.tryParse(user.fecNac!);
      _page = ((user.onboardingStep - 1).clamp(0, 5));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pageController.jumpToPage(_page);
      });
    }
  }

  @override
  void dispose() {
    _nickTimer?.cancel();
    _nickController.dispose();
    _heightController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    _dismissKeyboard();
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) setState(() => _avatarFile = File(picked.path));
  }

  Future<void> _checkNick(String value) async {
    _nickTimer?.cancel();
    final generation = ++_nickCheckGeneration;
    final nick = value.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{3,20}$').hasMatch(nick)) {
      _lastNickQuery = null;
      setState(() => _nickAvailable = null);
      return;
    }
    if (mounted) setState(() => _nickAvailable = null);
    _nickTimer = Timer(const Duration(milliseconds: 600), () async {
      if (_lastNickQuery == nick) return;
      _lastNickQuery = nick;
      try {
        final available = await ref
            .read(profileRepositoryProvider)
            .isNickAvailable(nick);
        if (mounted &&
            generation == _nickCheckGeneration &&
            _nickController.text.trim() == nick) {
          setState(() => _nickAvailable = available);
        }
      } catch (_) {
        if (generation == _nickCheckGeneration) _lastNickQuery = null;
      }
    });
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.hide'));
  }

  Future<bool> _savePage() async {
    final controller = ref.read(sessionControllerProvider.notifier);
    if (_page == 1) {
      final nick = _nickController.text.trim();
      if (!RegExp(r'^[A-Za-z0-9_-]{3,20}$').hasMatch(nick) ||
          _nickAvailable != true) {
        setState(
          () => _inlineError =
              'Usa 3–20 caracteres, sin espacios, y confirma que el nick esté disponible.',
        );
        return false;
      }
      await controller.completeOnboarding(nick: nick);
    } else if (_page == 2 && _avatarFile != null) {
      await controller.completeOnboarding(avatarFile: _avatarFile);
    } else if (_page == 3) {
      final height = int.tryParse(_heightController.text.trim());
      if (height == null || height < 90 || height > 260 || _birthDate == null) {
        setState(
          () => _inlineError =
              'Completa una altura válida y tu fecha de nacimiento.',
        );
        return false;
      }
      await controller.completeOnboarding(
        sexo: _sex,
        alturaCm: height,
        fecNac: _birthDate!.toIso8601String().substring(0, 10),
      );
    } else if (_page == 4) {
      await controller.completeOnboarding(
        skills: Map<String, double>.from(_skills),
      );
    } else if (_page == 5) {
      await controller.completeOnboarding(themeMode: _theme);
      await ref.read(themeModeProvider.notifier).setDarkMode(_theme == 'dark');
    }
    final state = ref.read(sessionControllerProvider);
    if (state.errorMessage != null) {
      setState(() => _inlineError = state.errorMessage);
      return false;
    }
    return true;
  }

  Future<void> _next() async {
    _dismissKeyboard();
    setState(() => _inlineError = null);
    if (_page > 0 && !await _savePage()) return;
    if (_page == 6) return;
    setState(() => _page++);
    await _pageController.animateToPage(
      _page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _back() async {
    if (_page == 0) return;
    _dismissKeyboard();
    setState(() => _page--);
    await _pageController.animateToPage(
      _page,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final user = session.user;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          child: Column(
            children: [
              Row(
                children: [
                  if (_page > 0)
                    IconButton(
                      onPressed: session.loading ? null : _back,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  Expanded(
                    child: Text(
                      'Tu perfil Fulbii',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${_page + 1}/7',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_page + 1) / 7,
                minHeight: 6,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  children: [
                    _welcome(),
                    _nickname(),
                    _photo(user),
                    _personal(),
                    _skillsPage(),
                    _themePage(),
                    _finish(),
                  ],
                ),
              ),
              if (_inlineError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _inlineError!,
                    style: TextStyle(color: colors.error),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: session.loading ? null : _next,
                  child: session.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_page == 6 ? 'Entrar a Fulbii' : 'Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
    ],
  );
  Widget _welcome() => Center(
    child: _heading(
      'Bienvenido a Fulbii',
      'En unos minutos dejaremos tu perfil listo para encontrar mejores pichangas y equipos.',
    ),
  );

  Widget _nickname() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        'Elige tu nickname',
        'Será tu identidad visible para otros jugadores.',
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _nickController,
        autofocus: true,
        maxLength: 20,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9_-]')),
        ],
        onChanged: _checkNick,
        onTapOutside: (_) => _dismissKeyboard(),
        decoration: InputDecoration(
          labelText: 'Nickname',
          hintText: 'pichanguero21',
          prefixText: '@',
          suffixIcon: _nickAvailable == true
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Solo letras, números, guion y guion bajo. Sin espacios.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  Widget _photo(AppUser? user) {
    ImageProvider? image;
    if (_avatarFile != null)
      image = FileImage(_avatarFile!);
    else if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
      image = NetworkImage(user.avatarUrl!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Confirma tu foto',
          'Puedes usar la foto de Google o Apple, cambiarla o dejar tu inicial.',
        ),
        const SizedBox(height: 24),
        Center(
          child: CircleAvatar(
            radius: 72,
            backgroundImage: image,
            child: image == null
                ? Text(
                    (_nickController.text.isEmpty
                            ? 'F'
                            : _nickController.text[0])
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Cámara'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _personal() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        'Conócete mejor',
        'Estos datos nos ayudan a mostrarte partidos adecuados.',
      ),
      const SizedBox(height: 20),
      DropdownButtonFormField<String>(
        initialValue: _sex,
        decoration: const InputDecoration(labelText: 'Sexo'),
        items: const [
          DropdownMenuItem(value: 'M', child: Text('Hombre')),
          DropdownMenuItem(value: 'F', child: Text('Mujer')),
        ],
        onChanged: (v) => setState(() => _sex = v ?? 'M'),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _heightController,
        keyboardType: TextInputType.number,
        onTapOutside: (_) => _dismissKeyboard(),
        decoration: const InputDecoration(
          labelText: 'Altura (cm)',
          suffixText: 'cm',
        ),
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(1920),
            lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
            initialDate: _birthDate ?? DateTime(1995),
          );
          if (picked != null) setState(() => _birthDate = picked);
        },
        icon: const Icon(Icons.cake_outlined),
        label: Text(
          _birthDate == null
              ? 'Elegir fecha de nacimiento'
              : 'Nacimiento: ${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
        ),
      ),
    ],
  );

  Widget _skillsPage() => ListView(
    children: [
      _heading(
        'Tu estilo de juego',
        'Valórate para obtener una posición sugerida. Podrás mejorarla con tus partidos.',
      ),
      const SizedBox(height: 12),
      ..._skillMeta.map((skill) => _skillControl(skill)),
      const SizedBox(height: 8),
      Text(
        'Esta autocalificación inicial queda registrada como referencia. Las próximas valoraciones las harán otros jugadores.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
  Widget _skillControl(
    ({String key, String label, IconData icon, Color color}) skill,
  ) => Column(
    children: [
      Row(
        children: [
          Icon(skill.icon, color: skill.color),
          const SizedBox(width: 8),
          Expanded(child: Text(skill.label)),
          Text(
            (_skills[skill.key] ?? 0).toStringAsFixed(1),
            style: TextStyle(color: skill.color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
      Slider(
        value: _skills[skill.key] ?? 0,
        min: 0,
        max: 5,
        divisions: 50,
        activeColor: skill.color,
        onChanged: (v) => setState(() => _skills[skill.key] = v),
      ),
    ],
  );
  Widget _themePage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        'Elige tu ambiente',
        'Puedes cambiarlo más adelante desde tu perfil.',
      ),
      const SizedBox(height: 24),
      RadioListTile<String>(
        value: 'light',
        groupValue: _theme,
        onChanged: (v) => setState(() => _theme = v!),
        title: const Text('Modo claro'),
        subtitle: const Text('Luminoso y limpio'),
        secondary: const Icon(Icons.light_mode_outlined),
      ),
      RadioListTile<String>(
        value: 'dark',
        groupValue: _theme,
        onChanged: (v) => setState(() => _theme = v!),
        title: const Text('Modo oscuro'),
        subtitle: const Text('Cómodo para jugar de noche'),
        secondary: const Icon(Icons.dark_mode_outlined),
      ),
    ],
  );
  Widget _finish() => Center(
    child: _heading(
      'Todo listo',
      'Tu perfil está preparado. Entra y empieza a jugar.',
    ),
  );
}
