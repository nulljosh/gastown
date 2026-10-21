// HUD -- HTML overlay updates

import { ResourceTypes, BuildingType, BuildingTypes, selectedColonist } from './state.js';
import { listSlots } from './save.js';
import { toggleTheme, resolvedTheme } from './theme.js';

const RES_COLORS = { food:'var(--green)', power:'var(--yellow)', materials:'var(--orange)' };

const RESOURCE_META = {
    food:      { icon:'⬡', label:'FOOD' },
    power:     { icon:'◈', label:'PWR'  },
    materials: { icon:'▪', label:'MAT'  },
};

export function updateHUD(state, callbacks) {
    const hud = document.getElementById('hud');
    if (state.wallpaperMode) {
        hud.style.opacity = '0';
        hud.style.pointerEvents = 'none';
        updateToast(state);
        return;
    }
    hud.style.opacity = '1';
    hud.style.pointerEvents = 'none'; // children opt back in via CSS; 'auto' here blocked every canvas click

    updateResourceBar(state);
    updateBuildMenu(state, callbacks);
    updateColonistPanel(state, callbacks);
    updateGameLog(state);
    updateTimeDisplay(state);
    updatePauseOverlay(state, callbacks);
    updateSaveIndicator(state);
    updateSettings(state, callbacks);
    updateTutorial(state, callbacks);
    updateToast(state);
}

function updateToast(state) {
    let el = document.getElementById('toast-msg');
    if (!el) {
        el = document.createElement('div');
        el.id = 'toast-msg';
        document.body.appendChild(el);
    }
    if (state.toastMessage) {
        el.textContent = state.toastMessage.text;
        el.style.display = 'block';
        el.style.opacity = Math.min(1, state.toastMessage.ticks / 20);
    } else {
        el.style.display = 'none';
    }
}

function updateResourceBar(state) {
    const resBar = document.getElementById('resource-bar');
    resBar.textContent = '';
    for (const t of ResourceTypes) {
        const meta = RESOURCE_META[t] || { icon:'?', label:t };
        const pill = document.createElement('span');
        pill.className = 'res-pill';

        const icon = document.createElement('span');
        icon.className = 'res-icon';
        icon.style.color = RES_COLORS[t] || 'var(--text-1)';
        icon.textContent = meta.icon;
        pill.appendChild(icon);

        const val = document.createElement('span');
        val.className = 'res-val';
        val.textContent = state.resources[t] || 0;
        pill.appendChild(val);

        const lbl = document.createElement('span');
        lbl.className = 'res-label';
        lbl.textContent = meta.label;
        pill.appendChild(lbl);

        resBar.appendChild(pill);
    }
    const alive = document.createElement('span');
    alive.style.cssText = 'margin-left:auto;font-size:11px;font-weight:700;color:var(--text-2)';
    alive.textContent = `${state.colonists.length} colonists`;
    resBar.appendChild(alive);
}

function updateBuildMenu(state, callbacks) {
    const buildMenu = document.getElementById('build-menu');
    if (!state.showBuildMenu) { buildMenu.style.display = 'none'; return; }
    buildMenu.style.display = 'block';
    buildMenu.textContent = '';

    const title = document.createElement('div');
    title.className = 'hud-title hud-yellow';
    title.textContent = 'BUILD';
    buildMenu.appendChild(title);

    BuildingTypes.forEach((key, i) => {
        const bt = BuildingType[key];
        const sel = state.selectedBuildingType === key;
        const btn = document.createElement('button');
        btn.className = 'build-btn' + (sel ? ' selected' : '');
        const num = document.createElement('span');
        num.className = 'hud-pink';
        num.textContent = `${i + 1}. `;
        btn.appendChild(num);
        btn.appendChild(document.createTextNode(bt.name + ' '));
        const cost = document.createElement('span');
        cost.className = 'cost';
        cost.textContent = Object.entries(bt.cost).map(([r, a]) => {
            const m = RESOURCE_META[r];
            return m ? `${m.icon}${a}` : `${r}:${a}`;
        }).join(' ');
        btn.appendChild(cost);
        btn.onclick = () => {
            state.selectedBuildingType = key;
            state.inputMode = 'build';
            callbacks.onHudUpdate();
        };
        buildMenu.appendChild(btn);
    });

    buildMenu.appendChild(document.createElement('hr'));

    const demBtn = document.createElement('button');
    demBtn.className = 'build-btn demolish-btn' + (state.inputMode === 'demolish' ? ' selected' : '');
    demBtn.textContent = 'X. DEMOLISH';
    demBtn.onclick = () => { state.inputMode = 'demolish'; callbacks.onHudUpdate(); };
    buildMenu.appendChild(demBtn);
}

