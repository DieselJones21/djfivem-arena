(() => {
  const app = document.getElementById('app');
  const state = {
    open: false,
    modes: [],
    maps: [],
    weaponsByCat: {},
    choiceCategories: [],
    selectedMode: null,
    selectedMap: null,
    selectedWeapon: null,
    weaponFilter: 'all',
    modeWeapons: [],
    lobby: null,
    queue: null,
    ready: false,
    playerId: null,
    timerInterval: null,
    serverOffset: 0,
  };

  const resourceName = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'cursor_arena';

  async function nui(event, data = {}) {
    const resp = await fetch(`https://${resourceName}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    try {
      return await resp.json();
    } catch {
      return null;
    }
  }

  function show(el, on = true) {
    el.classList.toggle('hidden', !on);
  }

  function setStep(step) {
    document.querySelectorAll('.step').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.step === step);
      const order = ['mode', 'map', 'weapon', 'lobby'];
      const idx = order.indexOf(btn.dataset.step);
      const cur = order.indexOf(step);
      btn.classList.toggle('done', idx < cur);
    });
    document.querySelectorAll('.panel').forEach((panel) => {
      panel.classList.toggle('active', panel.id === `panel-${step}`);
    });
  }

  function renderModes() {
    const grid = document.getElementById('modeGrid');
    grid.innerHTML = '';
    state.modes.forEach((mode) => {
      const btn = document.createElement('button');
      btn.className = 'select-tile' + (state.selectedMode?.id === mode.id ? ' selected' : '');
      btn.style.setProperty('--accent', mode.color || '#ff5a1f');
      btn.innerHTML = `
        <h3>${mode.label}</h3>
        <p>${mode.description}</p>
        <div class="meta">
          <span>${mode.minPlayers}-${mode.maxPlayers} players</span>
          <span>${Math.round((mode.timeLimit || 0) / 60)}m</span>
          <span>${mode.type.toUpperCase()}</span>
        </div>
      `;
      btn.addEventListener('click', async () => {
        state.selectedMode = mode;
        state.selectedMap = null;
        state.selectedWeapon = null;
        state.weaponFilter = 'all';
        renderModes();
        const maps = await nui('getMaps', { modeId: mode.id });
        state.maps = maps || [];
        renderMaps();
        const weapons = await nui('getWeapons', { modeId: mode.id });
        state.modeWeapons = weapons || [];
        renderWeaponCats();
        renderWeapons();
        setStep('map');
      });
      grid.appendChild(btn);
    });
  }

  function renderMaps() {
    const grid = document.getElementById('mapGrid');
    grid.innerHTML = '';
    state.maps.forEach((map) => {
      const btn = document.createElement('button');
      btn.className = 'select-tile map-tile' + (state.selectedMap?.id === map.id ? ' selected' : '');
      btn.style.backgroundImage = map.image ? `url('${map.image}')` : 'none';
      btn.innerHTML = `
        <div class="map-veil"></div>
        <div class="map-copy">
          <h3>${map.label}</h3>
          <p>${map.description || ''}</p>
        </div>
      `;
      btn.addEventListener('click', () => {
        state.selectedMap = map;
        renderMaps();
        setStep('weapon');
      });
      grid.appendChild(btn);
    });
  }

  function renderWeaponCats() {
    const wrap = document.getElementById('weaponCats');
    wrap.innerHTML = '';
    const cats = new Set(state.modeWeapons.map((w) => w.category));
    const all = document.createElement('button');
    all.className = 'chip' + (state.weaponFilter === 'all' ? ' active' : '');
    all.textContent = 'All';
    all.addEventListener('click', () => {
      state.weaponFilter = 'all';
      renderWeaponCats();
      renderWeapons();
    });
    wrap.appendChild(all);

    cats.forEach((cat) => {
      const chip = document.createElement('button');
      chip.className = 'chip' + (state.weaponFilter === cat ? ' active' : '');
      const label = state.modeWeapons.find((w) => w.category === cat)?.categoryLabel || cat;
      chip.textContent = label;
      chip.addEventListener('click', () => {
        state.weaponFilter = cat;
        renderWeaponCats();
        renderWeapons();
      });
      wrap.appendChild(chip);
    });
  }

  function renderWeapons() {
    const grid = document.getElementById('weaponGrid');
    grid.innerHTML = '';
    const list = state.modeWeapons.filter((w) =>
      state.weaponFilter === 'all' ? true : w.category === state.weaponFilter
    );
    list.forEach((w) => {
      const btn = document.createElement('button');
      btn.className = 'select-tile' + (state.selectedWeapon?.id === w.id ? ' selected' : '');
      btn.innerHTML = `
        <h3>${w.label}</h3>
        <p>${w.categoryLabel || w.category}</p>
        <div class="meta"><span>${w.ammo || 0} ammo</span></div>
      `;
      btn.addEventListener('click', () => {
        state.selectedWeapon = w;
        renderWeapons();
        renderLobbySummary();
        setStep('lobby');
      });
      grid.appendChild(btn);
    });
  }

  function renderLobbySummary() {
    const el = document.getElementById('lobbySummary');
    el.innerHTML = `
      <div class="summary-block"><span>Mode</span><strong>${state.selectedMode?.label || '—'}</strong></div>
      <div class="summary-block"><span>Map</span><strong>${state.selectedMap?.label || 'Any / Queue'}</strong></div>
      <div class="summary-block"><span>Weapon</span><strong>${state.selectedWeapon?.label || '—'}</strong></div>
    `;
  }

  function renderQueue(data) {
    const el = document.getElementById('queueStatus');
    if (!data) {
      show(el, false);
      return;
    }
    state.queue = data;
    el.textContent = `In queue for ${data.modeLabel || data.modeId} — ${data.waiting || data.position}/${data.needed} players`;
    show(el, true);
  }

  function renderLobbyRoom(lobby) {
    const room = document.getElementById('lobbyRoom');
    if (!lobby) {
      show(room, false);
      return;
    }
    state.lobby = lobby;
    show(room, true);
    show(document.getElementById('queueStatus'), false);

    document.getElementById('lobbyMeta').textContent =
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
          if (refreshed) renderLobbyRoom(refreshed);
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

    const me = lobby.players.find((p) => p.id === state.playerId)
      || lobby.players.find((p) => p.weapon === state.selectedWeapon?.id)
      || lobby.players[0];
    state.ready = !!(me && me.ready);
    document.getElementById('btnReady').textContent = state.ready ? 'Unready' : 'Ready';

    const startBtn = document.getElementById('btnStart');
    show(startBtn, lobby.private === true && lobby.host === state.playerId);
  }

  async function browseLobbies() {
    const list = await nui('listLobbies');
    const wrap = document.getElementById('openLobbies');
    wrap.innerHTML = '';
    if (!list || !list.length) {
      wrap.innerHTML = '<div class="lobby-row"><span>No open lobbies</span></div>';
      show(wrap, true);
      return;
    }
    list.forEach((lobby) => {
      const row = document.createElement('div');
      row.className = 'lobby-row';
      row.innerHTML = `
        <div>
          <strong>${lobby.modeLabel}</strong> · ${lobby.mapLabel}
          <div style="color:var(--muted);font-size:0.85rem">${lobby.players.length}/${lobby.maxPlayers} players</div>
        </div>
        <button>Join</button>
      `;
      row.querySelector('button').addEventListener('click', async () => {
        if (!state.selectedWeapon) return;
        const res = await nui('joinLobby', {
          matchId: lobby.id,
          weaponId: state.selectedWeapon.id,
        });
        if (res?.ok) {
          renderLobbyRoom(res.lobby);
        }
      });
      wrap.appendChild(row);
    });
    show(wrap, true);
  }

  function openUI(data) {
    state.open = true;
    state.modes = data.modes || [];
    state.weaponsByCat = data.weapons || {};
    state.choiceCategories = data.choiceCategories || [];
    state.playerId = data.playerId || null;
    state.selectedMode = null;
    state.selectedMap = null;
    state.selectedWeapon = null;
    state.lobby = null;
    state.queue = data.queue || null;
    show(app, true);
    renderModes();
    renderLobbySummary();
    setStep('mode');
    if (state.queue) renderQueue(state.queue);
  }

  function closeUI() {
    state.open = false;
    show(app, false);
  }

  // Buttons
  document.getElementById('btnClose').addEventListener('click', () => nui('close'));
  document.getElementById('btnRandomMap').addEventListener('click', () => {
    state.selectedMap = null;
    renderMaps();
    setStep('weapon');
  });

  document.querySelectorAll('.step').forEach((btn) => {
    btn.addEventListener('click', () => {
      if (btn.dataset.step === 'map' && !state.selectedMode) return;
      if (btn.dataset.step === 'weapon' && !state.selectedMode) return;
      if (btn.dataset.step === 'lobby' && !state.selectedWeapon) return;
      setStep(btn.dataset.step);
    });
  });

  document.getElementById('btnQueue').addEventListener('click', async () => {
    if (!state.selectedMode || !state.selectedWeapon) return;
    const res = await nui('joinQueue', {
      modeId: state.selectedMode.id,
      weaponId: state.selectedWeapon.id,
      mapId: state.selectedMap?.id || null,
    });
    if (!res?.ok) return;
    if (res.data?.type === 'lobby' || res.data?.type === 'matched') {
      renderLobbyRoom(res.data.lobby);
    } else if (res.data?.type === 'queued') {
      renderQueue({
        modeId: res.data.modeId,
        modeLabel: state.selectedMode.label,
        position: res.data.position,
        waiting: res.data.position,
        needed: res.data.needed,
      });
    }
  });

  document.getElementById('btnPrivate').addEventListener('click', async () => {
    if (!state.selectedMode || !state.selectedWeapon) return;
    if (!state.selectedMap) {
      // require map for private
      setStep('map');
      return;
    }
    const res = await nui('createPrivate', {
      modeId: state.selectedMode.id,
      mapId: state.selectedMap.id,
      weaponId: state.selectedWeapon.id,
    });
    if (res?.ok) renderLobbyRoom(res.lobby);
  });

  document.getElementById('btnBrowse').addEventListener('click', browseLobbies);
  document.getElementById('btnExitHub').addEventListener('click', () => nui('exitHub'));

  document.getElementById('btnReady').addEventListener('click', async () => {
    const res = await nui('setReady', {
      ready: !state.ready,
      weaponId: state.selectedWeapon?.id,
    });
    if (res?.ok && res.lobby) renderLobbyRoom(res.lobby);
  });

  document.getElementById('btnStart').addEventListener('click', async () => {
    await nui('startMatch');
  });

  document.getElementById('btnLeaveLobby').addEventListener('click', async () => {
    await nui('leave');
    state.lobby = null;
    state.queue = null;
    show(document.getElementById('lobbyRoom'), false);
    show(document.getElementById('queueStatus'), false);
  });

  // Match HUD helpers
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
    const hud = document.getElementById('matchHud');
    if (data.modeLabel) document.getElementById('hudMode').textContent = data.modeLabel;
    if (data.mapLabel) document.getElementById('hudMap').textContent = data.mapLabel;

    const score = document.getElementById('hudScore');
    if (data.scores && (data.team === 'red' || data.team === 'blue' || data.scores.red != null)) {
      if (data.players && data.team === 'ffa') {
        // handled below
      } else if (data.scores.red != null) {
        score.innerHTML = `<span class="red">RED ${data.scores.red}</span><span class="blue">BLUE ${data.scores.blue}</span>`;
      }
    }

    if (data.players && Array.isArray(data.players)) {
      const ffa = data.players.every((p) => p.team === 'ffa');
      if (ffa) {
        const top = [...data.players].sort((a, b) => (b.kills || 0) - (a.kills || 0)).slice(0, 5);
        score.innerHTML = `<div class="ffa-list">${top.map((p) => `<span>${p.name} ${p.kills || 0}</span>`).join('')}</div>`;
      }
    }

    if (data.endsAt) startTimer(data.endsAt, data.serverNow);
  }

  function pushKillfeed(entry) {
    const feed = document.getElementById('killfeed');
    const item = document.createElement('div');
    item.className = 'kill-item';
    if (entry.killer) {
      item.textContent = `${entry.killer} ✖ ${entry.victim}`;
    } else {
      item.textContent = `${entry.victim} died`;
    }
    feed.prepend(item);
    setTimeout(() => item.remove(), 4000);
  }

  window.addEventListener('message', (event) => {
    const msg = event.data;
    if (!msg || !msg.action) return;

    switch (msg.action) {
      case 'open':
        openUI(msg.data || {});
        break;
      case 'close':
        closeUI();
        break;
      case 'lobbyUpdate':
        renderLobbyRoom(msg.data);
        break;
      case 'queueMatched':
        renderLobbyRoom(msg.data);
        break;
      case 'matchHud':
        show(document.getElementById('matchHud'), !!msg.visible);
        if (msg.visible && msg.data) updateHud(msg.data);
        if (!msg.visible && state.timerInterval) {
          clearInterval(state.timerInterval);
          state.timerInterval = null;
        }
        break;
      case 'timer':
        startTimer(msg.endsAt, msg.serverNow);
        break;
      case 'killfeed':
        pushKillfeed(msg.data || {});
        if (msg.data) updateHud(msg.data);
        break;
      case 'countdown': {
        const el = document.getElementById('countdown');
        const num = document.getElementById('countdownNum');
        if (!msg.seconds) {
          show(el, false);
          break;
        }
        show(el, true);
        let left = msg.seconds;
        num.textContent = left;
        num.style.animation = 'none';
        void num.offsetWidth;
        num.style.animation = '';
        const iv = setInterval(() => {
          left -= 1;
          if (left <= 0) {
            clearInterval(iv);
            show(el, false);
            return;
          }
          num.textContent = left;
          num.style.animation = 'none';
          void num.offsetWidth;
          num.style.animation = '';
        }, 1000);
        break;
      }
      case 'deathOverlay':
        show(document.getElementById('deathOverlay'), !!msg.visible);
        break;
      case 'matchResult': {
        const wrap = document.getElementById('matchResult');
        if (!msg.data) {
          show(wrap, false);
          break;
        }
        const title = document.getElementById('resultTitle');
        const sub = document.getElementById('resultSub');
        if (msg.data.outcome === 'win') title.textContent = 'VICTORY';
        else if (msg.data.outcome === 'loss') title.textContent = 'DEFEAT';
        else title.textContent = 'DRAW';
        sub.textContent = msg.data.result?.winnerName
          || (msg.data.result?.winnerTeam ? `${msg.data.result.winnerTeam.toUpperCase()} wins` : '');
        show(wrap, true);
        setTimeout(() => show(wrap, false), 3500);
        break;
      }
      default:
        break;
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && state.open) nui('close');
  });
})();
