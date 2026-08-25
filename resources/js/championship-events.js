const EVENT_TYPES = {
  goal: { label: 'Gol' },
  own_goal: { label: 'Autogol' },
  assist: { label: 'Asistencia' },
  yellow_card: { label: 'Tarjeta amarilla' },
  red_card: { label: 'Tarjeta roja' },
  substitution_in: { label: 'Cambio · entra' },
  substitution_out: { label: 'Cambio · sale' },
};

const SCORING_TYPES = ['goal', 'own_goal'];
const PLAYER_REQUIRED_TYPES = ['assist', 'yellow_card', 'red_card', 'substitution_in', 'substitution_out'];

const parseJson = (value, fallback) => {
  try {
    const normalized = String(value || '').replaceAll('&quot;', '"').replaceAll('&#039;', "'");
    return JSON.parse(normalized);
  } catch (_) {
    return fallback;
  }
};

const asList = (value) => {
  if (Array.isArray(value)) return value;
  if (value && typeof value === 'object') return Object.values(value);
  return [];
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
  const form = editor.closest('form');
  const list = editor.querySelector('[data-events-list]');
  const empty = editor.querySelector('[data-events-empty]');
  const summary = editor.querySelector('[data-events-summary]');
  const hiddenJson = editor.querySelector('[data-events-json]');
  const jsonEditor = editor.querySelector('[data-json-editor]');
  const jsonError = editor.querySelector('[data-json-error]');
  const eventsError = editor.querySelector('[data-events-error]');
  const homeScore = form.querySelector('[name="home_score"]');
  const awayScore = form.querySelector('[name="away_score"]');
  let scoreError = '';
  const teams = asList(parseJson(editor.dataset.eventTeams, []));
  const membersByTeam = parseJson(editor.dataset.eventMembers, {});
  const seed = asList(parseJson(editor.dataset.eventSeed, []));
  const teamOptions = teams.map((team) => ({ value: team.id, label: team.name }));
  const homeTeamId = teamOptions[0]?.value ? String(teamOptions[0].value) : '';
  const awayTeamId = teamOptions[1]?.value ? String(teamOptions[1].value) : '';
  const allowedTypes = Object.keys(EVENT_TYPES);

  function memberOptions(teamId) {
    return asList(membersByTeam[String(teamId)] || []).map((user) => ({
      value: user.id,
      label: labelForUser(user),
    }));
  }

  function ensureOption(select, value, label) {
    if (!value || Array.from(select.options).some((option) => option.value === String(value))) return;
    const option = document.createElement('option');
    option.value = String(value);
    option.textContent = label || `Jugador #${value} (ya no está disponible)`;
    option.dataset.unavailable = 'true';
    select.appendChild(option);
  }

  function setPlayers(select, teamId, selectedId, optional = true) {
    const options = memberOptions(teamId);
    select.replaceChildren();
    const placeholder = document.createElement('option');
    placeholder.value = '';
    placeholder.textContent = options.length ? `Selecciona jugador${optional ? ' (opcional)' : ''}` : 'Sin miembros aprobados';
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

  function rowValues(row) {
    const get = (name) => row.querySelector(`[data-event-field="${name}"]`);
    const minuteValue = get('minute').value.trim();
    return {
      event_type: get('event_type').value,
      championship_team_id: integerOrNull(get('championship_team_id').value),
      player_user_id: integerOrNull(get('player_user_id').value),
      secondary_player_user_id: integerOrNull(get('secondary_player_user_id').value),
      minute: minuteValue === '' ? null : Number.parseInt(minuteValue, 10),
      placeholder: row.dataset.placeholderGoal === 'true',
    };
  }

  function hasDetails(event) {
    return Boolean(event.player_user_id || event.secondary_player_user_id || event.minute !== null);
  }

  function scoringSide(event) {
    if (!SCORING_TYPES.includes(event.event_type) || !event.championship_team_id) return null;
    if (event.event_type === 'goal') return String(event.championship_team_id);
    if (String(event.championship_team_id) === homeTeamId) return awayTeamId;
    if (String(event.championship_team_id) === awayTeamId) return homeTeamId;
    return null;
  }

  function updateSecondary(row) {
    const type = row.querySelector('[data-event-field="event_type"]').value;
    const secondaryField = row.querySelector('.admin-event-secondary');
    const secondary = row.querySelector('[data-event-field="secondary_player_user_id"]');
    const isGoal = type === 'goal';
    secondaryField.classList.toggle('d-none', !isGoal);
    secondary.disabled = !isGoal;
    if (!isGoal) secondary.value = '';
    const player = row.querySelector('[data-event-field="player_user_id"]');
    const playerPlaceholder = player?.options[0];
    if (playerPlaceholder && memberOptions(row.querySelector('[data-event-field="championship_team_id"]').value).length) {
      playerPlaceholder.textContent = `Selecciona jugador${PLAYER_REQUIRED_TYPES.includes(type) ? '' : ' (opcional)'}`;
    }
  }

  function createRow(event = {}, defaultTeamId = '') {
    const row = document.createElement('div');
    row.className = 'admin-event-row';
    row.dataset.eventRow = 'true';
    const eventType = allowedTypes.includes(event.event_type) ? event.event_type : 'goal';
    const teamId = event.championship_team_id ? String(event.championship_team_id) : defaultTeamId;
    const placeholder = event.placeholder ?? (!hasDetails(event) && SCORING_TYPES.includes(eventType));
    row.dataset.placeholderGoal = placeholder && SCORING_TYPES.includes(eventType) ? 'true' : 'false';

    const type = createSelect(Object.entries(EVENT_TYPES).map(([value, item]) => ({ value, label: item.label })), 'Selecciona evento');
    type.dataset.eventField = 'event_type';
    type.value = eventType;

    const team = createSelect(teamOptions, 'Selecciona equipo');
    team.dataset.eventField = 'championship_team_id';
    team.value = teamId;

    const player = createSelect([], 'Selecciona jugador (opcional)');
    player.dataset.eventField = 'player_user_id';
    setPlayers(player, team.value, event.player_user_id, !PLAYER_REQUIRED_TYPES.includes(eventType));

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
      row.dataset.placeholderGoal = 'false';
      setPlayers(player, team.value, null, !PLAYER_REQUIRED_TYPES.includes(type.value));
      setPlayers(secondary, team.value, null);
      syncFromRows();
    });
    type.addEventListener('change', () => {
      row.dataset.placeholderGoal = 'false';
      updateSecondary(row);
      syncFromRows();
    });
    [player, secondary, minute].forEach((field) => field.addEventListener('change', () => {
      row.dataset.placeholderGoal = 'false';
      syncFromRows();
    }));
    remove.addEventListener('click', () => {
      row.remove();
      syncFromRows();
    });
    updateSecondary(row);
    return row;
  }

  function allRows() {
    return Array.from(list.querySelectorAll('[data-event-row]'));
  }

  function renderRows(events) {
    list.replaceChildren();
    events.forEach((event) => list.appendChild(createRow(event)));
    empty.classList.toggle('d-none', events.length > 0);
  }

  function setError(element, message) {
    element.textContent = message || '';
    element.classList.toggle('d-none', !message);
  }

  function scoringCounts() {
    const counts = { [homeTeamId]: 0, [awayTeamId]: 0 };
    allRows().map(rowValues).forEach((event) => {
      const side = scoringSide(event);
      if (side && Object.prototype.hasOwnProperty.call(counts, side)) counts[side] += 1;
    });
    return counts;
  }

  function scores() {
    return {
      home: Math.max(0, Number.parseInt(homeScore.value, 10) || 0),
      away: Math.max(0, Number.parseInt(awayScore.value, 10) || 0),
    };
  }

  function setScores(counts) {
    homeScore.value = String(counts[homeTeamId] || 0);
    awayScore.value = String(counts[awayTeamId] || 0);
  }

  function addGoalPlaceholders(target, current) {
    const missing = Math.max(0, target - current);
    for (let index = 0; index < missing; index += 1) {
      const row = createRow({ event_type: 'goal', placeholder: true }, target === current ? homeTeamId : '');
      row.querySelector('[data-event-field="championship_team_id"]').value = target === current ? homeTeamId : awayTeamId;
      const team = row.querySelector('[data-event-field="championship_team_id"]');
      const player = row.querySelector('[data-event-field="player_user_id"]');
      const secondary = row.querySelector('[data-event-field="secondary_player_user_id"]');
      setPlayers(player, team.value, null);
      setPlayers(secondary, team.value, null);
      list.appendChild(row);
    }
  }

  function reconcileToScores(target) {
    const counts = scoringCounts();
    const targetBySide = { [homeTeamId]: target.home, [awayTeamId]: target.away };
    const rows = allRows();
    for (const side of [homeTeamId, awayTeamId]) {
      if (!side) continue;
      const detailed = rows.map(rowValues).filter((event) => scoringSide(event) === side && hasDetails(event)).length;
      if (detailed > targetBySide[side]) {
        scoreError = `No puedes reducir el marcador por debajo de los goles detallados del ${side === homeTeamId ? 'local' : 'visitante'}.`;
        setError(eventsError, scoreError);
        setScores(counts);
        return false;
      }
      let removable = rows.filter((row) => {
        const event = rowValues(row);
        return scoringSide(event) === side && !hasDetails(event);
      });
      while (counts[side] > targetBySide[side] && removable.length) {
        removable.pop().remove();
        counts[side] -= 1;
      }
      if (counts[side] < targetBySide[side]) {
        const missing = targetBySide[side] - counts[side];
        for (let index = 0; index < missing; index += 1) {
          list.appendChild(createRow({ event_type: 'goal', placeholder: true }, side));
        }
      }
    }
    setScores(targetBySide);
    scoreError = '';
    setError(eventsError, '');
    return true;
  }

  function serialize() {
    const events = [];
    const errors = [];
    allRows().forEach((row, index) => {
      row.classList.remove('admin-event-row-error');
      const event = rowValues(row);
      const rowErrors = [];
      if (!allowedTypes.includes(event.event_type)) rowErrors.push('elige un tipo');
      if (SCORING_TYPES.includes(event.event_type) && !event.championship_team_id) rowErrors.push('elige un equipo');
      if (!SCORING_TYPES.includes(event.event_type) && (!event.championship_team_id || !event.player_user_id)) rowErrors.push('elige equipo y jugador');
      if (event.minute !== null && (!Number.isInteger(event.minute) || event.minute < 0 || event.minute > 200)) rowErrors.push('usa un minuto entre 0 y 200');
      if (event.event_type !== 'goal' && event.secondary_player_user_id) rowErrors.push('la asistencia solo aplica a un gol');
      if (rowErrors.length) {
        row.classList.add('admin-event-row-error');
        errors.push(`Evento ${index + 1}: ${rowErrors.join(', ')}.`);
        return;
      }
      events.push({
        event_type: event.event_type,
        championship_team_id: event.championship_team_id,
        player_user_id: event.player_user_id,
        secondary_player_user_id: event.event_type === 'goal' ? event.secondary_player_user_id : null,
        minute: event.minute,
      });
    });
    return { events, errors };
  }

  function renderSummary(events) {
    const counts = scoringCounts();
    const counters = [
      ['⚽', `${counts[homeTeamId] || 0} local · ${counts[awayTeamId] || 0} visitante`],
      ['🟨', `${events.filter((event) => event.event_type === 'yellow_card').length} amarillas`],
      ['🟥', `${events.filter((event) => event.event_type === 'red_card').length} rojas`],
      ['↔', `${events.filter((event) => event.event_type === 'substitution_in').length} cambios`],
    ];
    summary.replaceChildren();
    counters.forEach(([icon, label]) => {
      const badge = document.createElement('span');
      badge.className = 'admin-event-summary-badge';
      badge.textContent = `${icon} ${label}`;
      summary.appendChild(badge);
    });
  }

  function syncFromRows() {
    const result = serialize();
    const counts = scoringCounts();
    if (allRows().some((row) => SCORING_TYPES.includes(rowValues(row).event_type))) setScores(counts);
    renderSummary(result.events);
    if (!result.errors.length) {
      hiddenJson.value = JSON.stringify(result.events);
      jsonEditor.value = JSON.stringify(result.events, null, 2);
    }
    setError(eventsError, result.errors.join(' ') || scoreError);
    return result;
  }

  function defaultGoalSide() {
    const current = scores();
    return current.home <= current.away ? homeTeamId : awayTeamId;
  }

  editor.querySelector('[data-add-event]').addEventListener('click', () => {
    list.appendChild(createRow({ event_type: 'goal', placeholder: true }, defaultGoalSide()));
    empty.classList.add('d-none');
    syncFromRows();
    list.lastElementChild?.querySelector('[data-event-field="event_type"]')?.focus();
  });

  [homeScore, awayScore].forEach((input) => input.addEventListener('change', () => {
    reconcileToScores(scores());
    syncFromRows();
  }));

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
    syncFromRows();
    jsonEditor.readOnly = true;
    editor.querySelector('[data-toggle-json]').textContent = 'Editar JSON';
    editor.querySelector('[data-apply-json]').classList.add('d-none');
  });

  form.addEventListener('submit', (event) => {
    const result = syncFromRows();
    const counts = scoringCounts();
    const current = scores();
    if (counts[homeTeamId] !== current.home || counts[awayTeamId] !== current.away) {
      setError(eventsError, 'El marcador debe coincidir con los goles registrados.');
      event.preventDefault();
    } else if (result.errors.length) {
      event.preventDefault();
      editor.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  });

  const initialScores = scores();
  renderRows(seed);
  const seededScoring = seed.filter((event) => SCORING_TYPES.includes(event.event_type));
  const seededTeamsComplete = seededScoring.every((event) => event.championship_team_id);
  if (!seededScoring.length || !seededTeamsComplete) {
    reconcileToScores(initialScores);
  } else {
    syncFromRows();
  }
  editor.__eventsEditor = { sync: syncFromRows };
}

document.querySelectorAll('[data-events-editor]').forEach(initEventEditor);
