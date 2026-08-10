import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../clubs/data/clubs_repository.dart';
import '../../fields/data/fields_repository.dart';
import '../../fields/domain/field_model.dart';
import '../data/pichangas_repository.dart';

final myClubsForCreateProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) => ref.watch(clubsRepositoryProvider).listClubs(scope: 'mine'),
    );

final createPichangaFieldProvider = FutureProvider.autoDispose
    .family<FieldModel, int>(
      (ref, fieldId) => ref.watch(fieldsRepositoryProvider).detail(fieldId),
    );

final createPichangaFieldSearchProvider = FutureProvider.autoDispose
    .family<List<FieldModel>, String>((ref, query) {
      final clean = query.trim();
      if (clean.length < 2) return Future.value(const []);
      return ref.watch(fieldsRepositoryProvider).list(q: clean, limit: 20);
    });

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
  final _fieldSearchController = TextEditingController();

  late DateTime _startsAt;
  String _matchFormat = 'versus';
  int _playersPerTeam = 7;
  int _durationMinutes = 60;
  String _confirmationMode = 'auto_by_capacity';
  bool _isOpen = false;
  bool _includeDescription = false;
  int _notifyDegree = 1;
  bool _allowExternal = true;
  bool _autoReminderEnabled = true;
  String? _audienceSex;
  int? _ageMin;
  int? _ageMax;
  int? _clubId;
  int? _fieldId;
  int? _courtId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _clubId = widget.clubId;
    _fieldId = widget.initialFieldId;
    _startsAt = _nextHalfHour(DateTime.now());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fieldSearchController.dispose();
    super.dispose();
  }

  DateTime _nextHalfHour(DateTime now) {
    final base = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final add = now.minute < 30 ? 30 - now.minute : 60 - now.minute;
    return base.add(Duration(minutes: add));
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

  Future<void> _pickCustomDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null || !mounted) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final rounded = selected.add(
      Duration(minutes: (30 - selected.minute % 30) % 30),
    );
    setState(() => _startsAt = rounded);
  }

  Widget _dateTimeSelector(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 19,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _dateLabel(_startsAt),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                key: const Key('custom_datetime_button'),
                onPressed: _pickCustomDateTime,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Personalizar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: const Key('start_hour_selector'),
                  initialValue: _startsAt.hour,
                  decoration: const InputDecoration(
                    labelText: 'Hora',
                    isDense: true,
                  ),
                  items: List.generate(
                    24,
                    (hour) => DropdownMenuItem(
                      value: hour,
                      child: Text(hour.toString().padLeft(2, '0')),
                    ),
                  ),
                  onChanged: (hour) => setState(
                    () => _startsAt = DateTime(
                      _startsAt.year,
                      _startsAt.month,
                      _startsAt.day,
                      hour ?? _startsAt.hour,
                      _startsAt.minute,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 7),
                child: Text(':', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: const Key('start_minute_selector'),
                  initialValue: _startsAt.minute,
                  decoration: const InputDecoration(
                    labelText: 'Minutos',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('00')),
                    DropdownMenuItem(value: 30, child: Text('30')),
                  ],
                  onChanged: (minute) => setState(
                    () => _startsAt = DateTime(
                      _startsAt.year,
                      _startsAt.month,
                      _startsAt.day,
                      _startsAt.hour,
                      minute ?? _startsAt.minute,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupSelector(List<Map<String, dynamic>> clubs) {
    final selectable = clubs.where(_canSelectClub).toList();
    final restricted = clubs.where((club) => !_canSelectClub(club)).toList();
    if (_clubId == null && selectable.isNotEmpty) {
      _clubId = _asInt(selectable.first['id']);
    }
    final selected = clubs.cast<Map<String, dynamic>?>().firstWhere(
      (club) => _asInt(club?['id']) == _clubId,
      orElse: () => null,
    );

    return _PickerField(
      key: const Key('group_picker'),
      label: 'Grupo',
      enabled: widget.clubId == null,
      onTap: widget.clubId != null
          ? null
          : () => _showGroupPicker(selectable, restricted),
      child: selected == null
          ? const Text('Selecciona un grupo')
          : _ClubRow(club: selected, compact: true),
    );
  }

  bool _canSelectClub(Map<String, dynamic> club) {
    if (club['is_active'] == false) return false;
    final role = club['my_role']?.toString();
    return role == 'admin' || club['pichanga_create_scope'] == 'members';
  }

  Future<void> _showGroupPicker(
    List<Map<String, dynamic>> selectable,
    List<Map<String, dynamic>> restricted,
  ) async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Selecciona un grupo',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            const _PickerSectionTitle('Puedes crear pichangas'),
            ...selectable.map(
              (club) => _ClubPickerTile(
                club: club,
                onTap: () => Navigator.of(context).pop(_asInt(club['id'])),
              ),
            ),
            if (restricted.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _PickerSectionTitle('Solo administradores'),
              ...restricted.map((club) => _ClubPickerTile(club: club)),
            ],
          ],
        ),
      ),
    );
    if (chosen != null && mounted) setState(() => _clubId = chosen);
  }

  Widget _venueSelector(BuildContext context) {
    if (_fieldId == null) {
      final query = _fieldSearchController.text.trim();
      final results = query.length >= 2
          ? ref.watch(createPichangaFieldSearchProvider(query))
          : null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('field_search'),
            controller: _fieldSearchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Busca una cancha o polideportivo',
              hintText: 'Ej. Complejo Lince',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          if (query.length < 2)
            const Text('Escribe al menos 2 letras para buscar.'),
          if (results != null)
            results.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) => Text('No se pudo buscar: $error'),
              data: (fields) => fields.isEmpty
                  ? const Text(
                      'No encontramos polideportivos con esa búsqueda.',
                    )
                  : Column(
                      children: fields
                          .map(
                            (field) => ListTile(
                              key: Key('field_result_${field.id}'),
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                child: Icon(Icons.location_on_outlined),
                              ),
                              title: Text(field.nombre),
                              subtitle: Text(
                                field.direccion ??
                                    '${field.canchasCount} canchas',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => setState(() {
                                _fieldId = field.id;
                                _courtId = null;
                              }),
                            ),
                          )
                          .toList(),
                    ),
            ),
        ],
      );
    }

    final fieldAsync = ref.watch(createPichangaFieldProvider(_fieldId!));
    return fieldAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No se pudo cargar las canchas: $error'),
          TextButton(
            onPressed: () => setState(() {
              _fieldId = null;
              _courtId = null;
            }),
            child: const Text('Buscar otro polideportivo'),
          ),
        ],
      ),
      data: (field) => _courtSelection(context, field),
    );
  }

  Widget _courtSelection(BuildContext context, FieldModel field) {
    final selectedCourt = field.canchas.cast<FieldCourtModel?>().firstWhere(
      (court) => court?.id == _courtId,
      orElse: () => null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PickerField(
          label: 'Polideportivo',
          onTap: widget.initialFieldId == null
              ? () => setState(() {
                  _fieldId = null;
                  _courtId = null;
                })
              : null,
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(field.nombre, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Elige una cancha',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        if (field.canchas.isEmpty)
          const Text('Este polideportivo aún no tiene canchas registradas.')
        else
          ...field.canchas.map(
            (court) => _CourtTile(
              court: court,
              selected: selectedCourt?.id == court.id,
              onTap: () => setState(() => _courtId = court.id),
            ),
          ),
      ],
    );
  }

  Widget _compactChoiceRow({
    required String title,
    required List<Widget> children,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Row(children: children),
    ],
  );

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

  Widget _compactSegment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Key? key,
  }) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            key: key,
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

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
            _venueSelector(context),
            const SizedBox(height: 14),
            clubsAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) => Text('No se pudo cargar grupos: $error'),
              data: _groupSelector,
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
            _switchOption(
              Icons.notes_outlined,
              'Añadir descripción',
              'Incluye reglas o información adicional',
              _includeDescription,
              (value) => setState(() => _includeDescription = value),
            ),
            if (_includeDescription) ...[
              const SizedBox(height: 4),
              TextField(
                key: const Key('description_textarea'),
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Indica el nivel, reglas o información útil',
                ),
                minLines: 2,
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 24),
            _sectionTitle(context, '2. Partido'),
            _dateTimeSelector(context),
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
            _compactChoiceRow(
              title: 'Jugadores por equipo',
              children: List.generate(7, (index) {
                final value = index + 5;
                return _compactSegment(
                  key: Key('players_$value'),
                  label: '$value',
                  selected: _playersPerTeam == value,
                  onTap: () => setState(() => _playersPerTeam = value),
                );
              }),
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
            _compactChoiceRow(
              title: 'Duración',
              children: [
                _compactSegment(
                  label: '1 hora',
                  selected: _durationMinutes == 60,
                  onTap: () => setState(() => _durationMinutes = 60),
                ),
                _compactSegment(
                  label: '1 h 30',
                  selected: _durationMinutes == 90,
                  onTap: () => setState(() => _durationMinutes = 90),
                ),
                _compactSegment(
                  label: '2 horas',
                  selected: _durationMinutes == 120,
                  onTap: () => setState(() => _durationMinutes = 120),
                ),
                _compactSegment(
                  key: const Key('custom_duration_button'),
                  label:
                      _durationMinutes == 60 ||
                          _durationMinutes == 90 ||
                          _durationMinutes == 120
                      ? 'Personalizar'
                      : _durationLabel(_durationMinutes),
                  selected: ![60, 90, 120].contains(_durationMinutes),
                  onTap: _pickCustomDuration,
                ),
              ],
            ),
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

  Future<void> _save() async {
    if (_clubId == null) {
      _showMessage('Selecciona un grupo.');
      return;
    }
    if (_fieldId == null || _courtId == null) {
      _showMessage('Selecciona un polideportivo y una cancha.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(pichangasRepositoryProvider).create(_clubId!, {
        'title': _titleController.text.trim(),
        'description': _includeDescription
            ? _descriptionController.text.trim()
            : '',
        'field_id': _fieldId,
        'cancha_id': _courtId,
        'starts_at': _startsAt.toIso8601String(),
        'duration_minutes': _durationMinutes,
        'match_format': _matchFormat,
        'players_per_team': _playersPerTeam,
        'capacity': _calculatedCapacity(),
        'confirmation_mode': _confirmationMode,
        'is_open': _isOpen,
        'notify_degree': _notifyDegree,
        'allow_external_requests': _allowExternal,
        'auto_reminder_enabled': _autoReminderEnabled,
        'audience_sex': _audienceSex,
        'audience_age_min': _ageMin,
        'audience_age_max': _ageMax,
      });
      if (mounted) {
        Navigator.of(context).pop(true);
        _showMessage('Pichanga creada.');
      }
    } on ApiError catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Error: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  int _calculatedCapacity() =>
      _teamCountForFormat(_matchFormat) * _playersPerTeam;

  int _teamCountForFormat(String format) => switch (format) {
    'triangular' => 3,
    'cuadrangular' => 4,
    _ => 2,
  };

  String _formatText() => List.generate(
    _teamCountForFormat(_matchFormat),
    (_) => '$_playersPerTeam',
  ).join(' vs ');

  String _durationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$minutes min';
    if (remainder == 0) return hours == 1 ? '1 hora' : '$hours horas';
    return '$hours h $remainder min';
  }

  String _dateLabel(DateTime date) {
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return isToday ? 'Hoy · $day/$month' : '$day/$month/${date.year}';
  }
}