function updateColonistPanel(state) {
    const panel = document.getElementById('colonist-panel');
    const n = new Set(state.selectedColonistIds || []);
    if (state.selectedColonistId) n.add(state.selectedColonistId);
    if (!n.size) { panel.style.display = 'none'; return; }
    panel.style.display = 'block';
    panel.className = 'corners';
    panel.textContent = '';
    const c = selectedColonist(state);
    const head = document.createElement('div');
    head.className = 'hud-panel-name';
    head.textContent = n.size > 1 ? `${n.size} SELECTED` : c ? c.name : '';
    panel.appendChild(head);
    const hint = document.createElement('div');
    hint.style.cssText = 'font-size:11px;color:var(--text-2);margin-top:4px';
    hint.textContent = c && n.size === 1 ? c.job.toUpperCase() : 'Click ground to move, a resource to gather';
    panel.appendChild(hint);
}

function createHR() { return document.createElement('hr'); }

function updateGameLog(state) {
    const logEl = document.getElementById('game-log');
    logEl.textContent = '';
    state.gameLog.slice(-3).forEach(m => {
        const div = document.createElement('div');
        div.textContent = m;
        logEl.appendChild(div);
    });
}

function updateTimeDisplay(state) {
    const el = document.getElementById('time-display');
    el.textContent = `Day ${Math.floor(state.currentTick / 240) + 1} | ${state.currentHour}:00 | ${state.isNight ? 'NIGHT' : 'DAY'}`;
}

function updatePauseOverlay(state, callbacks) {
    const el = document.getElementById('pause-overlay');
    if (!state.isPaused || state.showSettings) {
        el.style.display = 'none';
        return;
    }
    el.style.display = 'flex';
    el.textContent = '';

    const card = document.createElement('div');
    card.className = 'pause-card';

    const title = document.createElement('div');
    title.className = 'pause-title';
    title.textContent = 'PAUSED';
    card.appendChild(title);

    const actions = [
        { label:'RESUME',       cls:'primary', fn: () => { state.isPaused = false; callbacks.onHudUpdate(); } },
        { label:'SAVE',         cls:'',        fn: () => { callbacks.onSaveSlot(state.lastSaveSlot || 1); } },
        { label:'SETTINGS',     cls:'',        fn: () => { state.showSettings = true; callbacks.onHudUpdate(); } },
        { label:'QUIT TO MENU', cls:'danger',  fn: () => { window._gameCallbacks?.quitToMenu?.() || window.location.reload(); } },
    ];

    for (const a of actions) {
        const btn = document.createElement('button');
        btn.className = 'pause-action-btn' + (a.cls ? ' ' + a.cls : '');
        btn.textContent = a.label;
        btn.onclick = a.fn;
        card.appendChild(btn);
    }

    el.appendChild(card);
}

function updateSaveIndicator(state) {
    document.getElementById('save-indicator').style.display = state.showSaveIndicator ? 'block' : 'none';
}

function updateSettings(state, callbacks) {
    const el = document.getElementById('settings-overlay');
    if (!state.showSettings) { el.style.display = 'none'; return; }
    el.style.display = 'flex';
    el.textContent = '';

    const panel = document.createElement('div');
    panel.className = 'settings-panel';
    panel.onclick = e => e.stopPropagation();

    const title = document.createElement('div');
    title.className = 'hud-big-title';
    title.textContent = 'SETTINGS';
    panel.appendChild(title);
    panel.appendChild(createHR());

    const ctrlTitle = document.createElement('div');
    ctrlTitle.className = 'hud-section-title';
    ctrlTitle.textContent = 'CONTROLS';
    panel.appendChild(ctrlTitle);

    const controls = [
        ['WASD / Arrows','Pan camera'], ['Scroll / Pinch','Zoom'], ['Right-drag','Pan camera'],
        ['B','Toggle build menu'], ['1-4','Select building'], ['X','Toggle demolish'],
        ['Space','Pause/resume'], ['Ctrl+S','Save game'], ['Esc','Settings / cancel'],
        ['Drag','Box select'], ['Click ground / resource','Move / gather'],
    ];
    controls.forEach(([key, action]) => {
        const row = document.createElement('div');
        row.className = 'ctrl-row';
        const k = document.createElement('span');
        k.className = 'ctrl-key';
        k.textContent = key;
        row.appendChild(k);
        row.appendChild(document.createTextNode(action));
        panel.appendChild(row);
    });

    panel.appendChild(createHR());

    const saveTitle = document.createElement('div');
    saveTitle.className = 'hud-section-title';
    saveTitle.textContent = 'SAVE / LOAD';
    panel.appendChild(saveTitle);

    const slots = listSlots();
    for (let i = 0; i < 3; i++) {
        const s = slots[i];
        const row = document.createElement('div');
        row.className = 'save-row';
        const label = document.createElement('span');
        label.style.cssText = s ? 'color:var(--text-1);font-size:12px' : 'color:var(--text-3);font-size:12px';
        label.textContent = s ? `Slot ${i + 1} — Day ${s.dayCount}` : `Slot ${i + 1} — Empty`;
        const btn = document.createElement('button');
        btn.className = 'save-btn';
        btn.textContent = 'SAVE';
        const slot = i + 1;
        btn.onclick = e => { e.stopPropagation(); callbacks.onSaveSlot(slot); };
        row.appendChild(label);
        row.appendChild(btn);
        panel.appendChild(row);
    }

    panel.appendChild(createHR());

    const appearTitle = document.createElement('div');
    appearTitle.className = 'hud-section-title';
    appearTitle.textContent = 'APPEARANCE';
    panel.appendChild(appearTitle);

    const themeRow = document.createElement('div');
    themeRow.className = 'save-row';
    const themeLabel = document.createElement('span');
    themeLabel.style.cssText = 'color:var(--text-1);font-size:12px';
    themeLabel.textContent = 'Theme';
    const themeBtn = document.createElement('button');
    themeBtn.className = 'save-btn';
    themeBtn.textContent = resolvedTheme() === 'dark' ? 'DARK' : 'LIGHT';
    themeBtn.onclick = e => {
        e.stopPropagation();
        themeBtn.textContent = toggleTheme() === 'dark' ? 'DARK' : 'LIGHT';
    };
    themeRow.appendChild(themeLabel);
    themeRow.appendChild(themeBtn);
    panel.appendChild(themeRow);

    panel.appendChild(createHR());

    const hint = document.createElement('div');
    hint.style.cssText = 'font-size:11px;color:var(--text-3)';
    hint.textContent = 'Press ESC to close';
    panel.appendChild(hint);

    el.appendChild(panel);
    el.onclick = () => { state.showSettings = false; state.isPaused = false; callbacks.onHudUpdate(); };
}

