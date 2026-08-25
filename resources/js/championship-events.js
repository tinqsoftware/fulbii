const EVENT_TYPES = {
  goal: { label: 'Gol', secondary: true },
  own_goal: { label: 'Autogol' },
  assist: { label: 'Asistencia' },
  yellow_card: { label: 'Tarjeta amarilla' },
  red_card: { label: 'Tarjeta roja' },
  substitution_in: { label: 'Cambio · entra' },
  substitution_out: { label: 'Cambio · sale' },
};

const parseJson = (value, fallback) => {
  try {
    return JSON.parse(value || '');
  } catch (_) {
    return fallback;
  }
};

const integerOrNull = (value) => {
  const number = Number.parseInt(value, 10);
  return Number.isFinite(number) && number > 0 ? number : null;
};

const labelForUser = (user) => {
  const nick = user.nick ? `@${user.nick}` : '';
  return nick || user.name || `Jugador #${user.id}`;
};

function createField(label, control, className = '') {
  const wrapper = document.createElement('label');
  wrapper.className = `admin-event-field ${className}`.trim();
  const caption = document.createElement('span');
  caption.className = 'admin-event-field-label';
  caption.textContent = label;
  wrapper.append(caption, control);
  return wrapper;
}

function createSelect(options, placeholder) {
  const select = document.createElement('select');
  select.className = 'form-select form-select-sm';
  if (placeholder) {
    const option = document.createElement('option');
    option.value = '';
    option.textContent = placeholder;
    select.appendChild(option);
  }
  options.forEach((optionData) => {
    const option = document.createElement('option');
    option.value = String(optionData.value);
    option.textContent = optionData.label;
    select.appendChild(option);
  });
  return select;
}

