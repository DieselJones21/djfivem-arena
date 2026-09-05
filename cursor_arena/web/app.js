(() => {
  const IN_GAME = typeof GetParentResourceName === 'function';
  const resourceName = IN_GAME ? GetParentResourceName() : 'cursor_arena';

  const MODES = [
    { id: 'ffa', label: 'FFA', blurb: '12 players · first to 30' },
    { id: '1v1', label: '1v1', blurb: 'Duel · first to 5' },
    { id: '2v2', label: '2v2', blurb: 'Squad · first to 4' },
    { id: '3v3', label: '3v3', blurb: 'Squad · first to 4' },
    { id: '4v4', label: '4v4', blurb: 'Squad · first to 4' },
    { id: 'tdm', label: 'TDM', blurb: '5v5 · first to 50' },
  ];
  const TABS = ['lobbies', 'private', 'loadout', 'shop', 'ranking', 'history'];
  const FIRST_TO = {
    ffa: [10, 15, 20, 25, 30],
    tdm: [20, 30, 40, 50],
    pvp: [3, 4, 5, 7, 9],
  };
  const MAP_THUMBS = {
    pvp_1: 'assets/map_stables.jpg',
    pvp_3: 'assets/map_pvp.jpg',
    pvp_4: 'assets/map_rooftop.jpg',
  };

  function mapThumb(entry) {
    if (!entry) return '';
    return MAP_THUMBS[entry.mapId] || entry.mapImage || '';
  }

  const state = {
    open: false,
    tab: 'lobbies',
    boardMode: 'ffa',
    boardSort: 'wins',
    mode: '1v1',
    mapId: 'pvp_1',
    roomQuery: '',
    lobbyFilter: 'all',
    playerName: 'Player',
    lobbies: [],
    loadouts: [],
    shop: [],
    coins: 0,
    coinLabel: 'Coins',
    stats: {},
    leaderboard: { ffa: [], tdm: [], pvp: [], showdown: [] },
    history: [],
    selected: null,
    playerId: null,
    currentLobbyId: null,
    pick: { loadoutId: null, weaponId: null, team: 1 },
    livePick: { loadoutId: null, weaponId: null },
    hudEndsAt: 0,
    hudLocalEnd: 0,
    maps: [],
    priv: { mode: '1v1', mapId: 'pvp_1', firstTo: 5, team: 1 },
  };

  const MOCK = {
    playerName: 'Diesel',
    coins: 1840,
    coinLabel: 'Envy Coins',
    loadouts: [
      { id: 'pistols', label: 'Pistols', weapons: [
        { id: 'g17', label: 'G17', weapon: 'WEAPON_G17' },
        { id: 'g45', label: 'G45', weapon: 'WEAPON_G45' },
      ]},
      { id: 'smg', label: 'SMG', weapons: [{ id: 'spectre', label: 'Spectre SMG', weapon: 'WEAPON_SPECTRESMG' }] },
      { id: 'ar', label: 'AR', weapons: [{ id: 'kissar', label: 'Kiss AR', weapon: 'WEAPON_KISSAR' }] },
    ],
    shop: [
      { id: 'spiderap', loadoutId: 'pistols', label: 'Spider AP', category: 'Pistols', price: 250, owned: false },
      { id: 'bluewire', loadoutId: 'pistols', label: 'Blue Wire', category: 'Pistols', price: 250, owned: true },
      { id: 'chromewire', loadoutId: 'smg', label: 'Chrome Wire SMG', category: 'SMG', price: 400, owned: false },
      { id: 'portalpurple', loadoutId: 'ar', label: 'Portal Purple', category: 'AR', price: 500, owned: false },
    ],
    lobbies: [
      { id: 'ffa_arena_1', name: 'FFA', mode: 'ffa', mapId: 'arena_1', mapName: 'Park', mapImage: 'assets/map_construction.svg', playerCount: 6, maxPlayers: 12, killsToWin: 30, state: 'active', sizeLabel: 'FFA', players: [{ id: 1, name: 'Diesel', kills: 8, deaths: 2, team: 0, weapon: 'g17' }] },
      { id: 'ffa_arena_2', name: 'FFA', mode: 'ffa', mapId: 'arena_2', mapName: 'Wreck', mapImage: 'assets/map_warehouse.svg', playerCount: 2, maxPlayers: 12, killsToWin: 30, state: 'waiting', sizeLabel: 'FFA', players: [{ id: 2, name: 'Nova', team: 0 }] },
      { id: 'pvp_1v1_pvp_1', name: '1v1', mode: 'pvp', mapId: 'pvp_1', mapName: 'Stables', mapImage: 'assets/map_stables.jpg', playerCount: 1, maxPlayers: 2, maxPlayersPerTeam: 1, roundsToWin: 5, state: 'waiting', sizeLabel: '1v1', players: [{ id: 1, name: 'Diesel', kills: 0, deaths: 0, team: 1, weapon: 'g17' }] },
      { id: 'pvp_1v1_pvp_2', name: '1v1', mode: 'pvp', mapId: 'pvp_2', mapName: 'Stores', mapImage: 'assets/map_warehouse.svg', playerCount: 0, maxPlayers: 2, maxPlayersPerTeam: 1, roundsToWin: 5, state: 'idle', sizeLabel: '1v1', players: [] },
      { id: 'pvp_1v1_pvp_3', name: '1v1', mode: 'pvp', mapId: 'pvp_3', mapName: 'PVP Map', mapImage: 'assets/map_pvp.jpg', playerCount: 2, maxPlayers: 2, maxPlayersPerTeam: 1, roundsToWin: 5, state: 'active', sizeLabel: '1v1', players: [{ id: 1, name: 'Diesel', team: 1 }, { id: 2, name: 'Nova', team: 2 }] },
      { id: 'pvp_1v1_pvp_4', name: '1v1', mode: 'pvp', mapId: 'pvp_4', mapName: 'Rooftop', mapImage: 'assets/map_rooftop.jpg', playerCount: 0, maxPlayers: 2, maxPlayersPerTeam: 1, roundsToWin: 5, state: 'idle', sizeLabel: '1v1', players: [] },
      { id: 'pvp_2v2_pvp_1', name: '2v2', mode: 'pvp', mapId: 'pvp_1', mapName: 'Stables', mapImage: 'assets/map_stables.jpg', playerCount: 3, maxPlayers: 4, maxPlayersPerTeam: 2, roundsToWin: 4, sizeLabel: '2v2', state: 'waiting', players: [{ id: 1, name: 'Diesel', team: 1 }, { id: 2, name: 'Rook', team: 1 }, { id: 3, name: 'Nova', team: 2 }] },
      { id: 'pvp_2v2_pvp_2', name: '2v2', mode: 'pvp', mapId: 'pvp_2', mapName: 'Stores', mapImage: 'assets/map_warehouse.svg', playerCount: 0, maxPlayers: 4, maxPlayersPerTeam: 2, roundsToWin: 4, sizeLabel: '2v2', state: 'idle', players: [] },
      { id: 'pvp_3v3_pvp_1', name: '3v3', mode: 'pvp', mapId: 'pvp_1', mapName: 'Stables', mapImage: 'assets/map_stables.jpg', playerCount: 0, maxPlayers: 6, maxPlayersPerTeam: 3, roundsToWin: 4, sizeLabel: '3v3', state: 'idle', players: [] },
      { id: 'pvp_4v4_pvp_4', name: '4v4', mode: 'pvp', mapId: 'pvp_4', mapName: 'Rooftop', mapImage: 'assets/map_rooftop.jpg', playerCount: 4, maxPlayers: 8, maxPlayersPerTeam: 4, roundsToWin: 4, sizeLabel: '4v4', state: 'waiting', players: [{ id: 4, name: 'Ash', team: 1 }] },
      { id: 'tdm_arena_1', name: 'TDM', mode: 'tdm', mapId: 'arena_1', mapName: 'Park', mapImage: 'assets/map_construction.svg', playerCount: 8, maxPlayers: 10, maxPlayersPerTeam: 5, killsToWin: 50, state: 'active', sizeLabel: 'TDM', scores: { 1: 22, 2: 18 }, players: [{ id: 1, name: 'Diesel', kills: 7, deaths: 3, team: 1 }] },
      { id: 'tdm_arena_2', name: 'TDM', mode: 'tdm', mapId: 'arena_2', mapName: 'Wreck', mapImage: 'assets/map_warehouse.svg', playerCount: 0, maxPlayers: 10, maxPlayersPerTeam: 5, killsToWin: 50, state: 'idle', sizeLabel: 'TDM', players: [] },
      { id: 'priv_k7m2p', name: '1v1', mode: 'pvp', private: true, code: 'K7M2P', mapId: 'pvp_1', mapName: 'Stables', mapImage: 'assets/map_stables.jpg', playerCount: 1, maxPlayers: 2, maxPlayersPerTeam: 1, roundsToWin: 5, state: 'waiting', sizeLabel: '1v1', players: [{ id: 1, name: 'Diesel', team: 1 }] },
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
      { lobby_name: '1v1 Stables', mode: 'pvp', won: 1, kills: 6, deaths: 2, scoreline: '5-3', elo_change: 18 },
      { lobby_name: 'Park TDM', mode: 'tdm', won: 0, kills: 9, deaths: 8, scoreline: '41-50', elo_change: 0 },
    ],
    maps: [
      { id: 'arena_1', name: 'Park', image: 'assets/map_construction.svg' },
      { id: 'arena_2', name: 'Wreck', image: 'assets/map_warehouse.svg' },
      { id: 'pvp_1', name: 'Stables', image: 'assets/map_stables.jpg' },
      { id: 'pvp_2', name: 'Stores', image: 'assets/map_warehouse.svg' },
      { id: 'pvp_3', name: 'PVP Map', image: 'assets/map_pvp.jpg' },
      { id: 'pvp_4', name: 'Rooftop', image: 'assets/map_rooftop.jpg' },
    ],
  };

  async function nui(event, data = {}) {
    if (!IN_GAME) {
      if (event === 'listLobbies') return state.lobbies;
      if (event === 'getLobby') return state.lobbies.find((l) => l.id === data.lobbyId) || state.selected;
      if (event === 'getLeaderboard') return state.leaderboard[data.mode] || [];
      if (event === 'getHistory') return state.history;
      if (event === 'buyShop') {
        const item = state.shop.find((s) => s.id === data.weaponId);
        if (!item) return { ok: false, message: 'Unknown gun' };
        if (item.owned) return { ok: true, owned: true, coins: state.coins };
        if (state.coins < item.price) return { ok: false, message: 'Not enough coins' };
        item.owned = true;
        state.coins -= item.price;
        const group = state.loadouts.find((l) => l.id === item.loadoutId);
        if (group && !group.weapons.find((w) => w.id === item.id)) {
          group.weapons.push({ id: item.id, label: item.label, loadoutId: item.loadoutId });
        }
        return { ok: true, coins: state.coins, shop: state.shop, loadouts: state.loadouts };
      }
      if (event === 'watchLobby' || event === 'watchByCode') return { ok: true };
      if (event === 'createPrivate') {
        return { ok: true, lobby: { id: 'priv_demo', code: 'K7M2P', sizeLabel: state.priv.mode.toUpperCase(), mapName: 'Stables', mode: 'pvp', private: true } };
      }
      if (event === 'joinByCode') return { ok: true };
      if (event === 'placeBet') return { ok: true, bets: [] };
      if (event === 'betItems') return [
        { name: 'WEAPON_G17', label: 'G17', count: 1, kind: 'gun' },
        { name: 'vehiclekey', label: 'Sultan RS key', count: 1, kind: 'car' },
      ];
      if (event === 'myMoney') return { cash: 25000, max: 100000 };
      return { ok: true };
    }
    const ctrl = typeof AbortController === 'function' ? new AbortController() : null;
    const timer = setTimeout(() => { if (ctrl) ctrl.abort(); }, 8000);
    try {
      const resp = await fetch(`https://${resourceName}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
        signal: ctrl ? ctrl.signal : undefined,
      });
      try { return await resp.json(); } catch { return { ok: false, message: 'Arena server sent a bad reply' }; }
    } catch (err) {
      return { ok: false, message: 'Arena server did not answer' };
    } finally {
      clearTimeout(timer);
    }
  }

  function toast(msg) {
    const el = $('tabletToast');
    if (!el || !msg) return;
    el.textContent = String(msg);
    show(el, true);
    clearTimeout(el._t);
    el._t = setTimeout(() => show(el, false), 3200);
  }

  const $ = (id) => document.getElementById(id);
  const show = (el, on = true) => { if (el) el.classList.toggle('hidden', !on); };
  const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const initials = (name) => {
    const parts = String(name || 'A').trim().split(/\s+/);
    return ((parts[0]?.[0] || 'A') + (parts[1]?.[0] || '')).toUpperCase();
  };
  const isLive = (l) => l.state === 'active' || l.state === 'countdown';
  const isTeam = (l) => l && (l.mode === 'tdm' || l.mode === 'pvp' || l.mode === 'showdown');
  const statusOf = (l) => {
    if (isLive(l)) return { cls: 'live', label: 'IN PROGRESS' };
    if ((l.playerCount || 0) >= (l.maxPlayers || 0) && l.maxPlayers) return { cls: 'full', label: 'FULL' };
    return { cls: 'open', label: 'OPEN' };
  };
  const weaponLabel = (id) => (allWeapons().find((w) => w.id === id) || {}).label || 'Open';

  function allWeapons() {
    const list = [];
    (state.loadouts || []).forEach((l) => {
      (l.weapons || []).forEach((w) => list.push({ ...w, loadoutId: l.id, loadoutLabel: l.label }));
    });
    return list;
  }

  function uniqueByMap(list) {
    const seen = new Set();
    return list.filter((l) => {
      const key = l.mapId || l.id;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }

  function mapsForMode(mode) {
    if (mode === 'ffa') return uniqueByMap(state.lobbies.filter((l) => l.mode === 'ffa'));
    if (mode === 'tdm') return uniqueByMap(state.lobbies.filter((l) => l.mode === 'tdm'));
    return uniqueByMap(state.lobbies.filter((l) => l.mode === 'pvp' && l.sizeLabel === mode));
  }

  function lobbyForPick() {
    const maps = mapsForMode(state.mode);
    return maps.find((l) => l.mapId === state.mapId) || maps[0];
  }

  function setTab(tab) {
    state.tab = tab;
    show($('sala'), false);
    document.querySelectorAll('.nav-tab').forEach((b) => b.classList.toggle('active', b.dataset.tab === tab));
    document.querySelectorAll('.page').forEach((p) => p.classList.toggle('active', p.id === `page-${tab}`));
    if (tab === 'lobbies') renderLobbies();
    if (tab === 'private') renderPrivate();
    if (tab === 'loadout') renderLoadout();
    if (tab === 'shop') renderShop();
    if (tab === 'ranking') {
      renderBoard();
      nui('getLeaderboard', { mode: state.boardMode }).then((list) => {
        if (list) state.leaderboard[state.boardMode] = list;
        if (state.tab === 'ranking') renderBoard();
      });
    }
    if (tab === 'history') {
      renderHistory();
      nui('getHistory').then((list) => {
        if (list) state.history = list;
        if (state.tab === 'history') renderHistory();
      });
    }
  }

  function renderLoadout() {
    const grid = $('modeGrid');
    grid.innerHTML = '';
    MODES.forEach((m) => {
      const btn = document.createElement('button');
      btn.className = `chip ${state.mode === m.id ? 'active' : ''}`;
      btn.textContent = m.label;
      btn.addEventListener('click', () => {
        state.mode = m.id;
        const maps = mapsForMode(m.id);
        if (maps[0]) state.mapId = maps[0].mapId;
        renderLoadout();
      });
      grid.appendChild(btn);
    });

    const lobby = lobbyForPick();
    show($('teamWrap'), state.mode !== 'ffa' && state.mode !== '1v1');
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
      btn.innerHTML = `<span>${esc(w.label)}</span><span class="dot"></span>`;
      btn.addEventListener('click', () => {
        state.pick.weaponId = w.id;
        state.pick.loadoutId = w.loadoutId;
        renderLoadout();
      });
      list.appendChild(btn);
    });

    const maps = mapsForMode(state.mode);
    const pick = $('mapPick');
    pick.innerHTML = '';
    maps.forEach((m) => {
      const btn = document.createElement('button');
      btn.className = `map-tile ${state.mapId === m.mapId ? 'selected' : ''}`;
      btn.innerHTML = `
        <span class="card-tag">${state.mapId === m.mapId ? 'SELECTED' : 'MAP'}</span>
        <div class="thumb" style="background-image:url('${mapThumb(m)}')"></div>
        <div class="label">${esc(m.mapName || m.name)}</div>
        <span class="check">✓</span>`;
      btn.addEventListener('click', () => { state.mapId = m.mapId; renderLoadout(); });
      pick.appendChild(btn);
    });
    const joinCta = $('btnJoinArena');
    if (joinCta) joinCta.disabled = !lobby;
  }

  function mapsForCreate(mode) {
    const all = state.maps || [];
    if (all.length) {
      if (mode === 'ffa' || mode === 'tdm') return all.filter((m) => String(m.id).startsWith('arena_'));
      return all.filter((m) => String(m.id).startsWith('pvp_'));
    }
    return mapsForMode(mode).map((l) => ({ id: l.mapId, name: l.mapName, image: l.mapImage }));
  }

  function privKind() {
    const mode = state.priv.mode;
    if (mode === 'ffa' || mode === 'tdm') return mode;
    return 'pvp';
  }

  function renderPrivate() {
    const modes = $('privModes');
    if (!modes) return;
    modes.innerHTML = '';
    MODES.forEach((m) => {
      const btn = document.createElement('button');
      btn.className = `chip ${state.priv.mode === m.id ? 'active' : ''}`;
      btn.textContent = m.label;
      btn.addEventListener('click', () => {
        state.priv.mode = m.id;
        const maps = mapsForCreate(m.id);
        if (maps[0] && !maps.find((x) => x.id === state.priv.mapId)) state.priv.mapId = maps[0].id;
        const opts = FIRST_TO[privKind()] || FIRST_TO.pvp;
        if (!opts.includes(state.priv.firstTo)) state.priv.firstTo = opts[Math.floor(opts.length / 2)];
        renderPrivate();
      });
      modes.appendChild(btn);
    });

    const maps = mapsForCreate(state.priv.mode);
    if (maps[0] && !maps.find((m) => m.id === state.priv.mapId)) state.priv.mapId = maps[0].id;
    const pick = $('privMaps');
    pick.innerHTML = '';
    maps.forEach((m) => {
      const btn = document.createElement('button');
      btn.className = `map-tile ${state.priv.mapId === m.id ? 'selected' : ''}`;
      const thumb = MAP_THUMBS[m.id] || m.image || '';
      btn.innerHTML = `
        <span class="card-tag">${state.priv.mapId === m.id ? 'SELECTED' : 'MAP'}</span>
        <div class="thumb" style="background-image:url('${thumb}')"></div>
        <div class="label">${esc(m.name)}</div>
        <span class="check">✓</span>`;
      btn.addEventListener('click', () => { state.priv.mapId = m.id; renderPrivate(); });
      pick.appendChild(btn);
    });

    const kind = privKind();
    const opts = FIRST_TO[kind] || FIRST_TO.pvp;
    $('privGoalLabel').textContent = kind === 'pvp' ? 'First to (rounds)' : 'First to (kills)';
    const row = $('privFirstTo');
    row.innerHTML = '';
    opts.forEach((n) => {
      const btn = document.createElement('button');
      btn.className = `chip ${state.priv.firstTo === n ? 'active' : ''}`;
      btn.textContent = String(n);
      btn.addEventListener('click', () => { state.priv.firstTo = n; renderPrivate(); });
      row.appendChild(btn);
    });

    const solo = state.priv.mode === '1v1' || state.priv.mode === 'ffa';
    show($('privTeamBox'), !solo);
    $('privTeamHint').textContent = state.priv.mode === '1v1'
      ? '1v1 assigns Orange and Blue automatically.'
      : state.priv.mode === 'ffa'
        ? 'Free-for-all — no teams.'
        : 'Pick a side. Rooms stay Orange vs Blue.';
    $('privTeamWrap').querySelectorAll('.vis-btn').forEach((b) => {
      b.classList.toggle('selected', Number(b.dataset.team) === state.priv.team);
    });

    const weapons = allWeapons();
    if (!state.pick.weaponId && weapons[0]) {
      state.pick.weaponId = weapons[0].id;
      state.pick.loadoutId = weapons[0].loadoutId;
    }
    const list = $('privWeapons');
    list.innerHTML = '';
    weapons.forEach((w) => {
      const btn = document.createElement('button');
      btn.className = `wep-row ${state.pick.weaponId === w.id ? 'selected' : ''}`;
      btn.innerHTML = `<span>${esc(w.label)}</span><span class="dot"></span>`;
      btn.addEventListener('click', () => {
        state.pick.weaponId = w.id;
        state.pick.loadoutId = w.loadoutId;
        renderPrivate();
      });
      list.appendChild(btn);
    });

    const map = maps.find((m) => m.id === state.priv.mapId);
    const goal = kind === 'pvp' ? `first to ${state.priv.firstTo}` : `first to ${state.priv.firstTo} kills`;
    $('privSummary').textContent = `${state.priv.mode.toUpperCase()} · ${map?.name || 'Map'} · ${goal}`;
  }

  function renderLobbies() {
    const q = (state.roomQuery || '').toLowerCase();
    const filter = state.lobbyFilter || 'all';
    const list = state.lobbies.filter((l) => {
      const size = String(l.sizeLabel || l.mode || '').toLowerCase();
      if (filter === 'live') {
        if (!isLive(l)) return false;
      } else if (filter === 'private') {
        if (!l.private) return false;
      } else if (filter !== 'all' && size !== filter && String(l.mode || '').toLowerCase() !== filter) {
        return false;
      }
      const host = l.players?.[0]?.name || '';
      const hay = `${l.sizeLabel || ''} ${l.mapName || ''} ${l.name || ''} ${l.mode || ''} ${host}`.toLowerCase();
      return !q || hay.includes(q);
    });
    show($('roomsEmpty'), list.length === 0);
    const grid = $('roomGrid');
    grid.innerHTML = '';
    list.forEach((l) => {
      const st = statusOf(l);
      const host = l.players?.[0]?.name || (l.private ? 'Your private room' : 'Open lobby');
      const busy = isLive(l) || ((l.playerCount || 0) >= (l.maxPlayers || 0) && l.maxPlayers);
      const wep = weaponLabel(l.players?.[0]?.weapon);
      const card = document.createElement('div');
      const shot = mapThumb(l);
      const filled = Math.min(100, Math.round(((l.playerCount || 0) / Math.max(1, l.maxPlayers || 1)) * 100));
      card.className = `lobby-row ${l.private ? 'private' : ''}`;
      card.innerHTML = `
        <div class="lobby-shot ${shot ? '' : 'empty'}" style="${shot ? `background-image:url('${shot}')` : ''}"></div>
        <div class="lobby-body">
          <div class="lobby-top">
            <div class="lobby-host">${esc(host)}<small>${esc(l.mapName || 'Arena')}${l.code ? ` · CODE ${esc(l.code)}` : ''}</small></div>
            <div class="lobby-badges">
              <span class="mode-pill ${l.private ? 'lock' : ''}">${l.private ? 'PRIVATE' : esc(l.sizeLabel || l.mode)}</span>
              ${l.private ? `<span class="mode-pill">${esc(l.sizeLabel || l.mode)}</span>` : ''}
              <span class="status ${st.cls}">${st.label}</span>
            </div>
          </div>
          <div class="lobby-meta">
            <span><span class="meter"><i style="width:${filled}%"></i></span><b>${l.playerCount || 0}/${l.maxPlayers || 0}</b></span>
            <span>${l.killsToWin ? 'First to' : 'First to'} <b>${l.killsToWin || l.roundsToWin || 0}</b></span>
            <span>Gun <b>${esc(wep)}</b></span>
          </div>
        </div>
        <div class="lobby-actions">
          <button class="lobby-join ${busy ? 'busy' : ''}" data-join="1">${busy ? (isLive(l) ? 'Live' : 'Full') : (state.currentLobbyId === l.id ? 'Your room' : 'Join')}</button>
          <button class="btn-ghost lobby-watch" data-watch="1">Watch</button>
        </div>`;
      card.addEventListener('click', (e) => {
        if (e.target.closest('[data-watch]')) {
          openWatch(l);
          return;
        }
        if (e.target.closest('[data-join]') && !busy && state.currentLobbyId !== l.id) {
          if (isTeam(l)) openSala(l);
          else joinSelected(l);
          return;
        }
        openSala(l);
      });
      grid.appendChild(card);
    });
  }

  function renderShop() {
    if ($('shopCoins')) $('shopCoins').textContent = String(state.coins || 0);
    if ($('shopCoinLabel')) $('shopCoinLabel').textContent = state.coinLabel || 'Coins';
    const list = state.shop || [];
    show($('shopEmpty'), list.length === 0);
    const grid = $('shopGrid');
    grid.innerHTML = '';
    list.forEach((item) => {
      const card = document.createElement('div');
      card.className = 'shop-card';
      card.innerHTML = `
        <span class="card-tag">${esc(item.category || 'GUN')}</span>
        <h3>${esc(item.label)}</h3>
        <p>Arena only. Leaves your city inventory alone.</p>
        <div class="shop-price">${item.owned ? 'OWNED' : `${item.price} ${esc(state.coinLabel || 'Coins')}`}</div>
        <button class="${item.owned ? 'btn-ghost' : 'btn-cta'}" ${item.owned ? 'disabled' : ''}>${item.owned ? 'Owned' : 'Buy'}</button>`;
      const btn = card.querySelector('button');
      btn.addEventListener('click', async () => {
        btn.disabled = true;
        const res = await nui('buyShop', { weaponId: item.id, loadoutId: item.loadoutId });
        if (res?.ok) {
          if (typeof res.coins === 'number') state.coins = res.coins;
          if (res.shop) state.shop = res.shop;
          else item.owned = true;
          if (res.loadouts) state.loadouts = res.loadouts;
          fillPlayerChrome();
          renderShop();
        } else {
          btn.disabled = false;
        }
      });
      grid.appendChild(card);
    });
  }

  function slotHtml(p, empty) {
    if (!p) return `<div class="slot empty">${empty}</div>`;
    const me = state.playerId != null && p.id === state.playerId;
    return `<div class="slot ${me ? 'me' : ''}"><span class="av">${initials(p.name)}</span><span>${esc(p.name)}${me ? ' · you' : ''}</span></div>`;
  }

  function salaIsOpen() {
    return $('sala') && !$('sala').classList.contains('hidden');
  }

  function openSala(lobby) {
    if (!state.open || !lobby) return;
    state.selected = lobby;
    const weapons = allWeapons();
    if (!state.pick.weaponId && weapons[0]) {
      state.pick.weaponId = weapons[0].id;
      state.pick.loadoutId = weapons[0].loadoutId;
    }
    $('salaName').textContent = `${lobby.sizeLabel || lobby.name}`;
    $('salaMeta').textContent = `${lobby.private ? 'Private · ' : ''}${lobby.sizeLabel || lobby.mode} · ${lobby.mapName || ''} · ${(allWeapons().find((w) => w.id === state.pick.weaponId) || {}).label || 'Loadout'}`;
    const salaShot = mapThumb(lobby);
    if ($('salaMap')) {
      $('salaMap').classList.toggle('empty', !salaShot);
      $('salaMap').style.backgroundImage = salaShot ? `url('${salaShot}')` : 'none';
    }
    const teamMode = isTeam(lobby);
    show($('salaFfa'), !teamMode);
    document.querySelector('.sala-vs').classList.toggle('hidden', !teamMode);
    const solo = (lobby.sizeLabel || '') === '1v1' || lobby.maxPlayersPerTeam === 1;
    show($('btnSwapTeam'), teamMode && !solo);
    const inThis = state.currentLobbyId && state.currentLobbyId === lobby.id;
    if ($('salaTag')) $('salaTag').textContent = lobby.private ? (lobby.code ? `CODE ${lobby.code}` : 'PRIVATE') : (inThis ? 'YOUR ROOM' : (isLive(lobby) ? 'LIVE' : 'ROOM'));
    const joinBtn = $('btnConfirmJoin');
    const leaveBtn = $('btnLeaveSala');
    if (joinBtn) {
      joinBtn.textContent = inThis ? 'In room' : 'Join';
      joinBtn.disabled = !!inThis;
    }
    if (leaveBtn) {
      leaveBtn.textContent = inThis ? '← LEAVE MATCH' : '← BACK';
      leaveBtn.classList.toggle('danger', !!inThis);
    }
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

  async function openWatch(lobby) {
    if (!lobby) return;
    state.selected = lobby;
    show($('sala'), false);
    $('watchName').textContent = `${lobby.sizeLabel || lobby.name} · ${lobby.mapName || ''}`;
    const fighters = lobby.players || [];
    $('watchFighters').innerHTML = fighters.length
      ? fighters.map((p) => `<button class="watch-pick" data-pick="${p.id}"><span>${esc(p.name)}</span><small>${p.team === 1 ? 'ORANGE' : p.team === 2 ? 'BLUE' : 'FFA'}</small></button>`).join('')
      : '<p class="sec-help">No fighters in this room yet.</p>';
    $('watchFighters').querySelectorAll('.watch-pick').forEach((btn) => {
      btn.addEventListener('click', () => {
        $('watchFighters').querySelectorAll('.watch-pick').forEach((b) => b.classList.toggle('selected', b === btn));
        state.betPick = Number(btn.dataset.pick);
      });
    });
    const money = await nui('myMoney') || { cash: 0, max: 100000 };
    $('betCash').max = money.max || 100000;
    $('betCash').placeholder = `Cash · max $${(money.max || 100000).toLocaleString()}`;
    $('betCashHint').textContent = `Wallet $${Number(money.cash || 0).toLocaleString()} · max $100,000`;
    const items = await nui('betItems') || [];
    $('betItems').innerHTML = items.length
      ? items.map((it) => `<label class="bet-item"><input type="checkbox" data-item="${esc(it.name)}" data-count="1" /><span>${esc(it.label)}</span><small>${esc(it.kind || 'item')}</small></label>`).join('')
      : '<p class="sec-help">No guns or keys in your pockets to stake.</p>';
    show($('watch'), true);
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
        <span>${esc(p.name)}</span>
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
          <strong>${esc(h.lobby_name || h.lobbyName || h.mode)}</strong>
          <div style="color:var(--muted);font-size:0.8rem">${esc((h.mode || '').toUpperCase())} · ${esc(h.scoreline || '')} · ${h.kills}/${h.deaths}</div>
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

  function ensurePick() {
    const weapons = allWeapons();
    if (!state.pick.weaponId && weapons[0]) {
      state.pick.weaponId = weapons[0].id;
      state.pick.loadoutId = weapons[0].loadoutId;
    }
    return state.pick;
  }

  let joining = false;
  async function joinSelected(lobby) {
    if (joining) return;
    if (!lobby) {
      toast('No open lobby for that mode and map.');
      return;
    }
    joining = true;
    const joinBtn = $('btnConfirmJoin');
    const arenaBtn = $('btnJoinArena');
    if (joinBtn) joinBtn.disabled = true;
    if (arenaBtn) arenaBtn.disabled = true;
    try {
      ensurePick();
      const solo = (lobby.sizeLabel || state.mode) === '1v1' || lobby.maxPlayersPerTeam === 1;
      const res = await nui('joinLobby', {
        lobbyId: lobby.id,
        loadoutId: state.pick.loadoutId,
        weaponId: state.pick.weaponId,
        team: solo ? undefined : state.pick.team,
      });
      if (res?.ok) {
        state.currentLobbyId = lobby.id;
        hideUI();
      } else {
        toast((res && res.message) || 'Could not join that lobby.');
      }
    } finally {
      joining = false;
      if (joinBtn) {
        const inThis = state.currentLobbyId && state.selected?.id === state.currentLobbyId;
        joinBtn.disabled = !!inThis;
        if (!inThis) joinBtn.textContent = 'Join';
      }
      if (arenaBtn) arenaBtn.disabled = false;
    }
  }

  function fillPlayerChrome() {
    const name = state.playerName || 'Player';
    const av = initials(name);
    const elo = (state.stats && (state.stats.pvp?.elo || state.stats.ffa?.elo)) || 1000;
    if ($('hdrName')) $('hdrName').textContent = name;
    if ($('hdrAv')) $('hdrAv').textContent = av;
    if ($('hdrElo')) $('hdrElo').textContent = String(elo);
    if ($('hdrCoins')) $('hdrCoins').textContent = String(state.coins || 0);
    if ($('shopCoins')) $('shopCoins').textContent = String(state.coins || 0);
  }

  function openUI(data) {
    try {
      data = data || {};
      state.open = true;
      state.playerId = data.playerId || null;
      state.currentLobbyId = data.current && data.current.id ? data.current.id : state.currentLobbyId;
      state.playerName = data.playerName || 'Player';
      state.loadouts = data.loadouts || [];
      state.lobbies = data.lobbies || [];
      state.shop = data.shop || [];
      state.coins = data.coins || 0;
      state.coinLabel = data.coinLabel || 'Coins';
      state.stats = data.stats || {};
      state.leaderboard = Object.assign(state.leaderboard, data.leaderboard || {});
      state.history = data.history || [];
      state.maps = data.maps || state.maps || [];
      if (data.private && data.private.firstTo) {
        Object.assign(FIRST_TO, data.private.firstTo);
      }
      const maps = mapsForMode(state.mode);
      if (maps[0] && !maps.find((m) => m.mapId === state.mapId)) state.mapId = maps[0].mapId;
      fillPlayerChrome();
      show($('app'), true);
      setTab(state.tab || 'lobbies');
    } catch (err) {
      console.error('[cursor_arena] openUI', err);
      show($('app'), true);
    }
  }

  function hideMatchChrome() {
    show($('waiting'), false);
    show($('roundBanner'), false);
    show($('countdown'), false);
    show($('bounds'), false);
    show($('deathOverlay'), false);
    show($('spectateBar'), false);
    show($('matchResult'), false);
    show($('streak'), false);
    if ($('streakCall')) show($('streakCall'), false);
  }

  function hideUI() {
    state.open = false;
    state.selected = null;
    show($('app'), false);
    show($('sala'), false);
    show($('watch'), false);
    show($('loadoutModal'), false);
  }

  function closeUI() {
    hideUI();
    nui('close');
  }

  document.querySelectorAll('.nav-tab').forEach((btn) => btn.addEventListener('click', () => setTab(btn.dataset.tab)));
  $('lobbyFilters').querySelectorAll('.chip').forEach((btn) => {
    btn.addEventListener('click', () => {
      state.lobbyFilter = btn.dataset.filter;
      $('lobbyFilters').querySelectorAll('.chip').forEach((b) => b.classList.toggle('active', b === btn));
      renderLobbies();
    });
  });
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
  document.querySelectorAll('.js-close').forEach((btn) => btn.addEventListener('click', closeUI));
  $('btnCloseSala').addEventListener('click', () => show($('sala'), false));
  $('btnCloseWatch').addEventListener('click', () => show($('watch'), false));
  $('btnWatchLive').addEventListener('click', async () => {
    if (!state.selected) return;
    const res = await nui('watchLobby', { lobbyId: state.selected.id });
    if (res?.ok) hideUI();
  });
  $('btnPlaceBet').addEventListener('click', async () => {
    if (!state.selected || !state.betPick) return;
    const cash = Math.min(100000, Math.max(0, Number($('betCash').value) || 0));
    const items = [...$('betItems').querySelectorAll('input:checked')].map((el) => ({
      name: el.dataset.item,
      count: 1,
    }));
    const res = await nui('placeBet', { lobbyId: state.selected.id, pickSrc: state.betPick, cash, items });
    if (res?.ok) {
      $('betCash').value = '';
      $('betItems').querySelectorAll('input').forEach((el) => { el.checked = false; });
    }
  });
  $('btnQuickJoin').addEventListener('click', () => {
    const open = (state.lobbies || []).find((l) => {
      if (l.private || isLive(l)) return false;
      return (l.playerCount || 0) < (l.maxPlayers || 99);
    });
    if (open) {
      if (isTeam(open) && open.maxPlayersPerTeam !== 1) openSala(open);
      else joinSelected(open);
      return;
    }
    setTab('loadout');
    joinSelected(lobbyForPick());
  });
  $('btnGoPrivate').addEventListener('click', () => setTab('private'));
  $('privTeamWrap').addEventListener('click', (e) => {
    const btn = e.target.closest('.vis-btn');
    if (!btn) return;
    state.priv.team = Number(btn.dataset.team);
    state.pick.team = state.priv.team;
    renderPrivate();
  });
  $('btnCreatePrivate').addEventListener('click', async () => {
    ensurePick();
    const res = await nui('createPrivate', {
      mode: state.priv.mode,
      mapId: state.priv.mapId,
      firstTo: state.priv.firstTo,
      team: state.priv.team,
      loadoutId: state.pick.loadoutId,
      weaponId: state.pick.weaponId,
    });
    if (res?.ok) {
      state.currentLobbyId = res.lobby?.id || state.currentLobbyId;
      hideUI();
    } else {
      toast((res && res.message) || 'Could not create that room.');
    }
  });
  async function enterByCode(watch) {
    const code = ($('lobbyCode').value || '').trim().toUpperCase();
    if (!code) return;
    ensurePick();
    const res = await nui(watch ? 'watchByCode' : 'joinByCode', {
      code,
      loadoutId: state.pick.loadoutId,
      weaponId: state.pick.weaponId,
      team: state.pick.team,
    });
    if (res?.ok) hideUI();
    else toast((res && res.message) || (watch ? 'Could not watch that room.' : 'Could not join that code.'));
  }
  $('btnJoinCode').addEventListener('click', () => enterByCode(false));
  $('btnWatchCode').addEventListener('click', () => enterByCode(true));
  $('lobbyCode').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') enterByCode(false);
  });
  $('btnLeaveSala').addEventListener('click', async () => {
    if (state.currentLobbyId && state.selected?.id === state.currentLobbyId) {
      await nui('leaveLobby');
      state.currentLobbyId = null;
      hideUI();
      return;
    }
    show($('sala'), false);
  });
  $('teamWrap').addEventListener('click', (e) => {
    const btn = e.target.closest('.vis-btn');
    if (!btn) return;
    state.pick.team = Number(btn.dataset.team);
    renderLoadout();
  });
  $('btnSwapTeam').addEventListener('click', async () => {
    const next = state.pick.team === 1 ? 2 : 1;
    state.pick.team = next;
    if (state.currentLobbyId && state.selected?.id === state.currentLobbyId) {
      const res = await nui('setTeam', { team: next });
      if (res && res.ok === false) state.pick.team = next === 1 ? 2 : 1;
    }
    if (state.selected) openSala(state.selected);
  });
  $('btnJoinArena').addEventListener('click', () => joinSelected(lobbyForPick()));
  $('btnConfirmJoin').addEventListener('click', () => joinSelected(state.selected));
  $('roomSearch').addEventListener('input', (e) => { state.roomQuery = e.target.value; renderLobbies(); });
  $('btnCancelLoadout').addEventListener('click', () => { show($('loadoutModal'), false); nui('closeLoadout'); });
  $('btnApplyLoadout').addEventListener('click', async () => {
    await nui('changeLoadout', state.livePick);
    show($('loadoutModal'), false);
  });

  function fmtTime() {
    const end = state.hudLocalEnd || (state.hudEndsAt ? state.hudEndsAt * 1000 : 0);
    if (!end) return '--:--';
    const left = Math.max(0, Math.ceil((end - Date.now()) / 1000));
    const m = Math.floor(left / 60);
    const s = left % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }

  const ICO = {
    clock: '<svg class="hud-ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="8"/><path d="M12 8v5l3 2"/></svg>',
    trophy: '<svg class="hud-ico" viewBox="0 0 24 24" fill="currentColor"><path d="M7 4h10v2h3a4 4 0 0 1-3.6 4A5.5 5.5 0 0 1 13 13.9V16h3v2H8v-2h3v-2.1A5.5 5.5 0 0 1 7.6 10 4 4 0 0 1 4 6h3V4zm-1 4a2 2 0 0 0 1.7 1H7.6A3.6 3.6 0 0 1 6 8zm12 0a3.6 3.6 0 0 1-1.6 1h.1A2 2 0 0 0 18 8z"/></svg>',
    aim: '<svg class="hud-ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="7"/><path d="M12 5v2M12 17v2M5 12h2M17 12h2"/></svg>',
    skull: '<svg class="k-skull" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3c4.4 0 8 3.2 8 7.2 0 2.4-1.2 4.4-3 5.6V18H7v-2.2c-1.8-1.2-3-3.2-3-5.6C4 6.2 7.6 3 12 3zm-3 8.2a1.3 1.3 0 1 0 0-2.6 1.3 1.3 0 0 0 0 2.6zm6 0a1.3 1.3 0 1 0 0-2.6 1.3 1.3 0 0 0 0 2.6zM9 19h6v2H9z"/></svg>',
  };

  function pipRow(score, need, side) {
    const n = Math.min(7, Math.max(1, Number(need) || 5));
    const on = Math.max(0, Number(score) || 0);
    return `<div class="hud-pips">${Array.from({ length: n }, (_, i) => `<span class="hud-pip ${i < on ? `on ${side}` : ''}"></span>`).join('')}</div>`;
  }

  function teamCls(team) {
    return Number(team) === 1 ? 't1' : Number(team) === 2 ? 't2' : '';
  }

  function readScores(raw) {
    if (Array.isArray(raw)) return { orange: raw[0] || 0, blue: raw[1] || 0 };
    const src = raw || {};
    return {
      orange: src.orange ?? src.t1 ?? src[1] ?? src['1'] ?? 0,
      blue: src.blue ?? src.t2 ?? src[2] ?? src['2'] ?? 0,
    };
  }

  function renderHud(data) {
    if (!data) return;
    const me = data.me || {};
    const myTeam = Number(data.team || me.team || 0);
    const waiting = data.waiting || data.state === 'waiting' || data.state === 'idle';
    show($('waiting'), waiting);
    if (waiting) {
      const side = myTeam === 1 ? 'ORANGE' : myTeam === 2 ? 'BLUE' : '';
      $('waitingTitle').textContent = side ? `YOU ARE ${side}` : 'WAITING';
      if ($('waitingTeam')) {
        $('waitingTeam').textContent = side;
        $('waitingTeam').className = `waiting-team ${myTeam === 1 ? 't1' : myTeam === 2 ? 't2' : 'hidden'}`;
        show($('waitingTeam'), !!side);
      }
      $('waitingSub').textContent = [
        data.mode === 'ffa'
          ? 'Need one more fighter to start'
          : myTeam === 1 ? 'Waiting for Blue'
            : myTeam === 2 ? 'Waiting for Orange'
              : 'Need both Orange and Blue to start',
        data.code ? `Code ${data.code}` : '',
      ].filter(Boolean).join(' · ');
    }
    const codeBit = data.code ? `<span class="hud-code">${esc(data.code)}</span>` : '';
    const goalBit = data.roundsToWin
      ? ` · FIRST TO ${data.roundsToWin} · ROUND ${data.round || 1}`
      : data.killsToWin
        ? ` · FIRST TO ${data.killsToWin}`
        : '';
    const mapBit = `<div class="hud-map">${esc((data.sizeLabel || data.mode || '').toUpperCase())} · ${esc((data.mapName || '').toUpperCase())}${goalBit}${data.private ? ' · PRIVATE' : ''}${codeBit}</div>`;
    if (data.mode === 'tdm' || data.mode === 'pvp' || data.mode === 'showdown') {
      if (data.endsAt) {
        state.hudEndsAt = data.endsAt;
        if (!state.hudLocalEnd) state.hudLocalEnd = data.endsAt * 1000;
      }
      const sc = readScores(data.scores);
      const firstTo = data.roundsToWin || data.killsToWin;
      const pips = data.roundsToWin;
      $('scorePlate').innerHTML = `
        <div class="hud-geo">
          <div class="hud-plate score t1 ${myTeam === 1 ? 'mine' : ''}"><span>${sc.orange}</span></div>
          ${pips ? `<div class="hud-plate pips-plate t1">${pipRow(sc.orange, firstTo, 't1')}</div>` : ''}
          <div class="hud-diamond">
            <div class="hud-diamond-inner">
              ${ICO.clock}
              <div class="hud-clock">${fmtTime()}</div>
            </div>
          </div>
          ${pips ? `<div class="hud-plate pips-plate t2">${pipRow(sc.blue, firstTo, 't2')}</div>` : ''}
          <div class="hud-plate score t2 ${myTeam === 2 ? 'mine' : ''}"><span>${sc.blue}</span></div>
        </div>
        ${mapBit}`;
    } else {
      const sorted = [...(data.players || [])].sort((a, b) => (b.kills || 0) - (a.kills || 0));
      const place = Math.max(1, sorted.findIndex((p) => p.id === me.id) + 1 || 1);
      $('scorePlate').innerHTML = `
        <div class="hud-geo">
          <div class="hud-plate stat">
            ${ICO.aim}
            <b>${me.kills || 0}</b>
          </div>
          <div class="hud-diamond">
            <div class="hud-diamond-inner">
              ${ICO.trophy}
              <div class="hud-clock">#${place}</div>
            </div>
          </div>
          <div class="hud-plate stat">
            ${ICO.skull.replace('k-skull', 'hud-ico')}
            <b>${me.deaths || 0}</b>
          </div>
        </div>
        ${mapBit}`;
    }
    const panel = $('teamPanel');
    if (data.teamPanel && (data.mode === 'tdm' || data.mode === 'pvp' || data.mode === 'showdown')) {
      show(panel, true);
      const mine = (data.players || []).filter((p) => p.team === myTeam);
      const label = myTeam === 1 ? 'YOUR SIDE · ORANGE' : myTeam === 2 ? 'YOUR SIDE · BLUE' : 'YOUR SIDE';
      panel.innerHTML = `<h4>${label}</h4>` + mine.map((p) => `
        <div class="tp-row ${p.alive === false ? 'down' : ''}"><span>${esc(p.name)}${data.titles && p.title ? ` · ${esc(p.title)}` : ''}</span><span>${p.alive === false ? '✕' : '●'}</span></div>`).join('');
    } else show(panel, false);
  }

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'open') { show($('matchHud'), false); hideMatchChrome(); openUI(msg.data || {}); }
    if (msg.action === 'close') hideUI();
    if (msg.action === 'closeLoadout') show($('loadoutModal'), false);
    if (msg.action === 'refreshLobbies') {
      nui('listLobbies').then((list) => {
        if (!list) return;
        state.lobbies = list;
        if (!state.open) return;
        if (state.tab === 'loadout') renderLoadout();
        if (state.tab === 'lobbies') renderLobbies();
        if (state.tab === 'private') renderPrivate();
        if (salaIsOpen() && state.selected) {
          const next = list.find((l) => l.id === state.selected.id);
          if (next) openSala(next);
        }
      });
    }
    if (msg.action === 'lobbyUpdate' && msg.data) {
      state.lobbies = state.lobbies.map((l) => l.id === msg.data.id ? msg.data : l);
      if (state.open && salaIsOpen() && state.selected?.id === msg.data.id) openSala(msg.data);
      if (state.open && state.tab === 'lobbies') renderLobbies();
    }
    if (msg.action === 'openLoadout') {
      const loadouts = msg.data?.loadouts || state.loadouts;
      state.livePick.loadoutId = loadouts[0]?.id;
      state.livePick.weaponId = loadouts[0]?.weapons?.[0]?.id;
      renderLoadoutPicker('liveLoadouts', 'liveWeapons', loadouts, state.livePick);
      show($('loadoutModal'), true);
    }
    if (msg.action === 'matchHud') {
      if (msg.visible) hideUI();
      else {
        hideMatchChrome();
        state.currentLobbyId = null;
        state.hudLocalEnd = 0;
      }
      show($('matchHud'), !!msg.visible);
      if (msg.visible && msg.data) renderHud(msg.data);
    }
    if (msg.action === 'timer') {
      state.hudEndsAt = msg.endsAt;
      const remain = Number(msg.remaining != null ? msg.remaining : msg.limit);
      state.hudLocalEnd = remain ? Date.now() + (remain * 1000) : (msg.endsAt ? msg.endsAt * 1000 : 0);
    }
    if (msg.action === 'killfeed' && msg.data) {
      const feed = $('killfeed');
      const d = msg.data;
      const players = d.players || [];
      const teamOf = (id, name, fallback) => {
        if (fallback) return Number(fallback);
        const hit = players.find((p) => p.id === id || p.name === name);
        return hit && hit.team;
      };
      const kt = teamCls(teamOf(d.killerId, d.killer, d.killerTeam));
      const vt = teamCls(teamOf(d.victimId, d.victim, d.victimTeam));
      const row = document.createElement('div');
      row.className = `kill-item ${d.headshot ? 'head' : ''}`;
      row.innerHTML = `<span class="k-name ${kt}">${esc(d.killer || 'World')}</span>${ICO.skull}<span class="k-name down ${vt}">${esc(d.victim)}</span>`;
      feed.prepend(row);
      while (feed.children.length > 6) feed.lastElementChild.remove();
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
      const el = $('streak');
      $('streakLabel').textContent = msg.label || '';
      const n = Number(msg.kills) || 0;
      if ($('streakKills')) $('streakKills').textContent = n ? `${n} KILLS` : '';
      el.className = `streak ${teamCls(msg.team)}`;
      show(el, true);
      clearTimeout(el._t);
      el._t = setTimeout(() => show(el, false), 2200);
    }
    if (msg.action === 'killstreakCall' && msg.data) {
      const call = $('streakCall');
      if (call) {
        $('streakCallName').textContent = msg.data.name || '';
        $('streakCallLabel').textContent = msg.data.label || '';
        show(call, true);
        clearTimeout(call._t);
        call._t = setTimeout(() => show(call, false), 1800);
      }
    }
    if (msg.action === 'countdown') {
      if (msg.seconds) hideUI();
      show($('waiting'), false);
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
    if (msg.action === 'roundBanner') {
      if (msg.visible === false) { show($('roundBanner'), false); return; }
      show($('waiting'), false);
      $('roundBannerTitle').textContent = msg.round ? `ROUND ${msg.round}` : 'ROUND';
      $('roundBannerSub').textContent = msg.winnerTeam === 1 ? 'ORANGE TAKES THE ROUND' : msg.winnerTeam === 2 ? 'BLUE TAKES THE ROUND' : 'DRAW';
      $('roundBanner').className = `round-banner ${msg.winnerTeam === 1 ? 't1' : msg.winnerTeam === 2 ? 't2' : ''}`;
      show($('roundBanner'), true);
      clearTimeout($('roundBanner')._t);
      $('roundBanner')._t = setTimeout(() => show($('roundBanner'), false), 2200);
    }
    if (msg.action === 'spectate') {
      show($('spectateBar'), !!msg.visible);
      if (msg.name) $('spectateName').textContent = msg.name;
      $('spectateHint').textContent = msg.hint || '';
    }
    if (msg.action === 'matchResult') {
      if (!msg.data) {
        show($('matchResult'), false);
        clearInterval(window._resultCd);
        return;
      }
      const el = $('matchResult');
      const res = msg.data.result || {};
      const winnerTeam = Number(res.winner || 0);
      el.className = `match-result ${msg.data.outcome || ''} ${winnerTeam === 1 ? 't1' : winnerTeam === 2 ? 't2' : ''}`;
      $('resultTitle').textContent = msg.data.outcome === 'win' ? 'VICTORY' : msg.data.outcome === 'loss' ? 'DEFEAT' : 'DRAW';
      if ($('resultWinner')) {
        $('resultWinner').textContent = res.winnerLabel || (res.winnerName || '');
      }
      $('resultSub').textContent = res.scoreline ? `Score ${res.scoreline}` : '';
      $('resultElo').textContent = msg.data.eloChange ? `${msg.data.eloChange > 0 ? '+' : ''}${msg.data.eloChange} ELO` : '';
      const board = $('resultBoard');
      if (board) {
        const rows = res.players || msg.data.players || [];
        board.innerHTML = rows.slice(0, 8).map((p) => `
          <div class="result-row ${p.won ? 'won' : ''} ${p.team === 1 ? 't1' : p.team === 2 ? 't2' : ''}">
            <span>${esc(p.name)}</span>
            <span>${p.kills || 0} / ${p.deaths || 0}</span>
            <span>${p.won ? 'WIN' : ''}</span>
          </div>`).join('');
      }
      let n = Math.max(1, Number(msg.data.sceneSeconds) || 10);
      if ($('resultCount')) $('resultCount').textContent = String(n);
      show(el, true);
      clearInterval(window._resultCd);
      window._resultCd = setInterval(() => {
        n -= 1;
        if ($('resultCount')) $('resultCount').textContent = String(Math.max(0, n));
        if (n <= 0) clearInterval(window._resultCd);
      }, 1000);
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape') return;
    if ($('loadoutModal') && !$('loadoutModal').classList.contains('hidden')) {
      show($('loadoutModal'), false);
      nui('closeLoadout');
      return;
    }
    if (salaIsOpen()) {
      show($('sala'), false);
      return;
    }
    if ($('watch') && !$('watch').classList.contains('hidden')) {
      show($('watch'), false);
      return;
    }
    if (state.open) closeUI();
  });

  setInterval(() => {
    const clock = document.querySelector('.hud-clock');
    if (clock && (state.hudLocalEnd || state.hudEndsAt) && !clock.textContent.startsWith('#')) {
      clock.textContent = fmtTime();
    }
  }, 1000);

  if (!IN_GAME) {
    document.body.classList.add('preview');
    MOCK.lobbies.forEach((l) => { l.loadouts = MOCK.loadouts; });
    const params = new URLSearchParams(location.search);
    const view = params.get('view');
    if (view === 'result') {
      window.postMessage({
        action: 'matchResult',
        data: {
          outcome: params.get('outcome') || 'win',
          eloChange: 18,
          sceneSeconds: 10,
          result: {
            winner: 1,
            winnerLabel: 'ORANGE WINS',
            scoreline: '5-3',
            players: [
              { name: 'Diesel', kills: 6, deaths: 2, won: true, team: 1 },
              { name: 'Nova', kills: 3, deaths: 5, won: false, team: 2 },
            ],
          },
        },
      }, '*');
      return;
    }
    if (view === 'hud' || view === 'waiting' || view === 'ffa' || view === 'streak') {
      state.playerId = 1;
      const side = params.get('side') === 'blue' ? 2 : 1;
      const scores = params.get('scores') === 'obj' ? { 1: 0, 2: 1 } : [0, 1];
      state.hudLocalEnd = Date.now() + 4 * 60 * 1000;
      const ffa = view === 'ffa';
      renderHud(ffa ? {
        mode: 'ffa',
        mapName: 'Park',
        sizeLabel: 'FFA',
        killsToWin: 30,
        waiting: false,
        state: 'active',
        team: 0,
        players: [
          { id: 1, name: 'Diesel', kills: 8, deaths: 2 },
          { id: 2, name: 'Nova', kills: 5, deaths: 3 },
          { id: 3, name: 'Rook', kills: 4, deaths: 4 },
        ],
        me: { id: 1, kills: 8, deaths: 2 },
      } : {
        mode: 'pvp',
        mapName: 'Stables',
        sizeLabel: '1v1',
        scores,
        round: 3,
        roundsToWin: 5,
        waiting: view === 'waiting',
        state: view === 'waiting' ? 'waiting' : 'active',
        team: side,
        teamPanel: true,
        players: [
          { id: 1, name: 'Diesel', team: 1, alive: true, title: 'Apex' },
          { id: 2, name: 'Nova', team: 2, alive: true },
        ],
        me: { id: 1, kills: 2, deaths: 1, team: side },
      });
      show($('matchHud'), true);
      setTimeout(() => {
        if (view !== 'waiting') {
          [
            { killer: 'Diesel', victim: 'Nova', killerTeam: 1, victimTeam: 2, headshot: true },
            { killer: 'Rook', victim: 'Ash', killerTeam: 2, victimTeam: 1 },
          ].forEach((d) => window.postMessage({ action: 'killfeed', data: d }, '*'));
        }
        if (view === 'streak' || view === 'ffa') {
          window.postMessage({ action: 'killstreak', label: 'DOMINATING', kills: 4, team: side }, '*');
        }
      }, 0);
      return;
    }
    const tab = params.get('tab') || 'lobbies';
    state.tab = TABS.includes(tab) ? tab : 'lobbies';
    openUI(MOCK);
  }
})();