int? _asInt(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.child,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: enabled && onTap != null,
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 2),
                    child,
                  ],
                ),
              ),
              if (enabled && onTap != null) const Icon(Icons.expand_more),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PickerSectionTitle extends StatelessWidget {
  const _PickerSectionTitle(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _ClubAvatar extends StatelessWidget {
  const _ClubAvatar({required this.club, this.radius = 21});
  final Map<String, dynamic> club;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = resolveClubImageUrl(
      club['logo_url']?.toString(),
      AppConfig.fromEnvironment(),
    );
    return CircleAvatar(
      radius: radius,
      backgroundImage: url == null ? null : NetworkImage(url),
      child: url == null ? const Icon(Icons.sports_soccer_outlined) : null,
    );
  }
}

class _ClubRow extends StatelessWidget {
  const _ClubRow({required this.club, this.compact = false});
  final Map<String, dynamic> club;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ClubAvatar(club: club, radius: compact ? 15 : 21),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            (club['nombre'] ?? '').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: compact ? FontWeight.w700 : FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClubPickerTile extends StatelessWidget {
  const _ClubPickerTile({required this.club, this.onTap});
  final Map<String, dynamic> club;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    key: Key('club_option_${club['id']}'),
    contentPadding: EdgeInsets.zero,
    enabled: onTap != null,
    leading: _ClubAvatar(club: club),
    title: Text((club['nombre'] ?? '').toString()),
    subtitle: onTap == null ? const Text('Solo administradores') : null,
    trailing: onTap == null
        ? const Icon(Icons.lock_outline)
        : const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class _CourtTile extends StatelessWidget {
  const _CourtTile({
    required this.court,
    required this.selected,
    required this.onTap,
  });
  final FieldCourtModel court;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 7),
    child: InkWell(
      key: Key('court_option_${court.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: court.urlFoto == null
                    ? const ColoredBox(
                        color: Colors.transparent,
                        child: Icon(Icons.sports_soccer_outlined),
                      )
                    : Image.network(court.urlFoto!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court.nombre ?? 'Cancha',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if ((court.vsFormat ?? court.surfaceType) != null)
                    Text(
                      [court.vsFormat, court.surfaceType]
                          .whereType<String>()
                          .where((value) => value.isNotEmpty)
                          .join(' · '),
                    ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? Theme.of(context).colorScheme.primary : null,
            ),
          ],
        ),
      ),
    ),
  );
}