function initEventEditor(editor) {
  const list = editor.querySelector('[data-events-list]');
  const empty = editor.querySelector('[data-events-empty]');
  const summary = editor.querySelector('[data-events-summary]');
  const hiddenJson = editor.querySelector('[data-events-json]');
  const jsonEditor = editor.querySelector('[data-json-editor]');
  const jsonError = editor.querySelector('[data-json-error]');
  const eventsError = editor.querySelector('[data-events-error]');
  const teams = parseJson(editor.dataset.eventTeams, []);
  const membersByTeam = parseJson(editor.dataset.eventMembers, {});
  const seed = parseJson(editor.dataset.eventSeed, []);

  const teamOptions = teams.map((team) => ({ value: team.id, label: team.name }));
  const allowedTypes = Object.keys(EVENT_TYPES);

  function memberOptions(teamId) {
    return (membersByTeam[String(teamId)] || []).map((user) => ({
      value: user.id,
      label: labelForUser(user),
    }));
  }

  function ensureOption(select, value, label) {
    if (!value || [...select.options].some((option) => option.value === String(value))) return;
    const option = document.createElement('option');
    option.value = String(value);
    option.textContent = label || `Jugador #${value} (ya no está disponible)`;
    option.dataset.unavailable = 'true';
    select.appendChild(option);
  }

  function setPlayers(select, teamId, selectedId) {
    const options = memberOptions(teamId);
    select.replaceChildren();
    const placeholder = document.createElement('option');
    placeholder.value = '';
    placeholder.textContent = options.length ? 'Selecciona jugador' : 'Sin miembros aprobados';
    select.appendChild(placeholder);
    options.forEach((optionData) => {
      const option = document.createElement('option');
      option.value = String(optionData.value);
      option.textContent = optionData.label;
      select.appendChild(option);
    });
    ensureOption(select, selectedId);
    select.value = selectedId ? String(selectedId) : '';
  }

  function updateSecondary(row) {
    const type = row.querySelector('[data-event-field="event_type"]').value;
    const secondaryField = row.querySelector('[data-secondary-field]');
    const secondary = row.querySelector('[data-event-field="secondary_player_user_id"]');
    const isGoal = type === 'goal';
    secondaryField.classList.toggle('d-none', !isGoal);
    secondary.disabled = !isGoal;
    if (!isGoal) secondary.value = '';
  }

  function createRow(event = {}) {
    const row = document.createElement('div');
    row.className = 'admin-event-row';
    row.dataset.eventRow = 'true';

    const type = createSelect(Object.entries(EVENT_TYPES).map(([value, item]) => ({ value, label: item.label })), 'Selecciona evento');
    type.dataset.eventField = 'event_type';
    type.value = allowedTypes.includes(event.event_type) ? event.event_type : 'goal';

    const team = createSelect(teamOptions, 'Selecciona equipo');
    team.dataset.eventField = 'championship_team_id';
    team.value = event.championship_team_id ? String(event.championship_team_id) : '';

    const player = createSelect([], 'Selecciona jugador');
    player.dataset.eventField = 'player_user_id';
    setPlayers(player, team.value, event.player_user_id);

    const minute = document.createElement('input');
    minute.type = 'number';
    minute.min = '0';
    minute.max = '200';
    minute.inputMode = 'numeric';
    minute.placeholder = '—';
    minute.className = 'form-control form-control-sm';
    minute.value = event.minute === null || event.minute === undefined ? '' : String(event.minute);
    minute.dataset.eventField = 'minute';

    const secondary = createSelect([], 'Sin asistencia');
    secondary.dataset.eventField = 'secondary_player_user_id';
    setPlayers(secondary, team.value, event.secondary_player_user_id);

    const remove = document.createElement('button');
    remove.type = 'button';
    remove.className = 'btn btn-sm btn-outline-danger admin-event-remove';
    remove.setAttribute('aria-label', 'Eliminar evento');
    remove.textContent = 'Quitar';

    row.append(
      createField('Evento', type, 'admin-event-type'),
      createField('Equipo', team, 'admin-event-team'),
      createField('Jugador', player, 'admin-event-player'),
      createField('Minuto', minute, 'admin-event-minute'),
      createField('Asistencia opcional', secondary, 'admin-event-secondary'),
      remove,
    );

    team.addEventListener('change', () => {
      setPlayers(player, team.value, null);
      setPlayers(secondary, team.value, null);
      sync();
    });
    type.addEventListener('change', () => {
      updateSecondary(row);
      sync();
    });
    [player, secondary, minute].forEach((field) => field.addEventListener('change', sync));
    remove.addEventListener('click', () => {
      row.remove();
      sync();
    });
    updateSecondary(row);
    return row;
  }

  function renderRows(events) {
    list.replaceChildren();
    events.forEach((event) => list.appendChild(createRow(event)));
    empty.classList.toggle('d-none', events.length > 0);
    sync();
  }

  function setError(element, message) {
    element.textContent = message || '';
    element.classList.toggle('d-none', !message);
  }

  function serialize() {
    const rows = [...list.querySelectorAll('[data-event-row]')];
    const events = [];
    const errors = [];
    rows.forEach((row, index) => {
      row.classList.remove('admin-event-row-error');
      const get = (name) => row.querySelector(`[data-event-field="${name}"]`);
      const eventType = get('event_type').value;
      const teamId = integerOrNull(get('championship_team_id').value);
      const playerId = integerOrNull(get('player_user_id').value);
      const secondaryId = integerOrNull(get('secondary_player_user_id').value);
      const minuteValue = get('minute').value.trim();
      const minute = minuteValue === '' ? null : Number.parseInt(minuteValue, 10);
      const rowErrors = [];
      if (!allowedTypes.includes(eventType)) rowErrors.push('elige un tipo');
      if (!teamId) rowErrors.push('elige un equipo');
      if (!playerId) rowErrors.push('elige un jugador');
      if (minute !== null && (!Number.isInteger(minute) || minute < 0 || minute > 200)) rowErrors.push('usa un minuto entre 0 y 200');
      if (eventType !== 'goal' && secondaryId) rowErrors.push('la asistencia solo aplica a un gol');
      if (rowErrors.length) {
        row.classList.add('admin-event-row-error');
        errors.push(`Evento ${index + 1}: ${rowErrors.join(', ')}.`);
        return;
      }
      events.push({
        event_type: eventType,
        championship_team_id: teamId,
        player_user_id: playerId,
        secondary_player_user_id: eventType === 'goal' ? secondaryId : null,
        minute,
      });
    });
    return { events, errors };
  }

  function renderSummary(events) {
    const counters = [
      ['goal', '⚽', 'goles'],
      ['yellow_card', '🟨', 'amarillas'],
      ['red_card', '🟥', 'rojas'],
      ['substitution_in', '↔', 'cambios'],
    ];
    summary.replaceChildren();
    counters.forEach(([type, icon, label]) => {
      const count = events.filter((event) => event.event_type === type).length;
      if (!count) return;
      const badge = document.createElement('span');
      badge.className = 'admin-event-summary-badge';
      badge.textContent = `${icon} ${count} ${label}`;
      summary.appendChild(badge);
    });
    if (!summary.children.length) summary.textContent = 'Sin eventos';
  }

  function sync() {
    const result = serialize();
    renderSummary(result.events);
    if (!result.errors.length) {
      hiddenJson.value = JSON.stringify(result.events);
      jsonEditor.value = JSON.stringify(result.events, null, 2);
    }
    setError(eventsError, result.errors.join(' '));
    return result;
  }

  editor.querySelector('[data-add-event]').addEventListener('click', () => {
    const row = createRow({ event_type: 'goal' });
    list.appendChild(row);
    empty.classList.add('d-none');
    sync();
    row.querySelector('[data-event-field="event_type"]').focus();
  });

  editor.querySelector('[data-toggle-json]').addEventListener('click', (event) => {
    const editing = jsonEditor.readOnly;
    jsonEditor.readOnly = !editing;
    event.currentTarget.textContent = editing ? 'Bloquear edición' : 'Editar JSON';
    editor.querySelector('[data-apply-json]').classList.toggle('d-none', !editing);
    if (editing) jsonEditor.focus();
  });

  editor.querySelector('[data-apply-json]').addEventListener('click', () => {
    const parsed = parseJson(jsonEditor.value, null);
    if (!Array.isArray(parsed)) {
      setError(jsonError, 'El contenido debe ser una lista de eventos JSON.');
      return;
    }
    const invalidType = parsed.find((event) => !event || !allowedTypes.includes(event.event_type));
    if (invalidType) {
      setError(jsonError, 'Hay un tipo de evento no reconocido. Revisa la lista permitida.');
      return;
    }
    setError(jsonError, '');
    renderRows(parsed);
    jsonEditor.readOnly = true;
    editor.querySelector('[data-toggle-json]').textContent = 'Editar JSON';
    editor.querySelector('[data-apply-json]').classList.add('d-none');
  });

  editor.closest('form').addEventListener('submit', (event) => {
    const result = sync();
    if (result.errors.length) {
      event.preventDefault();
      editor.scrollIntoView({ behavior: 'smooth', block: 'center' });
    } else {
      hiddenJson.value = JSON.stringify(result.events);
    }
  });

  renderRows(Array.isArray(seed) ? seed : []);
  editor.__eventsEditor = { sync };
}

document.querySelectorAll('[data-events-editor]').forEach(initEventEditor);
