import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../clubs/data/clubs_repository.dart';
import '../../pichangas/data/pichangas_repository.dart';

final myClubsForCreateProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => ref.watch(clubsRepositoryProvider).listClubs(scope: 'mine'),
    );

class CreatePichangaScreen extends ConsumerStatefulWidget {
  const CreatePichangaScreen({
    this.clubId,
    this.initialFieldId,
    this.initialAddress,
    super.key,
  });

  final int? clubId;
  final int? initialFieldId;
  final String? initialAddress;

  @override
  ConsumerState<CreatePichangaScreen> createState() =>
      _CreatePichangaScreenState();
}

class _CreatePichangaScreenState extends ConsumerState<CreatePichangaScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _fieldIdController = TextEditingController();
  final _canchaIdController = TextEditingController();

  DateTime _startsAt = DateTime.now().add(const Duration(days: 1));
  String _matchFormat = 'versus';
  int _playersPerTeam = 7;
  int _durationMinutes = 90;
  String _confirmationMode = 'auto_by_capacity';
  bool _isOpen = false;
  int _notifyDegree = 1;
  bool _allowExternal = true;
  bool _autoReminderEnabled = true;
  String? _audienceSex;
  int? _ageMin;
  int? _ageMax;

  int? _clubId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _clubId = widget.clubId;
    _addressController.text = widget.initialAddress ?? '';
    if (widget.initialFieldId != null) {
      _titleController.text = 'Pichanga en la cancha';
    }
    if (widget.initialFieldId != null) {
      _fieldIdController.text = widget.initialFieldId.toString();
    }
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    ),
  );

  Widget _selectedFieldCard(BuildContext context) {
    final address = _addressController.text.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_soccer,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancha seleccionada',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  address.isEmpty ? 'Polideportivo seleccionado' : address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF0A9A4A)),
        ],
      ),
    );
  }

  Widget _venueFields() => Column(
    children: [
      TextField(
        controller: _canchaIdController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Cancha seleccionada',
          hintText: 'Ingresa el identificador de la cancha',
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _addressController,
        decoration: const InputDecoration(labelText: 'Dirección opcional'),
      ),
      const SizedBox(height: 14),
    ],
  );

  Widget _dateTimeCard(BuildContext context) {
    final date = _dateTimeLabel(_startsAt);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _pickDateTime,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha y hora',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(date, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatChoices() {
    const options = [
      ('versus', 'Versus', Icons.people_outline),
      ('triangular', 'Triangular', Icons.change_history_outlined),
      ('cuadrangular', 'Cuadrangular', Icons.grid_view_outlined),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (option) => ChoiceChip(
              avatar: Icon(option.$3, size: 17),
              label: Text(option.$2),
              selected: _matchFormat == option.$1,
              onSelected: (_) => setState(() => _matchFormat = option.$1),
            ),
          )
          .toList(),
    );
  }

  Widget _durationChoices() {
    const presets = [(60, '1 hora'), (90, '1 h 30 min'), (120, '2 horas')];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...presets.map(
          (preset) => ChoiceChip(
            label: Text(preset.$2),
            selected: _durationMinutes == preset.$1,
            onSelected: (_) => setState(() => _durationMinutes = preset.$1),
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.tune, size: 17),
          label: Text(
            _durationMinutes == 60 ||
                    _durationMinutes == 90 ||
                    _durationMinutes == 120
                ? 'Personalizar'
                : _durationLabel(_durationMinutes),
          ),
          onPressed: _pickCustomDuration,
        ),
      ],
    );
  }

  Widget _switchOption(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile.adaptive(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    secondary: Icon(icon),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    value: value,
    onChanged: onChanged,
  );

  Widget _advancedOptions() => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      leading: const Icon(Icons.tune_outlined),
      title: const Text('Más opciones de convocatoria'),
      subtitle: const Text('Avisos, recordatorios y filtros'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _switchOption(
          Icons.notifications_active_outlined,
          'Avisos automáticos',
          'Envía recordatorios a las 48 y 24 horas',
          _autoReminderEnabled,
          (value) => setState(() => _autoReminderEnabled = value),
        ),
        DropdownButtonFormField<int>(
          initialValue: _notifyDegree,
          decoration: const InputDecoration(
            labelText: 'Alcance de notificación',
          ),
          items: const [
            DropdownMenuItem(value: 1, child: Text('1er grado')),
            DropdownMenuItem(value: 2, child: Text('2do grado')),
            DropdownMenuItem(value: 3, child: Text('3er grado')),
          ],
          onChanged: (value) => setState(() => _notifyDegree = value ?? 1),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String?>(
          initialValue: _audienceSex,
          decoration: const InputDecoration(labelText: 'Convocatoria por sexo'),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('Todos')),
            DropdownMenuItem<String?>(value: 'M', child: Text('Hombres')),
            DropdownMenuItem<String?>(value: 'F', child: Text('Mujeres')),
          ],
          onChanged: (value) => setState(() => _audienceSex = value),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Edad mínima'),
                onChanged: (value) => _ageMin = int.tryParse(value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Edad máxima'),
                onChanged: (value) => _ageMax = int.tryParse(value),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _pickCustomDuration() async {
    var selected = _durationMinutes.clamp(30, 600);
    selected -= selected % 5;
    final value = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Duración personalizada',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Minutos'),
                items: List.generate(115, (index) => 30 + index * 5)
                    .map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text(_durationLabel(minutes)),
                      ),
                    )
                    .toList(),
                onChanged: (minutes) => selected = minutes ?? selected,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: const Text('Usar duración'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (value != null && mounted) setState(() => _durationMinutes = value);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _fieldIdController.dispose();
    _canchaIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(myClubsForCreateProvider);

    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Crear pichanga')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
          children: [
            _sectionTitle(context, '1. Dónde y con quién'),
            if (widget.initialFieldId != null) ...[
              _selectedFieldCard(context),
              const SizedBox(height: 14),
            ] else
              _venueFields(),
            clubsAsync.when(
              data: (clubs) {
                if (_clubId == null && clubs.isNotEmpty) {
                  _clubId = int.tryParse(clubs.first['id'].toString());
                }
                return DropdownButtonFormField<int>(
                  initialValue: _clubId,
                  decoration: const InputDecoration(labelText: 'Grupo'),
                  items: clubs
                      .map(
                        (club) => DropdownMenuItem<int>(
                          value: int.tryParse(club['id'].toString()),
                          child: Text((club['nombre'] ?? '').toString()),
                        ),
                      )
                      .toList(),
                  onChanged: widget.clubId != null
                      ? null
                      : (value) => setState(() => _clubId = value),
                );
              },
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) => Text('No se pudo cargar grupos: $error'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ej. Pichanga de los jueves',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción opcional',
                hintText: 'Indica el nivel, reglas o información útil',
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '2. Partido'),
            _dateTimeCard(context),
            const SizedBox(height: 14),
            Text(
              'Formato',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _formatChoices(),
            const SizedBox(height: 14),
            Text(
              'Jugadores por equipo',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: List.generate(7, (index) => index + 5)
                  .map(
                    (value) => ChoiceChip(
                      label: Text('$value'),
                      selected: _playersPerTeam == value,
                      onSelected: (_) =>
                          setState(() => _playersPerTeam = value),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.groups_2_outlined, color: colors.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${_calculatedCapacity()} cupos · ${_formatText()}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Duración',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _durationChoices(),
            const SizedBox(height: 24),
            _sectionTitle(context, '3. Convocatoria'),
            DropdownButtonFormField<String>(
              initialValue: _confirmationMode,
              decoration: const InputDecoration(labelText: 'Confirmación'),
              items: const [
                DropdownMenuItem(
                  value: 'auto_by_capacity',
                  child: Text('Auto por aforo'),
                ),
                DropdownMenuItem(
                  value: 'manual_paid',
                  child: Text('Manual (pagada)'),
                ),
              ],
              onChanged: (value) => setState(
                () => _confirmationMode = value ?? _confirmationMode,
              ),
            ),
            const SizedBox(height: 10),
            _switchOption(
              Icons.public_outlined,
              'Pichanga abierta',
              'Puede descubrirse desde el mapa',
              _isOpen,
              (value) => setState(() => _isOpen = value),
            ),
            _switchOption(
              Icons.group_add_outlined,
              'Solicitudes externas',
              'Permite participar a jugadores fuera del grupo',
              _allowExternal,
              (value) => setState(() => _allowExternal = value),
            ),
            const SizedBox(height: 8),
            _advancedOptions(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sports_soccer),
            label: Text(
              _saving
                  ? 'Creando…'
                  : 'Crear pichanga · ${_durationLabel(_durationMinutes)}',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null) {
      return;
    }

    setState(
      () => _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (_clubId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un grupo.')));
      return;
    }

    final capacity = _calculatedCapacity();
    final duration = _durationMinutes;

    if (capacity < 2 || duration < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cupos o duración inválidos.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'field_id': int.tryParse(_fieldIdController.text.trim()),
        'cancha_id': int.tryParse(_canchaIdController.text.trim()),
        'address': _addressController.text.trim(),
        'starts_at': _startsAt.toIso8601String(),
        'duration_minutes': duration,
        'match_format': _matchFormat,
        'players_per_team': _playersPerTeam,
        'capacity': capacity,
        'confirmation_mode': _confirmationMode,
        'is_open': _isOpen,
        'notify_degree': _notifyDegree,
        'allow_external_requests': _allowExternal,
        'auto_reminder_enabled': _autoReminderEnabled,
        'audience_sex': _audienceSex,
        'audience_age_min': _ageMin,
        'audience_age_max': _ageMax,
      };

      await ref.read(pichangasRepositoryProvider).create(_clubId!, payload);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pichanga creada.')));
      }
    } on ApiError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  int _calculatedCapacity() =>
      _teamCountForFormat(_matchFormat) * _playersPerTeam;

  int _teamCountForFormat(String format) {
    switch (format) {
      case 'triangular':
        return 3;
      case 'cuadrangular':
        return 4;
      default:
        return 2;
    }
  }

  String _formatText() {
    final teamCount = _teamCountForFormat(_matchFormat);
    return List.generate(teamCount, (_) => '$_playersPerTeam').join(' vs ');
  }

  String _durationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$minutes min';
    if (remainder == 0) return hours == 1 ? '1 hora' : '$hours horas';
    return '$hours h $remainder min';
  }

  String _dateTimeLabel(DateTime value) {
    const weekdays = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${weekdays[value.weekday - 1]} ${value.day} de ${months[value.month - 1]} · $hour:$minute';
  }
}
