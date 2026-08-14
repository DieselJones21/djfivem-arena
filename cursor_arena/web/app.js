(() => {
  const app = document.getElementById('app');
  const resourceName = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'cursor_arena';

  const state = {
    open: false,
    tab: 'lobbies',
    modes: [],
    maps: [],
    weaponsByCat: {},
    choiceCategories: ['pistols', 'smgs', 'rifles'],
    playerId: null,
    playerName: 'Player',
    stats: {},
    leaderboard: [],
    lobby: null,
    ready: false,
    timerInterval: null,
    serverOffset: 0,
    // create modal
    create: {
      size: 1,
      style: 'pvp',
      weaponClass: 'pistols',
      mapId: null,
      rounds: 5,
      private: false,
      weaponId: null,
    },
    // ffa quick play
    ffa: { modeId: null, weaponId: null },
    loadoutClass: 'pistols',
  };

  async function nui(event, data = {}) {
    const resp = await fetch(`https://${resourceName}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    try { return await resp.json(); } catch { return null; }
  }

  function show(el, on = true) {
    if (!el) return;
    el.classList.toggle('hidden', !on);
  }

  function setTab(tab) {
    state.tab = tab;
    document.querySelectorAll('.nav-tab').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.tab === tab);
    });
    document.querySelectorAll('.page').forEach((page) => {
      page.classList.toggle('active', page.id === `page-${tab}`);
    });
    if (tab === 'leaderboard') renderLeaderboard();
    if (tab === 'stats') renderMyStats();
    if (tab === 'lobbies') refreshLobbies();
    if (tab === 'loadout') renderLoadout();
    if (tab === 'ffa') renderFfa();
  }

  function initials(name) {
    if (!name) return 'A';
    const parts = String(name).trim().split(/\s+/);
    return ((parts[0]?.[0] || 'A') + (parts[1]?.[0] || '')).toUpperCase();
  }

  function openUI(data) {
    state.open = true;
    state.modes = data.modes || [];
    state.maps = data.maps || [];
    state.weaponsByCat = data.weapons || {};
    state.choiceCategories = data.choiceCategories || ['pistols', 'smgs', 'rifles'];
    state.playerId = data.playerId;
    state.playerName = data.playerName || 'Player';
    state.stats = data.stats || {};
    state.leaderboard = data.leaderboard || [];
    state.lobby = null;

    document.getElementById('profileName').textContent = state.playerName;
    document.getElementById('avatarCircle').textContent = initials(state.playerName);
    document.getElementById('statElo').textContent = state.stats.elo ?? 1000;
    document.getElementById('statCoins').textContent = state.stats.wins ?? 0;

    show(app, true);
    buildCreateModal();
    if (data.queue) {
      // stay on lobbies
    }
    setTab('lobbies');
    refreshLobbies();
  }

  function closeUI() {
    state.open = false;
    show(app, false);
    show(document.getElementById('createModal'), false);
  }

  /* ---------- Lobbies list ---------- */
  async function refreshLobbies() {
    const list = await nui('listLobbies') || [];
    const wrap = document.getElementById('lobbyList');
    const empty = document.getElementById('lobbyEmpty');
    wrap.innerHTML = '';
    if (!list.length) {
      show(empty, true);
      return;
    }
    show(empty, false);
    list.forEach((lobby) => {
      const row = document.createElement('div');
      row.className = 'lobby-card';
      row.innerHTML = `
        <div>
          <strong>${lobby.modeLabel}</strong>
          <small>${lobby.mapLabel} · ${lobby.players.length}/${lobby.maxPlayers}${lobby.private ? ' · PRIVATE' : ''}</small>
        </div>
        <button class="btn-accent">Join</button>
      `;
      row.querySelector('button').addEventListener('click', async () => {
        // Use first weapon of mode if none selected from loadout
        let weaponId = state.create.weaponId || state.ffa.weaponId;
        if (!weaponId) {
          const classId = state.loadoutClass || 'pistols';
          const cat = state.weaponsByCat[classId];
          weaponId = cat?.weapons?.[0]?.id;
        }
        if (!weaponId) return;
        const res = await nui('joinLobby', { matchId: lobby.id, weaponId });
        if (res?.ok) showRoom(res.lobby);
      });
      wrap.appendChild(row);
    });
  }

  /* ---------- Create modal ---------- */
  function buildCreateModal() {
    const pvp = document.getElementById('pvpSizes');
    const tdm = document.getElementById('tdmSizes');
    pvp.innerHTML = '';
    tdm.innerHTML = '';
    for (let i = 1; i <= 5; i++) {
      pvp.appendChild(sizeBtn(i, 'pvp'));
      tdm.appendChild(sizeBtn(i, 'tdm'));
    }

    const classes = document.getElementById('weaponClasses');
    classes.innerHTML = '';
    [
      { id: 'pistols', label: 'PISTOL' },
      { id: 'smgs', label: 'SMG' },
      { id: 'rifles', label: 'RIFLE' },
    ].forEach((c) => {
      const btn = document.createElement('button');
      btn.className = 'select-opt' + (state.create.weaponClass === c.id ? ' selected' : '');
      btn.textContent = c.label;
      btn.addEventListener('click', () => {
        state.create.weaponClass = c.id;
        state.create.weaponId = null;
        buildCreateModal();
      });
      classes.appendChild(btn);
    });

    const maps = document.getElementById('arenaMaps');
    maps.innerHTML = '';
    state.maps.forEach((m) => {
      const btn = document.createElement('button');
      btn.className = 'select-opt' + (state.create.mapId === m.id ? ' selected' : '');
      btn.textContent = m.label;
      btn.addEventListener('click', () => {
        state.create.mapId = m.id;
        buildCreateModal();
      });
      maps.appendChild(btn);
    });
    if (!state.create.mapId && state.maps[0]) state.create.mapId = state.maps[0].id;

    const isTdm = state.create.style === 'tdm';
    document.getElementById('roundsLabel').textContent = isTdm
      ? 'Kills for Death Match'
      : 'Rounds for PVP Match';
    document.getElementById('roundsHint').textContent = isTdm
      ? 'Choose between 1 and 40 kill target'
      : 'Choose between 1 and 40 rounds';

    // highlight size buttons
    pvp.querySelectorAll('button').forEach((b) => {
      b.classList.toggle('selected', state.create.style === 'pvp' && Number(b.dataset.size) === state.create.size);
    });
    tdm.querySelectorAll('button').forEach((b) => {
      b.classList.toggle('selected', state.create.style === 'tdm' && Number(b.dataset.size) === state.create.size);
    });
    maps.querySelectorAll('button').forEach((b) => {
      // already set via selected class above
    });

    renderCreateWeapons();
  }

  function sizeBtn(size, style) {
    const btn = document.createElement('button');
    btn.className = 'select-opt';
    btn.dataset.size = size;
    btn.textContent = `${size}v${size} ${style.toUpperCase()}`;
    btn.addEventListener('click', () => {
      state.create.size = size;
      state.create.style = style;
      buildCreateModal();
    });
    return btn;
  }

  function renderCreateWeapons() {
    const wrap = document.getElementById('createWeapons');
    wrap.innerHTML = '';
    const cat = state.weaponsByCat[state.create.weaponClass];
    const list = cat?.weapons || [];
    list.forEach((w) => {
      const btn = document.createElement('button');
      btn.className = 'chip' + (state.create.weaponId === w.id ? ' selected' : '');
      btn.textContent = w.label;
      btn.addEventListener('click', () => {
        state.create.weaponId = w.id;
        renderCreateWeapons();
      });
      wrap.appendChild(btn);
    });
    if (!state.create.weaponId && list[0]) {
      state.create.weaponId = list[0].id;
      renderCreateWeapons();
    }
  }

  /* ---------- Room ---------- */
  function showRoom(lobby) {
    state.lobby = lobby;
    setTab('room');
    // fake nav highlight - room isn't in nav
    document.querySelectorAll('.nav-tab').forEach((b) => b.classList.remove('active'));

    document.getElementById('roomMeta').textContent =
      `${lobby.modeLabel} · ${lobby.mapLabel} · ${lobby.players.length}/${lobby.maxPlayers}` +
      (lobby.private ? ' · PRIVATE' : '');

    const teams = document.getElementById('teamLists');
    teams.innerHTML = '';
    const isTeam = lobby.modeType === 'tdm' || lobby.modeType === 'team';

    if (isTeam) {
      ['red', 'blue'].forEach((team) => {
        const col = document.createElement('div');
        col.className = `team-col ${team}`;
        col.innerHTML = `<h4>${team.toUpperCase()}</h4>`;
        lobby.players.filter((p) => p.team === team).forEach((p) => {
          const row = document.createElement('div');
          row.className = 'player-row';
          row.innerHTML = `<span>${p.name}</span><span class="${p.ready ? 'ready' : 'waiting'}">${p.ready ? 'READY' : '...'}</span>`;
          col.appendChild(row);
        });
        col.addEventListener('click', async () => {
          await nui('setTeam', { team });
          const refreshed = await nui('refreshLobby');
          if (refreshed) showRoom(refreshed);
        });
        teams.appendChild(col);
      });
    } else {
      const col = document.createElement('div');
      col.className = 'team-col ffa';
      col.innerHTML = '<h4>FIGHTERS</h4>';
      lobby.players.forEach((p) => {
        const row = document.createElement('div');
        row.className = 'player-row';
        row.innerHTML = `<span>${p.name}</span><span class="${p.ready ? 'ready' : 'waiting'}">${p.ready ? 'READY' : '...'}</span>`;
        col.appendChild(row);
      });
      teams.appendChild(col);
    }

    const me = lobby.players.find((p) => p.id === state.playerId);
    state.ready = !!(me && me.ready);
    document.getElementById('btnReady').textContent = state.ready ? 'Unready' : 'Ready';
    show(document.getElementById('btnStart'), lobby.private === true && lobby.host === state.playerId);
  }

  /* ---------- FFA ---------- */
  function renderFfa() {
    const grid = document.getElementById('ffaGrid');
    grid.innerHTML = '';
    const ffaModes = state.modes.filter((m) => m.type === 'ffa' || m.tab === 'ffa');
    ffaModes.forEach((mode) => {
      const btn = document.createElement('button');
      btn.className = 'ffa-card' + (state.ffa.modeId === mode.id ? ' selected' : '');
      btn.innerHTML = `<h3>${mode.label}</h3><p>${mode.description || ''}</p>`;
      btn.addEventListener('click', () => {
        state.ffa.modeId = mode.id;
        state.ffa.weaponId = null;
        renderFfa();
        renderFfaWeapons(mode);
      });
      grid.appendChild(btn);
    });
  }

  async function renderFfaWeapons(mode) {
    const pick = document.getElementById('ffaWeaponPick');
    const wrap = document.getElementById('ffaWeapons');
    show(pick, true);
    const weapons = await nui('getWeapons', { modeId: mode.id }) || [];
    wrap.innerHTML = '';
    weapons.forEach((w) => {
      const btn = document.createElement('button');
      btn.className = 'chip' + (state.ffa.weaponId === w.id ? ' selected' : '');
      btn.textContent = w.label;
      btn.addEventListener('click', () => {
        state.ffa.weaponId = w.id;
        renderFfaWeapons(mode);
      });
      wrap.appendChild(btn);
    });
  }

  /* ---------- Stats / Leaderboard / Loadout ---------- */
  function renderMyStats() {
    const s = state.stats || {};
    const kd = s.deaths > 0 ? (s.kills / s.deaths).toFixed(2) : (s.kills || 0);
    document.getElementById('myStatsCards').innerHTML = `
      <div class="stat-card"><span>Kills</span><strong>${s.kills || 0}</strong></div>
      <div class="stat-card"><span>Deaths</span><strong>${s.deaths || 0}</strong></div>
      <div class="stat-card"><span>K/D</span><strong>${kd}</strong></div>
      <div class="stat-card"><span>Wins</span><strong>${s.wins || 0}</strong></div>
      <div class="stat-card"><span>Losses</span><strong>${s.losses || 0}</strong></div>
      <div class="stat-card"><span>ELO</span><strong>${s.elo || 1000}</strong></div>
    `;
  }

  async function renderLeaderboard() {
    const list = await nui('getLeaderboard') || state.leaderboard || [];
    state.leaderboard = list;
    const top3 = document.getElementById('top3');
    const rows = document.getElementById('boardRows');
    top3.innerHTML = '';
    rows.innerHTML = '';

    const medals = ['🥇', '🥈', '🥉'];
    const badge = ['gold', 'silver', 'bronze'];

    for (let i = 0; i < Math.min(3, list.length); i++) {
      const p = list[i];
      const card = document.createElement('div');
      card.className = 'top-card';
      card.innerHTML = `
        <div class="rank-trophy">${medals[i]}</div>
        <div class="avatar-lg">${initials(p.name)}</div>
        ${p.gang ? `<div class="gang">${p.gang}</div>` : '<div class="gang">ARENA</div>'}
        <h3>${p.name}</h3>
        <div class="elo">${p.elo || 1000} ELO</div>
        <div class="pair">
          <div><small>KILLS</small><b>${p.kills || 0}</b></div>
          <div><small>DEATHS</small><b>${p.deaths || 0}</b></div>
        </div>
      `;
      top3.appendChild(card);
    }

    list.forEach((p, idx) => {
      const row = document.createElement('div');
      row.className = 'board-row' + (idx === 0 ? ' rank1' : '');
      const bclass = badge[idx] || '';
      row.innerHTML = `
        <span><span class="rank-badge ${bclass}">${p.rank || idx + 1}</span></span>
        <span class="player-cell">
          <span class="avatar-sm">${initials(p.name)}</span>
          ${p.gang ? `<span class="gang-tag">${p.gang}</span>` : ''}
          <span>${p.name}</span>
        </span>
        <span>${p.kills || 0}</span>
        <span>${p.deaths || 0}</span>
        <span>${p.kd ?? '0'}</span>
      `;
      rows.appendChild(row);
    });
  }

  function renderLoadout() {
    const classes = document.getElementById('loadoutClasses');
    const weapons = document.getElementById('loadoutWeapons');
    classes.innerHTML = '';
    [
      { id: 'pistols', label: 'PISTOL' },
      { id: 'smgs', label: 'SMG' },
      { id: 'rifles', label: 'RIFLE' },
    ].forEach((c) => {
      const btn = document.createElement('button');
      btn.className = 'chip' + (state.loadoutClass === c.id ? ' selected' : '');
      btn.textContent = c.label;
      btn.addEventListener('click', () => {
        state.loadoutClass = c.id;
        renderLoadout();
      });
      classes.appendChild(btn);
    });

    weapons.innerHTML = '';
    const list = state.weaponsByCat[state.loadoutClass]?.weapons || [];
    list.forEach((w) => {
      const card = document.createElement('button');
      card.className = 'weapon-card' + (state.create.weaponId === w.id ? ' selected' : '');
      card.innerHTML = `<h3>${w.label}</h3><p>${w.ammo || 0} ammo</p>`;
      card.addEventListener('click', () => {
        state.create.weaponId = w.id;
        state.create.weaponClass = state.loadoutClass;
        renderLoadout();
      });
      weapons.appendChild(card);
    });
  }

  /* ---------- HUD helpers ---------- */
  function formatTime(total) {
    total = Math.max(0, Math.floor(total));
    const m = Math.floor(total / 60);
    const s = total % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }

  function startTimer(endsAt, serverNow) {
    if (state.timerInterval) clearInterval(state.timerInterval);
    if (!endsAt) return;
    const localNow = Math.floor(Date.now() / 1000);
    state.serverOffset = (serverNow || localNow) - localNow;
    const tick = () => {
      const now = Math.floor(Date.now() / 1000) + state.serverOffset;
      document.getElementById('hudTimer').textContent = formatTime(endsAt - now);
    };
    tick();
    state.timerInterval = setInterval(tick, 500);
  }

  function updateHud(data = {}) {
    if (data.modeLabel) document.getElementById('hudMode').textContent = data.modeLabel;
    if (data.mapLabel) document.getElementById('hudMap').textContent = data.mapLabel;
    const score = document.getElementById('hudScore');
    if (data.scores && data.scores.red != null) {
      score.innerHTML = `<span class="red">RED ${data.scores.red}</span><span class="blue">BLUE ${data.scores.blue}</span>`;
    }
    if (data.players && data.players.every((p) => p.team === 'ffa')) {
      const top = [...data.players].sort((a, b) => (b.kills || 0) - (a.kills || 0)).slice(0, 5);
      score.innerHTML = top.map((p) => `<span>${p.name} ${p.kills || 0}</span>`).join(' ');
    }
    if (data.endsAt) startTimer(data.endsAt, data.serverNow);
  }

  function pushKillfeed(entry) {
    const feed = document.getElementById('killfeed');
    const item = document.createElement('div');
    item.className = 'kill-item';
    item.textContent = entry.killer ? `${entry.killer} ✖ ${entry.victim}` : `${entry.victim} died`;
    feed.prepend(item);
    setTimeout(() => item.remove(), 4000);
  }

  /* ---------- Events ---------- */
  document.getElementById('btnClose').addEventListener('click', () => nui('close'));
  document.getElementById('btnOpenCreate').addEventListener('click', () => {
    buildCreateModal();
    show(document.getElementById('createModal'), true);
  });
  document.getElementById('btnCloseCreate').addEventListener('click', () => show(document.getElementById('createModal'), false));
  document.getElementById('btnCancelCreate').addEventListener('click', () => show(document.getElementById('createModal'), false));

  document.getElementById('roundsInput').addEventListener('change', (e) => {
    state.create.rounds = Math.max(1, Math.min(40, Number(e.target.value) || 5));
  });
  document.getElementById('privateCheck').addEventListener('change', (e) => {
    state.create.private = !!e.target.checked;
  });

  document.getElementById('btnConfirmCreate').addEventListener('click', async () => {
    state.create.rounds = Math.max(1, Math.min(40, Number(document.getElementById('roundsInput').value) || 5));
    if (!state.create.mapId || !state.create.weaponId) return;
    const res = await nui('createLobby', {
      size: state.create.size,
      style: state.create.style,
      weaponClass: state.create.weaponClass,
      mapId: state.create.mapId,
      rounds: state.create.rounds,
      private: state.create.private,
      weaponId: state.create.weaponId,
    });
    if (res?.ok) {
      show(document.getElementById('createModal'), false);
      showRoom(res.lobby);
    }
  });

  document.getElementById('btnFfaQueue').addEventListener('click', async () => {
    if (!state.ffa.modeId || !state.ffa.weaponId) return;
    const res = await nui('joinQueue', {
      modeId: state.ffa.modeId,
      weaponId: state.ffa.weaponId,
      mapId: null,
    });
    if (res?.ok && (res.data?.type === 'lobby' || res.data?.type === 'matched')) {
      showRoom(res.data.lobby);
    }
  });

  document.getElementById('btnReady').addEventListener('click', async () => {
    const res = await nui('setReady', {
      ready: !state.ready,
      weaponId: state.create.weaponId || state.ffa.weaponId,
    });
    if (res?.ok && res.lobby) showRoom(res.lobby);
  });
  document.getElementById('btnStart').addEventListener('click', async () => { await nui('startMatch'); });
  document.getElementById('btnLeaveLobby').addEventListener('click', async () => {
    await nui('leave');
    state.lobby = null;
    setTab('lobbies');
  });

  document.querySelectorAll('.nav-tab').forEach((btn) => {
    btn.addEventListener('click', () => setTab(btn.dataset.tab));
  });

  window.addEventListener('message', (event) => {
    const msg = event.data;
    if (!msg || !msg.action) return;

    switch (msg.action) {
      case 'open': openUI(msg.data || {}); break;
      case 'close': closeUI(); break;
      case 'lobbyUpdate': if (msg.data) showRoom(msg.data); break;
      case 'queueMatched': if (msg.data) showRoom(msg.data); break;
      case 'matchHud':
        show(document.getElementById('matchHud'), !!msg.visible);
        if (msg.visible && msg.data) updateHud(msg.data);
        if (!msg.visible && state.timerInterval) {
          clearInterval(state.timerInterval);
          state.timerInterval = null;
        }
        break;
      case 'timer': startTimer(msg.endsAt, msg.serverNow); break;
      case 'killfeed':
        pushKillfeed(msg.data || {});
        if (msg.data) updateHud(msg.data);
        break;
      case 'countdown': {
        const el = document.getElementById('countdown');
        const num = document.getElementById('countdownNum');
        if (!msg.seconds) { show(el, false); break; }
        show(el, true);
        let left = msg.seconds;
        num.textContent = left;
        const iv = setInterval(() => {
          left -= 1;
          if (left <= 0) { clearInterval(iv); show(el, false); return; }
          num.textContent = left;
        }, 1000);
        break;
      }
      case 'deathOverlay':
        show(document.getElementById('deathOverlay'), !!msg.visible);
        break;
      case 'matchResult': {
        const wrap = document.getElementById('matchResult');
        if (!msg.data) { show(wrap, false); break; }
        const title = document.getElementById('resultTitle');
        const sub = document.getElementById('resultSub');
        title.textContent = msg.data.outcome === 'win' ? 'VICTORY' : msg.data.outcome === 'loss' ? 'DEFEAT' : 'DRAW';
        sub.textContent = msg.data.result?.winnerName
          || (msg.data.result?.winnerTeam ? `${msg.data.result.winnerTeam.toUpperCase()} wins` : '');
        show(wrap, true);
        setTimeout(() => show(wrap, false), 3500);
        break;
      }
      default: break;
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && state.open) {
      if (!document.getElementById('createModal').classList.contains('hidden')) {
        show(document.getElementById('createModal'), false);
      } else {
        nui('close');
      }
    }
  });
})();
