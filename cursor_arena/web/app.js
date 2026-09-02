(() => {
  const IN_GAME = typeof GetParentResourceName === 'function';
  const resourceName = IN_GAME ? GetParentResourceName() : 'cursor_arena';

  const state = {
    open: false,
    page: 'arenas',
    modeFilter: 'all',
    boardMode: 'ffa',
    playerName: 'Player',
    playerId: 0,
    lobbies: [],
    loadouts: [],
    stats: {},
    leaderboard: { ffa: [], tdm: [], showdown: [] },
    history: [],
    selected: null,
    pick: { loadoutId: null, weaponId: null, team: 1 },
    livePick: { loadoutId: null, weaponId: null },
    hudTimer: null,
    endsAt: 0,
  };

  const MOCK = {
    playerId: 1,
    playerName: 'Diesel',
    loadouts: [
      { id: 'duelist', label: 'Duelist', description: 'Pistols', weapons: [
        { id: 'pistol', label: 'Pistol', weapon: 'WEAPON_PISTOL' },
        { id: 'appistol', label: 'AP Pistol', weapon: 'WEAPON_APPISTOL' },
      ]},
      { id: 'raider', label: 'Raider', description: 'SMGs', weapons: [
        { id: 'smg', label: 'SMG', weapon: 'WEAPON_SMG' },
      ]},
      { id: 'assault', label: 'Assault', description: 'Rifles', weapons: [
        { id: 'carbinerifle', label: 'Carbine Rifle', weapon: 'WEAPON_CARBINERIFLE' },
      ]},
    ],
    lobbies: [
      { id: 'construction_ffa', name: 'Construction FFA', description: 'Every floor is a fight. First to 30.', mode: 'ffa', mapName: 'Construction', mapImage: 'assets/map_construction.svg', playerCount: 6, maxPlayers: 16, killsToWin: 30, state: 'active', scores: { 1: 0, 2: 0 }, players: [
        { id: 1, name: 'Diesel', kills: 8, deaths: 2, team: 0 },
        { id: 2, name: 'Nova', kills: 6, deaths: 4, team: 0 },
      ], loadouts: null, kill_rewards: { health: 25 } },
      { id: 'dust_tdm', name: 'Dust TDM', description: 'Two sides, one strip of sand.', mode: 'tdm', mapName: 'Dust', mapImage: 'assets/map_docks.svg', playerCount: 8, maxPlayers: 16, maxPlayersPerTeam: 8, killsToWin: 50, state: 'active', scores: { 1: 22, 2: 18 }, players: [
        { id: 1, name: 'Diesel', kills: 7, deaths: 3, team: 1, alive: true },
        { id: 3, name: 'Rook', kills: 5, deaths: 5, team: 2, alive: true },
      ], kill_rewards: { health: 20 }, win_rewards: { money: 500 } },
      { id: 'rooftops_showdown', name: 'Rooftops Showdown', description: 'One life. Ranked.', mode: 'showdown', mapName: 'Rooftops', mapImage: 'assets/map_rooftops.svg', playerCount: 6, maxPlayers: 10, maxPlayersPerTeam: 5, roundsToWin: 5, round: 3, state: 'active', scores: { 1: 2, 2: 1 }, players: [
        { id: 1, name: 'Diesel', kills: 4, deaths: 1, team: 1, alive: true, title: 'Apex' },
        { id: 4, name: 'Vex', kills: 2, deaths: 2, team: 1, alive: false },
        { id: 5, name: 'Ash', kills: 3, deaths: 1, team: 2, alive: true },
      ], win_rewards: { money: 1200 } },
    ],
    stats: {
      ffa: { kills: 120, deaths: 88, wins: 14, matches: 31, elo: 1000 },
      tdm: { kills: 90, deaths: 70, wins: 11, matches: 22, elo: 1000 },
      showdown: { kills: 40, deaths: 28, wins: 9, matches: 16, elo: 1180 },
    },
    leaderboard: {
      ffa: [
        { rank: 1, name: 'Diesel', title: 'Champion', kills: 120, kd: 1.36, elo: 1000 },
        { rank: 2, name: 'Nova', title: 'Warlord', kills: 101, kd: 1.21, elo: 1000 },
        { rank: 3, name: 'Rook', title: 'Executioner', kills: 88, kd: 1.05, elo: 1000 },
      ],
      tdm: [],
      showdown: [
        { rank: 1, name: 'Diesel', title: 'Apex', kills: 40, kd: 1.42, elo: 1180 },
      ],
    },
    history: [
      { lobby_name: 'Rooftops Showdown', mode: 'showdown', won: 1, kills: 6, deaths: 2, scoreline: '5-3', elo_change: 18 },
      { lobby_name: 'Dust TDM', mode: 'tdm', won: 0, kills: 9, deaths: 8, scoreline: '41-50', elo_change: 0 },
    ],
  };

  async function nui(event, data = {}) {
    if (!IN_GAME) {
      if (event === 'listLobbies') return state.lobbies;
      if (event === 'getLobby') return state.lobbies.find((l) => l.id === data.lobbyId) || state.selected;
      if (event === 'getLeaderboard') return state.leaderboard[data.mode] || [];
      if (event === 'getMyStats') return state.stats;
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

  function initials(name) {
    const parts = String(name || 'A').trim().split(/\s+/);
    return ((parts[0]?.[0] || 'A') + (parts[1]?.[0] || '')).toUpperCase();
  }

  function modeLabel(mode) {
    return mode === 'tdm' ? 'TDM' : mode === 'showdown' ? 'SHOWDOWN' : 'FFA';
  }

  function setPage(page) {
    state.page = page;
    document.querySelectorAll('.rail-btn').forEach((b) => b.classList.toggle('active', b.dataset.page === page));
    document.querySelectorAll('.page').forEach((p) => p.classList.toggle('active', p.id === `page-${page}`));
    const titles = {
      arenas: ['Choose a fight', 'Every lobby is its own world. Pick a side, pick a loadout, drop in.'],
      leaderboard: ['Ranks', 'Titles follow the top ten. Showdown runs on ELO.'],
      history: ['Match history', 'Scoreline, roster, and what it did to your rating.'],
      stats: ['Your record', 'Kills, deaths, wins and playtime — per mode.'],
    };
    $('pageTitle').textContent = titles[page][0];
    $('pageSub').textContent = titles[page][1];
    $('modeFilters').style.display = page === 'arenas' ? '' : 'none';
    if (page === 'leaderboard') renderBoard();
    if (page === 'history') renderHistory();
    if (page === 'stats') renderStats();
    if (page === 'arenas') renderLobbies();
  }

  function renderLobbies() {
    const grid = $('lobbyGrid');
    const empty = $('lobbyEmpty');
    grid.innerHTML = '';
    const list = (state.lobbies || []).filter((l) => state.modeFilter === 'all' || l.mode === state.modeFilter);
    show(empty, list.length === 0);
    list.forEach((lobby) => {
      const card = document.createElement('button');
      card.className = 'lobby-card';
      const live = lobby.state === 'active' || lobby.state === 'countdown';
      card.innerHTML = `
        <div class="thumb" style="background-image:url('${lobby.mapImage || ''}')">
          <span class="mode-pill ${lobby.mode}">${modeLabel(lobby.mode)}</span>
        </div>
        <div class="body">
          <h3>${lobby.name}</h3>
          <p>${lobby.description || lobby.mapName || ''}</p>
          <div class="meta">
            <span>${lobby.playerCount || 0}/${lobby.maxPlayers || 0}</span>
            <span class="${live ? 'dot-live' : ''}">${live ? '● LIVE' : (lobby.state || 'idle').toUpperCase()}</span>
          </div>
        </div>`;
      card.addEventListener('click', () => openDrawer(lobby));
      grid.appendChild(card);
    });
  }

  function openDrawer(lobby) {
    state.selected = lobby;
    const loadouts = lobby.loadouts && lobby.loadouts.length ? lobby.loadouts : state.loadouts;
    state.pick.loadoutId = loadouts[0]?.id;
    state.pick.weaponId = loadouts[0]?.weapons?.[0]?.id;
    state.pick.team = 1;

    $('drawerName').textContent = lobby.name;
    $('drawerDesc').textContent = lobby.description || '';
    $('drawerImage').src = lobby.mapImage || '';
    const pill = $('drawerMode');
    pill.textContent = modeLabel(lobby.mode);
    pill.className = `mode-pill ${lobby.mode}`;
    $('drawerMeta').innerHTML = `
      <span>${lobby.mapName || ''}</span>
      <span>${lobby.playerCount || 0} / ${lobby.maxPlayers || 0} fighters</span>
      <span>${lobby.mode === 'showdown' ? `First to ${lobby.roundsToWin} rounds` : `First to ${lobby.killsToWin} kills`}</span>`;

    const team = $('teamPick');
    show(team, lobby.mode === 'tdm' || lobby.mode === 'showdown');
    team.querySelectorAll('.team-btn').forEach((b) => {
      b.classList.toggle('selected', Number(b.dataset.team) === state.pick.team);
    });

    renderLoadoutPicker('drawerLoadouts', 'drawerWeapons', loadouts, state.pick);
    renderLiveBoard(lobby);
    const kr = lobby.kill_rewards || {};
    const wr = lobby.win_rewards || {};
    const bits = [];
    if (kr.health) bits.push(`+${kr.health} HP / kill`);
    if (kr.armor) bits.push(`+${kr.armor} armour / kill`);
    if (wr.money) bits.push(`$${wr.money} to winners`);
    $('drawerRewards').textContent = bits.join(' · ') || 'No extra payouts';
    show($('drawer'), true);
  }

  function renderLoadoutPicker(listId, wepId, loadouts, pick) {
    const list = $(listId);
    const weps = $(wepId);
    list.innerHTML = '';
    weps.innerHTML = '';
    (loadouts || []).forEach((l) => {
      const btn = document.createElement('button');
      btn.className = `chip ${pick.loadoutId === l.id ? 'selected' : ''}`;
      btn.textContent = l.label;
      btn.addEventListener('click', () => {
        pick.loadoutId = l.id;
        pick.weaponId = l.weapons?.[0]?.id;
        renderLoadoutPicker(listId, wepId, loadouts, pick);
      });
      list.appendChild(btn);
    });
    const current = (loadouts || []).find((l) => l.id === pick.loadoutId);
    (current?.weapons || []).forEach((w) => {
      const btn = document.createElement('button');
      btn.className = `chip ${pick.weaponId === w.id ? 'selected' : ''}`;
      btn.textContent = w.label;
      btn.addEventListener('click', () => {
        pick.weaponId = w.id;
        renderLoadoutPicker(listId, wepId, loadouts, pick);
      });
      weps.appendChild(btn);
    });
  }

  function renderLiveBoard(lobby) {
    const box = $('drawerBoard');
    const players = lobby.players || [];
    if (!players.length) {
      box.innerHTML = '<div class="live-row"><span>Waiting for fighters</span></div>';
      return;
    }
    box.innerHTML = players.slice(0, 10).map((p) => `
      <div class="live-row">
        <span>${p.team === 1 ? 'A' : p.team === 2 ? 'B' : '#'} ${p.name}${p.title ? ` · ${p.title}` : ''}</span>
        <span>${p.kills || 0}/${p.deaths || 0}</span>
      </div>`).join('');
  }

  function renderBoard() {
    const rows = state.leaderboard[state.boardMode] || [];
    const top = $('top3');
    top.innerHTML = '';
    rows.slice(0, 3).forEach((p, i) => {
      const el = document.createElement('div');
      el.className = 'top-card';
      el.innerHTML = `
        <div class="avatar-lg">${initials(p.name)}</div>
        <div class="title-chip">${p.title || ''}</div>
        <h3>${p.name}</h3>
        <small>${state.boardMode === 'showdown' ? `ELO ${p.elo}` : `${p.kills} kills`}</small>`;
      top.appendChild(el);
      if (i > 2) return;
    });
    $('boardRows').innerHTML = rows.map((p) => `
      <div class="board-row">
        <span><span class="rank-badge ${p.rank === 1 ? 'gold' : p.rank === 2 ? 'silver' : p.rank === 3 ? 'bronze' : ''}">${p.rank}</span></span>
        <span>${p.name}</span>
        <span>${p.title || '—'}</span>
        <span>${p.kills}</span>
        <span>${p.kd}</span>
        <span>${p.elo}</span>
      </div>`).join('');
  }

  function renderHistory() {
    const list = $('historyList');
    const empty = $('historyEmpty');
    const rows = state.history || [];
    show(empty, rows.length === 0);
    list.innerHTML = rows.map((h) => `
      <div class="history-row ${h.won ? 'win' : 'loss'}">
        <div>
          <strong>${h.lobby_name || h.lobbyName || h.mode}</strong>
          <div style="color:var(--muted);font-size:0.8rem">${(h.mode || '').toUpperCase()} · ${h.scoreline || ''} · ${h.kills}/${h.deaths}</div>
        </div>
        <div>${h.won ? 'WIN' : 'LOSS'} ${h.elo_change || h.eloChange ? `(${(h.elo_change || h.eloChange) > 0 ? '+' : ''}${h.elo_change || h.eloChange})` : ''}</div>
      </div>`).join('');
  }

  function renderStats() {
    const grid = $('statsGrid');
    grid.innerHTML = '';
    ['ffa', 'tdm', 'showdown'].forEach((mode) => {
      const s = state.stats[mode] || {};
      const kd = s.deaths ? (s.kills / s.deaths).toFixed(2) : (s.kills || 0);
      [
        [mode.toUpperCase() + ' kills', s.kills || 0],
        [mode.toUpperCase() + ' deaths', s.deaths || 0],
        [mode.toUpperCase() + ' wins', s.wins || 0],
        [mode.toUpperCase() + ' K/D', kd],
        [mode.toUpperCase() + ' ELO', s.elo || 1000],
      ].forEach(([label, val]) => {
        const el = document.createElement('div');
        el.className = 'stat-card';
        el.innerHTML = `<span>${label}</span><strong>${val}</strong>`;
        grid.appendChild(el);
      });
    });
  }

  function openUI(data) {
    state.open = true;
    state.playerName = data.playerName || 'Player';
    state.playerId = data.playerId;
    state.loadouts = data.loadouts || [];
    state.lobbies = data.lobbies || [];
    state.stats = data.stats || {};
    state.leaderboard = data.leaderboard || state.leaderboard;
    state.history = data.history || [];
    $('profileName').textContent = state.playerName;
    $('avatarCircle').textContent = initials(state.playerName);
    const sd = state.stats.showdown || {};
    $('profileTitle').textContent = sd.elo ? `ELO ${sd.elo}` : 'Unranked';
    show($('app'), true);
    setPage('arenas');
  }

  function closeUI() {
    state.open = false;
    show($('app'), false);
    show($('drawer'), false);
    show($('loadoutModal'), false);
    nui('close');
  }

  document.querySelectorAll('.rail-btn').forEach((btn) => {
    btn.addEventListener('click', () => setPage(btn.dataset.page));
  });
  document.querySelectorAll('#modeFilters .mode-chip').forEach((btn) => {
    btn.addEventListener('click', () => {
      state.modeFilter = btn.dataset.mode;
      document.querySelectorAll('#modeFilters .mode-chip').forEach((b) => b.classList.toggle('active', b === btn));
      renderLobbies();
    });
  });
  document.querySelectorAll('#boardModes .mode-chip').forEach((btn) => {
    btn.addEventListener('click', async () => {
      state.boardMode = btn.dataset.board;
      document.querySelectorAll('#boardModes .mode-chip').forEach((b) => b.classList.toggle('active', b === btn));
      const list = await nui('getLeaderboard', { mode: state.boardMode });
      if (list) state.leaderboard[state.boardMode] = list;
      renderBoard();
    });
  });
  $('btnClose').addEventListener('click', closeUI);
  $('btnCloseDrawer').addEventListener('click', () => show($('drawer'), false));
  $('teamPick').addEventListener('click', (e) => {
    const btn = e.target.closest('.team-btn');
    if (!btn) return;
    state.pick.team = Number(btn.dataset.team);
    $('teamPick').querySelectorAll('.team-btn').forEach((b) => b.classList.toggle('selected', b === btn));
  });
  $('btnJoin').addEventListener('click', async () => {
    if (!state.selected) return;
    const res = await nui('joinLobby', {
      lobbyId: state.selected.id,
      loadoutId: state.pick.loadoutId,
      weaponId: state.pick.weaponId,
      team: state.pick.team,
    });
    if (res?.ok) {
      show($('drawer'), false);
      closeUI();
    }
  });
  $('btnCancelLoadout').addEventListener('click', () => {
    show($('loadoutModal'), false);
    nui('close');
  });
  $('btnApplyLoadout').addEventListener('click', async () => {
    await nui('changeLoadout', state.livePick);
    show($('loadoutModal'), false);
  });

  function renderHud(data) {
    if (!data) return;
    const plate = $('scorePlate');
    const me = data.me || {};
    if (data.mode === 'tdm' || data.mode === 'showdown') {
      plate.innerHTML = `
        <div class="mode">${modeLabel(data.mode)}${data.round ? ` · ROUND ${data.round}` : ''}</div>
        <div class="nums"><span class="t1">${data.scores?.[1] || 0}</span> — <span class="t2">${data.scores?.[2] || 0}</span></div>
        <div class="sub">${me.kills || 0} / ${me.deaths || 0} · ${data.mapName || ''}</div>`;
    } else {
      const sorted = [...(data.players || [])].sort((a, b) => (b.kills || 0) - (a.kills || 0));
      const place = Math.max(1, sorted.findIndex((p) => p.id === me.id) + 1 || 1);
      const lead = sorted[0]?.kills || 0;
      plate.innerHTML = `
        <div class="mode">FREE FOR ALL</div>
        <div class="nums">${me.kills || 0} <span style="color:var(--muted);font-size:1.1rem">kills</span></div>
        <div class="sub">#${place} · lead ${lead} / ${data.killsToWin || 30} · ${me.deaths || 0} deaths</div>`;
    }

    const panel = $('teamPanel');
    if (data.teamPanel) {
      show(panel, true);
      const mine = (data.players || []).filter((p) => p.team === data.team);
      panel.innerHTML = `<h4>YOUR SIDE</h4>` + mine.map((p) => `
        <div class="tp-row ${p.alive === false ? 'down' : ''}">
          <span>${p.name}${data.titles && p.title ? ` · ${p.title}` : ''}</span>
          <span>${p.alive === false ? '✕' : '●'}</span>
        </div>`).join('');
    } else {
      show(panel, false);
    }
  }

  window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'open') {
      show($('matchHud'), false);
      openUI(msg.data || {});
    }
    if (msg.action === 'close') {
      state.open = false;
      show($('app'), false);
      show($('drawer'), false);
      show($('loadoutModal'), false);
    }
    if (msg.action === 'refreshLobbies') {
      nui('listLobbies').then((list) => {
        if (list) { state.lobbies = list; if (state.page === 'arenas') renderLobbies(); }
      });
    }
    if (msg.action === 'lobbyUpdate' && msg.data) {
      state.lobbies = state.lobbies.map((l) => l.id === msg.data.id ? msg.data : l);
      if (state.selected?.id === msg.data.id) openDrawer(msg.data);
    }
    if (msg.action === 'openLoadout') {
      const loadouts = msg.data?.loadouts || state.loadouts;
      state.livePick.loadoutId = loadouts[0]?.id;
      state.livePick.weaponId = loadouts[0]?.weapons?.[0]?.id;
      renderLoadoutPicker('liveLoadouts', 'liveWeapons', loadouts, state.livePick);
      show($('loadoutModal'), true);
    }
    if (msg.action === 'matchHud') {
      show($('matchHud'), !!msg.visible);
      if (msg.visible && msg.data) renderHud(msg.data);
    }
    if (msg.action === 'killfeed' && msg.data) {
      const feed = $('killfeed');
      const row = document.createElement('div');
      row.className = 'kill-item';
      row.innerHTML = `<strong>${msg.data.killer || 'World'}</strong><span class="wep">${(msg.data.category || '').toUpperCase()}</span>${msg.data.victim}`;
      feed.prepend(row);
      setTimeout(() => row.remove(), 4200);
      if (feed.children.length > 6) feed.lastChild.remove();
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
      $('streakName').textContent = '';
      const el = $('streak');
      show(el, true);
      clearTimeout(el._t);
      el._t = setTimeout(() => show(el, false), 1600);
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
    if (msg.action === 'bounds') {
      show($('bounds'), !!msg.visible);
      if (msg.visible) $('boundsNum').textContent = msg.seconds;
    }
    if (msg.action === 'deathOverlay') show($('deathOverlay'), !!msg.visible);
    if (msg.action === 'spectate') {
      show($('spectateBar'), !!msg.visible);
      if (msg.name) $('spectateName').textContent = msg.name;
      $('spectateHint').textContent = msg.hint || '';
    }
    if (msg.action === 'matchResult') {
      if (!msg.data) { show($('matchResult'), false); return; }
      const d = msg.data;
      $('resultTitle').textContent = d.outcome === 'win' ? 'VICTORY' : d.outcome === 'loss' ? 'DEFEAT' : 'DRAW';
      $('resultSub').textContent = d.result?.scoreline ? `Score ${d.result.scoreline}` : '';
      $('resultElo').textContent = d.eloChange ? `${d.eloChange > 0 ? '+' : ''}${d.eloChange} ELO` : '';
      show($('matchResult'), true);
      setTimeout(() => show($('matchResult'), false), 6500);
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && (state.open || !$('loadoutModal').classList.contains('hidden'))) {
      closeUI();
    }
  });

  if (!IN_GAME) {
    MOCK.lobbies.forEach((l) => { l.loadouts = MOCK.loadouts; });
    openUI(MOCK);
    show($('matchHud'), true);
    renderHud({
      mode: 'showdown', round: 3, scores: { 1: 2, 2: 1 }, mapName: 'Rooftops',
      killsToWin: 5, teamPanel: true, team: 1, titles: true,
      me: { id: 1, kills: 4, deaths: 1 },
      players: MOCK.lobbies[2].players,
    });
  }
})();