function updateTutorial(state, callbacks) {
    const el = document.getElementById('tutorial-overlay');
    if (state.tutorialStep === null || state.tutorialStep === undefined) { el.style.display = 'none'; return; }
    el.style.display = 'flex';
    el.textContent = '';

    const steps = [
        { title:'COMMAND',   body:'Click a survivor, or drag a box around several. Click the ground to move them. Click a resource and they work it until you say otherwise.', hint:'Click a colonist' },
        { title:'BUILD',     body:'Press B. A Generator makes power. A Drill next to a resource mines it for you, burning power. Shelters add beds, and a bed plus 10 food brings a new survivor each day.', hint:'Press B' },
        { title:'THE BEACON', body:'Gather materials and power, then raise the Beacon. That is the whole game.', hint:'Click to dismiss' },
    ];

    const step = state.tutorialStep;
    const data = steps[step] || steps[0];

    const panel = document.createElement('div');
    panel.className = 'tutorial-panel';

    const header = document.createElement('div');
    header.className = 'tut-header';
    const counter = document.createElement('span');
    counter.className = 'hud-muted-sm';
    counter.textContent = `TUTORIAL ${step + 1}/${steps.length}`;
    const skip = document.createElement('button');
    skip.className = 'tut-skip';
    skip.textContent = 'SKIP';
    skip.onclick = e => { e.stopPropagation(); state.tutorialStep = null; callbacks.onHudUpdate(); };
    header.appendChild(counter);
    header.appendChild(skip);
    panel.appendChild(header);

    const titleEl = document.createElement('div');
    titleEl.className = 'hud-big-title';
    titleEl.style.fontSize = '24px';
    titleEl.textContent = data.title;
    panel.appendChild(titleEl);

    const bodyEl = document.createElement('div');
    bodyEl.style.cssText = 'font-size:14px;color:var(--text-1);text-align:center';
    bodyEl.textContent = data.body;
    panel.appendChild(bodyEl);

    const hintEl = document.createElement('div');
    hintEl.className = 'tut-hint';
    hintEl.textContent = data.hint;
    panel.appendChild(hintEl);

    const dots = document.createElement('div');
    dots.className = 'tut-dots';
    for (let i = 0; i < steps.length; i++) {
        const dot = document.createElement('span');
        dot.className = 'tut-dot' + (i <= step ? ' active' : '');
        dots.appendChild(dot);
    }
    panel.appendChild(dots);

    // ponytail: only "click to continue"/"click to dismiss" steps advance on click.
    // Steps that require a real action (select a colonist, press B, place a shelter)
    // only advance via checkTutorialAdvance() below — no clicking past them.
    const clickAdvances = data.hint === 'Click to continue' || data.hint === 'Click to dismiss';
    if (clickAdvances) {
        panel.onclick = () => {
            if (step >= steps.length - 1) state.tutorialStep = null;
            else state.tutorialStep = step + 1;
            callbacks.onHudUpdate();
        };
    }

    el.appendChild(panel);
    if (clickAdvances) {
        el.onclick = e => {
            if (e.target === el) {
                if (step >= steps.length - 1) state.tutorialStep = null;
                else state.tutorialStep = step + 1;
                callbacks.onHudUpdate();
            }
        };
    }
}

export function checkTutorialAdvance(state, event) {
    if (state.tutorialStep === null || state.tutorialStep === undefined) return;
    const step = state.tutorialStep;
    if (step === 0 && event === 'colonistSelected') state.tutorialStep = 1;
    else if (step === 1 && event === 'buildMenuOpened') state.tutorialStep = 2;
}
