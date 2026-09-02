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
  const TABS = ['lobbies', 'loadout', 'shop', 'ranking', 'history'];
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
    show($('teamWrap'), state.mode !== 'ffa');
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
    if (joinCta) joinCta.disabled = !lobby || !state.pick.weaponId;
  }

  function renderLobbies() {
    const q = (state.roomQuery || '').toLowerCase();
    const filter = state.lobbyFilter || 'all';
    const list = state.lobbies.filter((l) => {
      const size = String(l.sizeLabel || l.mode || '').toLowerCase();
      if (filter !== 'all' && size !== filter && String(l.mode || '').toLowerCase() !== filter) return false;
      const host = l.players?.[0]?.name || '';
      const hay = `${l.sizeLabel || ''} ${l.mapName || ''} ${l.name || ''} ${l.mode || ''} ${host}`.toLowerCase();
      return !q || hay.includes(q);
    });
    show($('roomsEmpty'), list.length === 0);
    const grid = $('roomGrid');
    grid.innerHTML = '';
    list.forEach((l) => {
      const st = statusOf(l);
      const host = l.players?.[0]?.name || 'Open lobby';
      const busy = isLive(l) || ((l.playerCount || 0) >= (l.maxPlayers || 0) && l.maxPlayers);
      const wep = weaponLabel(l.players?.[0]?.weapon);
      const card = document.createElement('div');
      const shot = mapThumb(l);
      card.className = 'lobby-card';
      card.innerHTML = `
        <div class="lobby-shot ${shot ? '' : 'empty'}" style="${shot ? `background-image:url('${shot}')` : ''}"></div>
        <div class="lobby-body">
          <div class="lobby-top">
            <div class="lobby-host">${esc(host)}<small>Host</small></div>
            <div class="lobby-badges">
              <span class="mode-pill">${esc(l.sizeLabel || l.mode)}</span>
              <span class="status ${st.cls}">${st.label}</span>
            </div>
          </div>
          <div class="lobby-rows">
            <div>Weapon <b>${esc(wep)}</b></div>
            <div>Arena <b>${esc(l.mapName || '—')}</b></div>
            <div>${l.killsToWin ? 'Kills' : 'Rounds'} <b>${l.killsToWin || l.roundsToWin || 0}</b></div>
            <div>Players <b>${l.playerCount || 0} / ${l.maxPlayers || 0}</b></div>
          </div>
          <button class="lobby-join ${busy ? 'busy' : ''}" data-join="1">${busy ? (isLive(l) ? 'Match in progress' : 'Full') : (state.currentLobbyId === l.id ? 'Your room' : 'Join lobby')}</button>
        </div>`;
      card.addEventListener('click', (e) => {
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
    $('salaMeta').textContent = `${lobby.sizeLabel || lobby.mode} · ${lobby.mapName || ''} · ${(allWeapons().find((w) => w.id === state.pick.weaponId) || {}).label || 'Loadout'}`;
    const salaShot = mapThumb(lobby);
    if ($('salaMap')) {
      $('salaMap').classList.toggle('empty', !salaShot);
      $('salaMap').style.backgroundImage = salaShot ? `url('${salaShot}')` : 'none';
    }
    const teamMode = isTeam(lobby);
    show($('salaFfa'), !teamMode);
    document.querySelector('.sala-vs').classList.toggle('hidden', !teamMode);
    show($('btnSwapTeam'), teamMode);
    const inThis = state.currentLobbyId && state.currentLobbyId === lobby.id;
    if ($('salaTag')) $('salaTag').textContent = inThis ? 'YOUR ROOM' : (isLive(lobby) ? 'LIVE' : 'ROOM');
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

  let joining = false;
  async function joinSelected(lobby) {
    if (!lobby || joining) return;
    joining = true;
    const joinBtn = $('btnConfirmJoin');
    const arenaBtn = $('btnJoinArena');
    if (joinBtn) joinBtn.disabled = true;
    if (arenaBtn) arenaBtn.disabled = true;
    try {
      const res = await nui('joinLobby', {
        lobbyId: lobby.id,
        loadoutId: state.pick.loadoutId,
        weaponId: state.pick.weaponId,
        team: state.pick.team,
      });
      if (res?.ok) {
        state.currentLobbyId = lobby.id;
        hideUI();
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
    const maps = mapsForMode(state.mode);
    if (maps[0] && !maps.find((m) => m.mapId === state.mapId)) state.mapId = maps[0].mapId;
    fillPlayerChrome();
    show($('app'), true);
    setTab(state.tab || 'lobbies');
  }

  function hideMatchChrome() {
    show($('waiting'), false);
    show($('roundBanner'), false);
    show($('countdown'), false);
    show($('bounds'), false);
    show($('deathOverlay'), false);
    show($('spectateBar'), false);
    show($('matchResult'), false);
  }

  function hideUI() {
    state.open = false;
    state.selected = null;
    show($('app'), false);
    show($('sala'), false);
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
  $('btnQuickJoin').addEventListener('click', () => setTab('loadout'));
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
    const waiting = data.waiting || data.state === 'waiting' || data.state === 'idle';
    show($('waiting'), waiting);
    if (waiting) {
      $('waitingTitle').textContent = 'WAITING';
      $('waitingSub').textContent = data.mode === 'ffa' || data.mode === 'tdm'
        ? 'Need one more fighter to start'
        : 'Need both Orange and Blue to start';
    }
    const mapBit = data.mapName ? `<div class="hud-map">${(data.sizeLabel || data.mode || '').toUpperCase()} · ${(data.mapName || '').toUpperCase()}</div>` : '';
    if (data.mode === 'tdm' || data.mode === 'pvp' || data.mode === 'showdown') {
      state.hudEndsAt = data.endsAt || state.hudEndsAt;
      const roundLabel = data.roundsToWin ? `${data.round || 1}/${data.roundsToWin}` : `${data.round || 1}`;
      $('scorePlate').innerHTML = `
        <div class="hud-side"><span class="hud-tag t1">ORANGE</span><span class="hud-score">${data.scores?.[1] || 0}</span></div>
        <div class="hud-timer">
          <span class="hud-round">${roundLabel}</span>
          <div class="hud-ring">${fmtTime(state.hudEndsAt)}</div>
        </div>
        <div class="hud-side"><span class="hud-score">${data.scores?.[2] || 0}</span><span class="hud-tag t2">BLUE</span></div>
        ${mapBit}`;
    } else {
      const sorted = [...(data.players || [])].sort((a, b) => (b.kills || 0) - (a.kills || 0));
      const place = Math.max(1, sorted.findIndex((p) => p.id === me.id) + 1 || 1);
      $('scorePlate').innerHTML = `
        <div class="hud-ffa">
          <div class="mode">FREE FOR ALL</div>
          <div class="hud-score">${me.kills || 0}</div>
          <div class="mode">#${place} · ${data.killsToWin || 30} TO WIN</div>
        </div>
        ${mapBit}`;
    }
    const panel = $('teamPanel');
    if (data.teamPanel && !waiting) {
      show(panel, true);
      const mine = (data.players || []).filter((p) => p.team === data.team);
      const label = data.team === 1 ? 'ORANGE' : data.team === 2 ? 'BLUE' : 'YOUR SIDE';
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
      }
      show($('matchHud'), !!msg.visible);
      if (msg.visible && msg.data) renderHud(msg.data);
    }
    if (msg.action === 'timer') { state.hudEndsAt = msg.endsAt; }
    if (msg.action === 'killfeed' && msg.data) {
      const feed = $('killfeed');
      const row = document.createElement('div');
      row.className = 'kill-item';
      row.innerHTML = `<strong>${esc(msg.data.killer || 'World')}</strong><span class="wep">${esc((msg.data.category || '').toUpperCase())}</span>${esc(msg.data.victim)}`;
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
      hideUI();
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
      $('roundBannerSub').textContent = msg.winnerTeam === 1 ? 'ORANGE TOOK IT' : msg.winnerTeam === 2 ? 'BLUE TOOK IT' : '';
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
      if (!msg.data) { show($('matchResult'), false); return; }
      const el = $('matchResult');
      el.className = `match-result ${msg.data.outcome || ''}`;
      $('resultTitle').textContent = msg.data.outcome === 'win' ? 'VICTORY' : msg.data.outcome === 'loss' ? 'DEFEAT' : 'DRAW';
      $('resultSub').textContent = msg.data.result?.scoreline ? `Score ${msg.data.result.scoreline}` : '';
      $('resultElo').textContent = msg.data.eloChange ? `${msg.data.eloChange > 0 ? '+' : ''}${msg.data.eloChange} ELO` : '';
      show(el, true);
      setTimeout(() => show(el, false), 6500);
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
    if (state.open) closeUI();
  });

  setInterval(() => {
    const ring = document.querySelector('.hud-ring');
    if (ring && state.hudEndsAt) ring.textContent = fmtTime(state.hudEndsAt);
  }, 1000);

  if (!IN_GAME) {
    document.body.classList.add('preview');
    MOCK.lobbies.forEach((l) => { l.loadouts = MOCK.loadouts; });
    const params = new URLSearchParams(location.search);
    const view = params.get('view');
    if (view === 'hud' || view === 'waiting') {
      state.playerId = 1;
      renderHud({
        mode: 'pvp',
        mapName: 'Stables',
        sizeLabel: '1v1',
        scores: { 1: 2, 2: 1 },
        round: 3,
        roundsToWin: 5,
        waiting: view === 'waiting',
        state: view === 'waiting' ? 'waiting' : 'active',
        team: 1,
        teamPanel: true,
        players: [
          { id: 1, name: 'Diesel', team: 1, alive: true, title: 'Apex' },
          { id: 2, name: 'Nova', team: 2, alive: true },
        ],
        me: { id: 1, kills: 2 },
      });
      show($('matchHud'), true);
      return;
    }
    const tab = params.get('tab') || 'lobbies';
    state.tab = TABS.includes(tab) ? tab : 'lobbies';
    openUI(MOCK);
  }
})();
