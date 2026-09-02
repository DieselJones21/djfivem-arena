(() => {
  const IN_GAME = typeof GetParentResourceName === 'function';
  const resourceName = IN_GAME ? GetParentResourceName() : 'cursor_arena';

  const MODES = [
    { id: 'ffa', label: 'FFA' },
    { id: '1v1', label: '1v1' },
    { id: '2v2', label: '2v2' },
    { id: '3v3', label: '3v3' },
    { id: '4v4', label: '4v4' },
    { id: 'tdm', label: 'TDM' },
  ];

  const state = {
    open: false,
    tab: 'join',
    boardMode: 'ffa',
    boardSort: 'wins',
    mode: '1v1',
    mapId: 'construction',
    roomQuery: '',
    playerName: 'Player',
    lobbies: [],
    loadouts: [],
    stats: {},
    leaderboard: { ffa: [], tdm: [], pvp: [], showdown: [] },
    history: [],
    selected: null,
    pick: { loadoutId: null, weaponId: null, team: 1 },
    livePick: { loadoutId: null, weaponId: null },
    hudEndsAt: 0,
  };

  const MOCK = {
    playerName: 'Diesel',
    loadouts: [
      { id: 'duelist', label: 'Duelist', weapons: [
        { id: 'pistol', label: 'Pistol', weapon: 'WEAPON_PISTOL' },
        { id: 'appistol', label: 'AP Pistol', weapon: 'WEAPON_APPISTOL' },
        { id: 'combatpistol', label: 'Combat Pistol', weapon: 'WEAPON_COMBATPISTOL' },
      ]},
      { id: 'raider', label: 'Raider', weapons: [{ id: 'smg', label: 'SMG', weapon: 'WEAPON_SMG' }] },
      { id: 'assault', label: 'Assault', weapons: [{ id: 'carbinerifle', label: 'Carbine Rifle', weapon: 'WEAPON_CARBINERIFLE' }] },
    ],
    lobbies: [
      { id: 'ffa_construction', name: 'FFA', mode: 'ffa', mapId: 'construction', mapName: 'Construction', mapImage: 'assets/map_construction.svg', description: 'Vertical fights.', playerCount: 6, maxPlayers: 16, killsToWin: 30, state: 'active', sizeLabel: 'FFA', players: [{ id: 1, name: 'Diesel', kills: 8, deaths: 2, team: 0 }] },
      { id: 'ffa_cargo', name: 'FFA', mode: 'ffa', mapId: 'cargo', mapName: 'Cargo', mapImage: 'assets/map_warehouse.svg', playerCount: 2, maxPlayers: 16, killsToWin: 30, state: 'waiting', sizeLabel: 'FFA', players: [] },
      { id: 'ffa_dust', name: 'FFA', mode: 'ffa', mapId: 'dust', mapName: 'Dust', mapImage: 'assets/map_docks.svg', playerCount: 9, maxPlayers: 16, killsToWin: 30, state: 'active', sizeLabel: 'FFA', players: [] },
      { id: 'pvp_1v1_construction', name: '1v1', mode: 'pvp', mapId: 'construction', mapName: 'Construction', mapImage: 'assets/map_construction.svg', playerCount: 1, maxPlayers: 2, maxPlayersPerTeam: 1, roundsToWin: 5, state: 'waiting', sizeLabel: '1v1', players: [{ id: 1, name: 'Diesel', kills: 0, deaths: 0, team: 1 }] },
      { id: 'pvp_1v1_cargo', name: '1v1', mode: 'pvp', mapId: 'cargo', mapName: 'Cargo', mapImage: 'assets/map_warehouse.svg', playerCount: 0, maxPlayers: 2, maxPlayersPerTeam: 1, roundsToWin: 5, state: 'idle', sizeLabel: '1v1', players: [] },
      { id: 'pvp_1v1_dust', name: '1v1', mode: 'pvp', mapId: 'dust', mapName: 'Dust', mapImage: 'assets/map_docks.svg', playerCount: 2, maxPlayers: 2, maxPlayersPerTeam: 1, roundsToWin: 5, state: 'active', sizeLabel: '1v1', players: [{ id: 1, name: 'Diesel', team: 1 }, { id: 2, name: 'Nova', team: 2 }] },
      { id: 'pvp_2v2_construction', name: '2v2', mode: 'pvp', mapId: 'construction', mapName: 'Construction', mapImage: 'assets/map_construction.svg', playerCount: 3, maxPlayers: 4, maxPlayersPerTeam: 2, roundsToWin: 4, sizeLabel: '2v2', state: 'waiting', players: [{ id: 1, name: 'Diesel', team: 1 }, { id: 2, name: 'Rook', team: 1 }, { id: 3, name: 'Nova', team: 2 }] },
      { id: 'pvp_2v2_cargo', name: '2v2', mode: 'pvp', mapId: 'cargo', mapName: 'Cargo', mapImage: 'assets/map_warehouse.svg', playerCount: 0, maxPlayers: 4, maxPlayersPerTeam: 2, roundsToWin: 4, sizeLabel: '2v2', state: 'idle', players: [] },
      { id: 'pvp_2v2_dust', name: '2v2', mode: 'pvp', mapId: 'dust', mapName: 'Dust', mapImage: 'assets/map_docks.svg', playerCount: 2, maxPlayers: 4, maxPlayersPerTeam: 2, roundsToWin: 4, sizeLabel: '2v2', state: 'waiting', players: [] },
      { id: 'pvp_3v3_construction', name: '3v3', mode: 'pvp', mapId: 'construction', mapName: 'Construction', mapImage: 'assets/map_construction.svg', playerCount: 0, maxPlayers: 6, maxPlayersPerTeam: 3, roundsToWin: 4, sizeLabel: '3v3', state: 'idle', players: [] },
      { id: 'pvp_3v3_cargo', name: '3v3', mode: 'pvp', mapId: 'cargo', mapName: 'Cargo', mapImage: 'assets/map_warehouse.svg', playerCount: 0, maxPlayers: 6, maxPlayersPerTeam: 3, roundsToWin: 4, sizeLabel: '3v3', state: 'idle', players: [] },
      { id: 'pvp_3v3_dust', name: '3v3', mode: 'pvp', mapId: 'dust', mapName: 'Dust', mapImage: 'assets/map_docks.svg', playerCount: 1, maxPlayers: 6, maxPlayersPerTeam: 3, roundsToWin: 4, sizeLabel: '3v3', state: 'waiting', players: [] },
      { id: 'pvp_4v4_construction', name: '4v4', mode: 'pvp', mapId: 'construction', mapName: 'Construction', mapImage: 'assets/map_construction.svg', playerCount: 0, maxPlayers: 8, maxPlayersPerTeam: 4, roundsToWin: 4, sizeLabel: '4v4', state: 'idle', players: [] },
      { id: 'pvp_4v4_cargo', name: '4v4', mode: 'pvp', mapId: 'cargo', mapName: 'Cargo', mapImage: 'assets/map_warehouse.svg', playerCount: 4, maxPlayers: 8, maxPlayersPerTeam: 4, roundsToWin: 4, sizeLabel: '4v4', state: 'waiting', players: [] },
      { id: 'pvp_4v4_dust', name: '4v4', mode: 'pvp', mapId: 'dust', mapName: 'Dust', mapImage: 'assets/map_docks.svg', playerCount: 8, maxPlayers: 8, maxPlayersPerTeam: 4, roundsToWin: 4, sizeLabel: '4v4', state: 'active', players: [] },
      { id: 'tdm_dust', name: 'Dust TDM', mode: 'tdm', mapId: 'dust', mapName: 'Dust', mapImage: 'assets/map_docks.svg', description: 'Two sides, one strip of sand.', playerCount: 8, maxPlayers: 16, killsToWin: 50, state: 'active', sizeLabel: 'TDM', scores: { 1: 22, 2: 18 }, players: [{ id: 1, name: 'Diesel', kills: 7, deaths: 3, team: 1 }] },
      { id: 'tdm_cargo', name: 'Cargo TDM', mode: 'tdm', mapId: 'cargo', mapName: 'Cargo', mapImage: 'assets/map_warehouse.svg', playerCount: 0, maxPlayers: 12, killsToWin: 40, state: 'idle', sizeLabel: 'TDM', players: [] },
      { id: 'tdm_construction', name: 'Construction TDM', mode: 'tdm', mapId: 'construction', mapName: 'Construction', mapImage: 'assets/map_construction.svg', playerCount: 3, maxPlayers: 12, killsToWin: 40, state: 'waiting', sizeLabel: 'TDM', players: [] },
    ],
    stats: { ffa: { elo: 1000 }, pvp: { elo: 1120 } },
    leaderboard: {
      ffa: [
        { rank: 1, name: 'Diesel', title: 'Champion', kills: 120, deaths: 88, kd: 1.36, wins: 18, losses: 9, elo: 1000 },
        { rank: 2, name: 'Nova', title: 'Warlord', kills: 101, deaths: 83, kd: 1.21, wins: 14, losses: 11, elo: 1000 },
        { rank: 3, name: 'Rook', title: 'Executioner', kills: 88, deaths: 84, kd: 1.05, wins: 11, losses: 12, elo: 1000 },
        { rank: 4, name: 'Ash', kills: 40, deaths: 92, kd: 0.43, wins: 3, losses: 10, elo: 980 },
      ],
      pvp: [
        { rank: 1, name: 'Diesel', title: 'Apex', kills: 40, deaths: 28, kd: 1.4, wins: 12, losses: 4, elo: 1120 },
        { rank: 2, name: 'Nova', title: 'Duelist King', kills: 33, deaths: 30, kd: 1.1, wins: 9, losses: 6, elo: 1084 },
      ],
      tdm: [],
    },
    history: [
      { lobby_name: '1v1 Construction', mode: 'pvp', won: 1, kills: 6, deaths: 2, scoreline: '5-3', elo_change: 18 },
      { lobby_name: 'Dust TDM', mode: 'tdm', won: 0, kills: 9, deaths: 8, scoreline: '41-50', elo_change: 0 },
    ],
  };

  async function nui(event, data = {}) {
    if (!IN_GAME) {
      if (event === 'listLobbies') return state.lobbies;
      if (event === 'getLobby') return state.lobbies.find((l) => l.id === data.lobbyId) || state.selected;
      if (event === 'getLeaderboard') return state.leaderboard[data.mode] || [];
      if (event === 'getHistory') return state.history;
      return { ok: true };
    }
    const resp = await fetch(`https://${resourceName}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    try { return await resp.json(); } catch { return null; }
  }

  const $ = (id) => document.getElementById(id);
  const show = (el, on = true) => { if (el) el.classList.toggle('hidden', !on); };
  const initials = (name) => {
    const parts = String(name || 'A').trim().split(/\s+/);
    return ((parts[0]?.[0] || 'A') + (parts[1]?.[0] || '')).toUpperCase();
  };
  const isLive = (l) => l.state === 'active' || l.state === 'countdown';
  const isTeam = (l) => l && (l.mode === 'tdm' || l.mode === 'pvp' || l.mode === 'showdown');
  const statusOf = (l) => {
    if (isLive(l)) return { cls: 'live', label: 'LIVE' };
    if ((l.playerCount || 0) >= (l.maxPlayers || 0) && l.maxPlayers) return { cls: 'full', label: 'FULL' };
    return { cls: 'open', label: 'OPEN' };
  };

  function allWeapons() {
    const list = [];
    (state.loadouts || []).forEach((l) => {
      (l.weapons || []).forEach((w) => list.push({ ...w, loadoutId: l.id, loadoutLabel: l.label }));
    });
    return list;
  }

  function mapsForMode(mode) {
    if (mode === 'ffa') return state.lobbies.filter((l) => l.mode === 'ffa');
    if (mode === 'tdm') return state.lobbies.filter((l) => l.mode === 'tdm');
    return state.lobbies.filter((l) => l.mode === 'pvp' && l.sizeLabel === mode);
  }

  function lobbyForPick() {
    const maps = mapsForMode(state.mode);
    return maps.find((l) => l.mapId === state.mapId) || maps[0];
  }

  function setTab(tab) {
    state.tab = tab;
    document.querySelectorAll('.nav-tab').forEach((b) => b.classList.toggle('active', b.dataset.tab === tab));
    document.querySelectorAll('.page').forEach((p) => p.classList.toggle('active', p.id === `page-${tab}`));
    if (tab === 'join') renderJoin();
    if (tab === 'rooms') renderRooms();
    if (tab === 'ranking') renderBoard();
    if (tab === 'history') renderHistory();
  }

  function renderJoin() {
    const grid = $('modeGrid');
    grid.innerHTML = '';
    MODES.forEach((m) => {
      const btn = document.createElement('button');
      btn.className = `mode-btn ${state.mode === m.id ? 'selected' : ''}`;
      btn.textContent = m.label;
      btn.addEventListener('click', () => {
        state.mode = m.id;
        const maps = mapsForMode(m.id);
        if (maps[0]) state.mapId = maps[0].mapId;
        renderJoin();
      });
      grid.appendChild(btn);
    });

    const lobby = lobbyForPick();
    const teamMode = state.mode !== 'ffa';
    show($('teamWrap'), teamMode);
    $('ruleLabel').textContent = state.mode === 'ffa' || state.mode === 'tdm' ? 'FIRST TO' : 'ROUNDS';
    $('ruleValue').textContent = lobby
      ? (lobby.killsToWin ? `${lobby.killsToWin} kills` : `First to ${lobby.roundsToWin || 5}`)
      : '—';

    $('teamWrap').querySelectorAll('.vis-btn').forEach((b) => {
      b.classList.toggle('selected', Number(b.dataset.team) === state.pick.team);
    });

    const weapons = allWeapons();
    if (!state.pick.weaponId && weapons[0]) {
      state.pick.weaponId = weapons[0].id;
      state.pick.loadoutId = weapons[0].loadoutId;
    }
    const list = $('weaponList');
    list.innerHTML = '';
    weapons.forEach((w) => {
      const btn = document.createElement('button');
      btn.className = `wep-row ${state.pick.weaponId === w.id ? 'selected' : ''}`;
      btn.innerHTML = `<span>${w.label}</span><span class="dot"></span>`;
      btn.addEventListener('click', () => {
        state.pick.weaponId = w.id;
        state.pick.loadoutId = w.loadoutId;
        renderJoin();
      });
      list.appendChild(btn);
    });
    const current = weapons.find((w) => w.id === state.pick.weaponId) || weapons[0];
    $('wepName').textContent = current?.label || 'Weapon';
    $('wepCat').textContent = (current?.loadoutLabel || '').toUpperCase();

    const maps = mapsForMode(state.mode);
    const pick = $('mapPick');
    pick.innerHTML = '';
    maps.forEach((m) => {
      const btn = document.createElement('button');
      btn.className = `map-tile ${state.mapId === m.mapId ? 'selected' : ''}`;
      btn.innerHTML = `
        <div class="thumb" style="background-image:url('${m.mapImage || ''}')"></div>
        <div class="label">${m.mapName || m.name}</div>
        <span class="check">✓</span>`;
      btn.addEventListener('click', () => { state.mapId = m.mapId; renderJoin(); });
      pick.appendChild(btn);
    });
  }

  function renderRooms() {
    const q = (state.roomQuery || '').toLowerCase();
    const list = state.lobbies.filter((l) => {
      const hay = `${l.sizeLabel || ''} ${l.mapName || ''} ${l.name || ''} ${l.mode || ''}`.toLowerCase();
      return !q || hay.includes(q);
    });
    $('roomCount').textContent = String(list.length);
    show($('roomsEmpty'), list.length === 0);
    const grid = $('roomGrid');
    grid.innerHTML = '';
    list.forEach((l) => {
      const st = statusOf(l);
      const card = document.createElement('button');
      card.className = 'room-card';
      card.innerHTML = `
        <div class="room-top">
          <h3>${l.sizeLabel || l.name}</h3>
          <span class="status ${st.cls}">${st.label}</span>
        </div>
        <p>${l.mapName || ''}</p>
        <div class="room-meta">
          <span>${l.killsToWin ? `${l.killsToWin} kills` : `${l.roundsToWin || 0} rounds`}</span>
          <span>${l.playerCount || 0}/${l.maxPlayers || 0}</span>
        </div>
        <div class="room-host">${l.players?.[0]?.name || 'Waiting for fighters'}</div>`;
      card.addEventListener('click', () => openSala(l));
      grid.appendChild(card);
    });
  }

  function slotHtml(p, empty) {
    if (!p) return `<div class="slot empty">${empty}</div>`;
    return `<div class="slot"><span class="av">${initials(p.name)}</span><span>${p.name}</span></div>`;
  }

  function openSala(lobby) {
    state.selected = lobby;
    const weapons = allWeapons();
    if (!state.pick.weaponId && weapons[0]) {
      state.pick.weaponId = weapons[0].id;
      state.pick.loadoutId = weapons[0].loadoutId;
    }
    $('salaName').textContent = `${lobby.sizeLabel || lobby.name}`;
    $('salaMeta').textContent = `${lobby.sizeLabel || lobby.mode} · ${lobby.mapName || ''} · ${(allWeapons().find((w) => w.id === state.pick.weaponId) || {}).label || 'Loadout'}`;
    const teamMode = isTeam(lobby);
    show($('salaFfa'), !teamMode);
    document.querySelector('.sala-vs').classList.toggle('hidden', !teamMode);
    show($('btnSwapTeam'), teamMode);
    const players = lobby.players || [];
    if (teamMode) {
      const cap = lobby.maxPlayersPerTeam || Math.ceil((lobby.maxPlayers || 2) / 2);
      const t1 = players.filter((p) => p.team === 1);
      const t2 = players.filter((p) => p.team === 2);
      $('salaTeam1').innerHTML = Array.from({ length: cap }, (_, i) => slotHtml(t1[i], 'Open slot')).join('');
      $('salaTeam2').innerHTML = Array.from({ length: cap }, (_, i) => slotHtml(t2[i], 'Open slot')).join('');
    } else {
      $('salaFfa').innerHTML = players.length
        ? players.map((p) => slotHtml(p)).join('')
        : '<div class="slot empty">Waiting for fighters</div>';
    }
    show($('sala'), true);
  }

  function renderBoard() {
    const rows = [...(state.leaderboard[state.boardMode] || [])];
    rows.forEach((p) => {
      p.wl = (p.losses || 0) > 0 ? Math.round(((p.wins || 0) / p.losses) * 100) / 100 : (p.wins || 0);
    });
    const sort = state.boardSort;
    rows.sort((a, b) => (b[sort] || 0) - (a[sort] || 0));
    $('boardRows').innerHTML = rows.map((p, i) => {
      const rank = i + 1;
      const medal = rank === 1 ? 'gold' : rank === 2 ? 'silver' : rank === 3 ? 'bronze' : '';
      const kdClass = (p.kd || 0) >= 1 ? 'kd-hi' : 'kd-lo';
      return `<div class="board-row">
        <span><span class="medal ${medal}">${rank}</span></span>
        <span>${p.name}</span>
        <span>${p.kills || 0}</span>
        <span>${p.deaths || 0}</span>
        <span class="${kdClass}">${p.kd ?? '—'}</span>
        <span>${p.wins || 0}</span>
        <span>${p.losses || 0}</span>
        <span>${p.wl ?? '—'}</span>
      </div>`;
    }).join('') || '<div class="empty-state">No ranked fights yet.</div>';
  }

  function renderHistory() {
    const rows = state.history || [];
    show($('historyEmpty'), rows.length === 0);
    $('historyList').innerHTML = rows.map((h) => `
      <div class="history-row ${h.won ? 'win' : 'loss'}">
        <div>
          <strong>${h.lobby_name || h.lobbyName || h.mode}</strong>
          <div style="color:var(--muted);font-size:0.8rem">${(h.mode || '').toUpperCase()} · ${h.scoreline || ''} · ${h.kills}/${h.deaths}</div>
        </div>
        <div>${h.won ? 'WIN' : 'LOSS'} ${h.elo_change || h.eloChange ? `(${(h.elo_change || h.eloChange) > 0 ? '+' : ''}${h.elo_change || h.eloChange})` : ''}</div>
      </div>`).join('');
  }

  function renderLoadoutPicker(listId, wepId, loadouts, pick) {
    const list = $(listId); const weps = $(wepId);
    if (!list || !weps) return;
    list.innerHTML = ''; weps.innerHTML = '';
    (loadouts || []).forEach((l) => {
      const btn = document.createElement('button');
      btn.className = `chip ${pick.loadoutId === l.id ? 'selected' : ''}`;
      btn.textContent = l.label;
      btn.addEventListener('click', () => { pick.loadoutId = l.id; pick.weaponId = l.weapons?.[0]?.id; renderLoadoutPicker(listId, wepId, loadouts, pick); });
      list.appendChild(btn);
    });
    const current = (loadouts || []).find((l) => l.id === pick.loadoutId);
    (current?.weapons || []).forEach((w) => {
      const btn = document.createElement('button');
      btn.className = `chip ${pick.weaponId === w.id ? 'selected' : ''}`;
      btn.textContent = w.label;
      btn.addEventListener('click', () => { pick.weaponId = w.id; renderLoadoutPicker(listId, wepId, loadouts, pick); });
      weps.appendChild(btn);
    });
  }

  async function joinSelected(lobby) {
    if (!lobby) return;
    const res = await nui('joinLobby', {
      lobbyId: lobby.id,
      loadoutId: state.pick.loadoutId,
      weaponId: state.pick.weaponId,
      team: state.pick.team,
    });
    if (res?.ok) {
      show($('sala'), false);
      hideUI();
    }
  }

  function openUI(data) {
    state.open = true;
    state.playerName = data.playerName || 'Player';
    state.loadouts = data.loadouts || [];
    state.lobbies = data.lobbies || [];
    state.stats = data.stats || {};
    state.leaderboard = Object.assign(state.leaderboard, data.leaderboard || {});
    state.history = data.history || [];
    const maps = mapsForMode(state.mode);
    if (maps[0] && !maps.find((m) => m.mapId === state.mapId)) state.mapId = maps[0].mapId;
    show($('app'), true);
    setTab(state.tab || 'join');
  }

  function hideUI() {
    state.open = false;
    show($('app'), false);
    show($('sala'), false);
    show($('loadoutModal'), false);
  }

  function closeUI() {
    hideUI();
    nui('close');
  }

  document.querySelectorAll('.nav-tab').forEach((btn) => btn.addEventListener('click', () => setTab(btn.dataset.tab)));
  $('boardModes').querySelectorAll('.chip').forEach((btn) => {
    btn.addEventListener('click', async () => {
      state.boardMode = btn.dataset.board;
      $('boardModes').querySelectorAll('.chip').forEach((b) => b.classList.toggle('active', b === btn));
      const list = await nui('getLeaderboard', { mode: state.boardMode });
      if (list) state.leaderboard[state.boardMode] = list;
      renderBoard();
    });
  });
  $('boardSort').querySelectorAll('.chip').forEach((btn) => {
    btn.addEventListener('click', () => {
      state.boardSort = btn.dataset.sort;
      $('boardSort').querySelectorAll('.chip').forEach((b) => b.classList.toggle('active', b === btn));
      renderBoard();
    });
  });
  $('btnClose').addEventListener('click', closeUI);
  $('btnCloseSala').addEventListener('click', () => show($('sala'), false));
  $('btnLeaveSala').addEventListener('click', () => show($('sala'), false));
  $('teamWrap').addEventListener('click', (e) => {
    const btn = e.target.closest('.vis-btn');
    if (!btn) return;
    state.pick.team = Number(btn.dataset.team);
    renderJoin();
  });
  $('btnSwapTeam').addEventListener('click', () => {
    state.pick.team = state.pick.team === 1 ? 2 : 1;
  });
  $('btnJoinArena').addEventListener('click', () => joinSelected(lobbyForPick()));
  $('btnConfirmJoin').addEventListener('click', () => joinSelected(state.selected));
  $('roomSearch').addEventListener('input', (e) => { state.roomQuery = e.target.value; renderRooms(); });
  $('btnCancelLoadout').addEventListener('click', () => { show($('loadoutModal'), false); nui('close'); });
  $('btnApplyLoadout').addEventListener('click', async () => {
    await nui('changeLoadout', state.livePick);
    show($('loadoutModal'), false);
  });

  function fmtTime(endsAt) {
    if (!endsAt) return '--:--';
    const left = Math.max(0, endsAt - Math.floor(Date.now() / 1000));
    const m = Math.floor(left / 60);
    const s = left % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }

  function renderHud(data) {
    if (!data) return;
    const me = data.me || {};
    if (data.mode === 'tdm' || data.mode === 'pvp' || data.mode === 'showdown') {
      state.hudEndsAt = data.endsAt || state.hudEndsAt;
      $('scorePlate').innerHTML = `
        <div class="hud-side"><span class="hud-tag t1">ALPHA</span><span class="hud-score">${data.scores?.[1] || 0}</span></div>
        <div class="hud-timer">
          <span class="hud-round">${data.round || 1}</span>
          <div class="hud-ring">${fmtTime(state.hudEndsAt)}</div>
        </div>
        <div class="hud-side"><span class="hud-score">${data.scores?.[2] || 0}</span><span class="hud-tag t2">BRAVO</span></div>`;
    } else {
      const sorted = [...(data.players || [])].sort((a, b) => (b.kills || 0) - (a.kills || 0));
      const place = Math.max(1, sorted.findIndex((p) => p.id === me.id) + 1 || 1);
      $('scorePlate').innerHTML = `
        <div class="hud-ffa">
          <div class="mode">FREE FOR ALL</div>
          <div class="hud-score">${me.kills || 0}</div>
          <div class="mode">#${place} · ${data.killsToWin || 30} TO WIN</div>
        </div>`;
    }
    const panel = $('teamPanel');
    if (data.teamPanel) {
      show(panel, true);
      const mine = (data.players || []).filter((p) => p.team === data.team);
      panel.innerHTML = `<h4>YOUR SIDE</h4>` + mine.map((p) => `
        <div class="tp-row ${p.alive === false ? 'down' : ''}"><span>${p.name}</span><span>${p.alive === false ? '✕' : '●'}</span></div>`).join('');
    } else show(panel, false);
  }

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'open') { show($('matchHud'), false); openUI(msg.data || {}); }
    if (msg.action === 'close') hideUI();
    if (msg.action === 'refreshLobbies') {
      nui('listLobbies').then((list) => { if (list) { state.lobbies = list; setTab(state.tab); } });
    }
    if (msg.action === 'lobbyUpdate' && msg.data) {
      state.lobbies = state.lobbies.map((l) => l.id === msg.data.id ? msg.data : l);
      if (state.selected?.id === msg.data.id) openSala(msg.data);
    }
    if (msg.action === 'openLoadout') {
      const loadouts = msg.data?.loadouts || state.loadouts;
      state.livePick.loadoutId = loadouts[0]?.id;
      state.livePick.weaponId = loadouts[0]?.weapons?.[0]?.id;
      renderLoadoutPicker('liveLoadouts', 'liveWeapons', loadouts, state.livePick);
      show($('loadoutModal'), true);
    }
    if (msg.action === 'matchHud') { show($('matchHud'), !!msg.visible); if (msg.visible && msg.data) renderHud(msg.data); }
    if (msg.action === 'timer') { state.hudEndsAt = msg.endsAt; }
    if (msg.action === 'killfeed' && msg.data) {
      const feed = $('killfeed');
      const row = document.createElement('div');
      row.className = 'kill-item';
      row.innerHTML = `<strong>${msg.data.killer || 'World'}</strong><span class="wep">${(msg.data.category || '').toUpperCase()}</span>${msg.data.victim}`;
      feed.prepend(row);
      setTimeout(() => row.remove(), 4200);
    }
    if (msg.action === 'hitmarker') {
      const el = $('hitmarker');
      el.className = `hitmarker ${msg.kind || 'hit'}`;
      $('hitDmg').textContent = msg.damage ? msg.damage : '';
      show(el, true);
      clearTimeout(el._t);
      el._t = setTimeout(() => show(el, false), 280);
    }
    if (msg.action === 'killstreak') {
      $('streakLabel').textContent = msg.label || '';
      show($('streak'), true);
      clearTimeout($('streak')._t);
      $('streak')._t = setTimeout(() => show($('streak'), false), 1600);
    }
    if (msg.action === 'countdown') {
      if (!msg.seconds) { show($('countdown'), false); return; }
      $('countdownRound').textContent = msg.round ? `ROUND ${msg.round}` : '';
      show($('countdown'), true);
      let n = msg.seconds;
      $('countdownNum').textContent = n;
      clearInterval(window._cd);
      window._cd = setInterval(() => {
        n -= 1;
        if (n <= 0) { clearInterval(window._cd); show($('countdown'), false); return; }
        $('countdownNum').textContent = n;
      }, 1000);
    }
    if (msg.action === 'bounds') { show($('bounds'), !!msg.visible); if (msg.visible) $('boundsNum').textContent = msg.seconds; }
    if (msg.action === 'deathOverlay') show($('deathOverlay'), !!msg.visible);
    if (msg.action === 'spectate') {
      show($('spectateBar'), !!msg.visible);
      if (msg.name) $('spectateName').textContent = msg.name;
      $('spectateHint').textContent = msg.hint || '';
    }
    if (msg.action === 'matchResult') {
      if (!msg.data) { show($('matchResult'), false); return; }
      $('resultTitle').textContent = msg.data.outcome === 'win' ? 'VICTORY' : msg.data.outcome === 'loss' ? 'DEFEAT' : 'DRAW';
      $('resultSub').textContent = msg.data.result?.scoreline ? `Score ${msg.data.result.scoreline}` : '';
      $('resultElo').textContent = msg.data.eloChange ? `${msg.data.eloChange > 0 ? '+' : ''}${msg.data.eloChange} ELO` : '';
      show($('matchResult'), true);
      setTimeout(() => show($('matchResult'), false), 6500);
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && state.open) closeUI();
  });

  setInterval(() => {
    const ring = document.querySelector('.hud-ring');
    if (ring && state.hudEndsAt) ring.textContent = fmtTime(state.hudEndsAt);
  }, 1000);

  if (!IN_GAME) {
    document.body.classList.add('preview');
    MOCK.lobbies.forEach((l) => { l.loadouts = MOCK.loadouts; });
    const tab = new URLSearchParams(location.search).get('tab') || 'join';
    state.tab = ['join', 'rooms', 'ranking', 'history'].includes(tab) ? tab : 'join';
    openUI(MOCK);
  }
})();
