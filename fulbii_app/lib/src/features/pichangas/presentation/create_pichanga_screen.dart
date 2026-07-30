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
  final _durationController = TextEditingController(text: '90');

  DateTime _startsAt = DateTime.now().add(const Duration(days: 1));
  String _matchFormat = 'versus';
  int _playersPerTeam = 7;
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
      _fieldIdController.text = widget.initialFieldId.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _fieldIdController.dispose();
    _canchaIdController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clubsAsync = ref.watch(myClubsForCreateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear pichanga')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            clubsAsync.when(
              data: (clubs) {
                if (_clubId == null && clubs.isNotEmpty) {
                  _clubId = int.tryParse(clubs.first['id'].toString());
                }
                return DropdownButtonFormField<int>(
                  initialValue: _clubId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Grupo',
                  ),
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
                border: OutlineInputBorder(),
                labelText: 'Título',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Descripción',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fieldIdController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'ID cancha',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _canchaIdController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'ID cancha',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Dirección',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _matchFormat,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Formato',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'versus', child: Text('Versus')),
                      DropdownMenuItem(
                        value: 'triangular',
                        child: Text('Triangular'),
                      ),
                      DropdownMenuItem(
                        value: 'cuadrangular',
                        child: Text('Cuadrangular'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _matchFormat = value ?? 'versus'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _playersPerTeam,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Jugadores por equipo',
                    ),
                    items: List.generate(7, (index) => index + 5)
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => _playersPerTeam = value ?? _playersPerTeam,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Cupos: ${_calculatedCapacity()} (${_formatText()})',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Duración (min)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha y hora'),
              subtitle: Text(_startsAt.toString()),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _confirmationMode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Modo confirmación',
              ),
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
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isOpen,
              onChanged: (value) => setState(() => _isOpen = value),
              title: const Text('Pichanga abierta'),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _allowExternal,
              onChanged: (value) => setState(() => _allowExternal = value),
              title: const Text('Permitir solicitudes externas'),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _autoReminderEnabled,
              onChanged: (value) =>
                  setState(() => _autoReminderEnabled = value),
              title: const Text('Activar avisos automáticos 48h/24h'),
            ),
            DropdownButtonFormField<int>(
              initialValue: _notifyDegree,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Grado de notificación',
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1er grado')),
                DropdownMenuItem(value: 2, child: Text('2do grado')),
                DropdownMenuItem(value: 3, child: Text('3er grado')),
              ],
              onChanged: (value) => setState(() => _notifyDegree = value ?? 1),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _audienceSex,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Filtro sexo (opcional)',
              ),
              items: const [
                DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                DropdownMenuItem<String?>(value: 'M', child: Text('Hombres')),
                DropdownMenuItem<String?>(value: 'F', child: Text('Mujeres')),
              ],
              onChanged: (value) => setState(() => _audienceSex = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Edad mínima',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _ageMin = int.tryParse(value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Edad máxima',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _ageMax = int.tryParse(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Crear pichanga'),
            ),
          ],
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
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;

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
}
