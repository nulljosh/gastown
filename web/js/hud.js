// HUD -- HTML overlay updates

import { ResourceTypes, BuildingType, BuildingTypes, ColonistJobs,
    Traits, WeaponTypes, selectedColonist, colonistXpForNext, colonistXpProgress,
    questLevel, questTitle, questXPProgress, activeQuests, completedQuests,
    DifficultyXP, CategoryInfo, colonistClass, DifficultyRanks, QuestCategories,
    currentPhase, GamePhase } from './state.js';
import { listSlots } from './save.js';
import { QUEST_WORK_TICKS } from './systems.js';
import { toggleTheme, resolvedTheme } from './theme.js';

const RES_COLORS = { food:'var(--green)', power:'var(--yellow)', materials:'var(--orange)', oxygen:'var(--cyan)', cash:'var(--pink)' };
const STATE_COLORS = { healthy:'var(--green)', hungry:'var(--yellow)', suffocating:'var(--cyan)', exhausted:'var(--orange)', dead:'var(--text-3)' };

const RESOURCE_META = {
    food:      { icon:'⬡', label:'FOOD' },
    power:     { icon:'◈', label:'PWR'  },
    materials: { icon:'▪', label:'MAT'  },
    oxygen:    { icon:'◎', label:'O₂'  },
    cash:      { icon:'$', label:'CASH' },
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
    updatePlayerProfile(state);
    updateBuildMenu(state, callbacks);
    updateColonistPanel(state, callbacks);
    updateGameLog(state);
    updateTimeDisplay(state);
    updatePauseOverlay(state, callbacks);
    updateSaveIndicator(state);
    updateSettings(state, callbacks);
    updateTutorial(state, callbacks);
    updateQuestBoard(state);
    updateToast(state);
}

function updatePlayerProfile(state) {
    let el = document.getElementById('player-profile');
    if (!el) {
        el = document.createElement('div');
        el.id = 'player-profile';
        document.getElementById('hud').appendChild(el);
    }
    const prog = questXPProgress(state.playerXP);
    const title = questTitle(prog.level);
    const alive = state.colonists.filter(c => c.state !== 'dead').length;

    el.textContent = '';
    const titleDiv = document.createElement('div');
    titleDiv.className = 'pp-title';
    titleDiv.textContent = `Lvl ${prog.level} ${title}`;
    el.appendChild(titleDiv);

    const track = document.createElement('div');
    track.className = 'pp-xp-track';
    const fill = document.createElement('div');
    fill.className = 'pp-xp-fill';
    fill.style.width = Math.min(prog.percent, 100) + '%';
    track.appendChild(fill);
    el.appendChild(track);

    const stats = document.createElement('div');
    stats.className = 'pp-stats';
    stats.textContent = `${state.playerXP} XP | ${state.playerStreak}d streak | ${alive} alive`;
    el.appendChild(stats);

    const quests = document.createElement('div');
    quests.className = 'pp-quests';
    quests.textContent = `${activeQuests(state).length} active quests [Q]`;
    quests.onclick = () => { state.showQuestBoard = !state.showQuestBoard; };
    el.appendChild(quests);
}

function updateQuestBoard(state) {
    let el = document.getElementById('quest-board');
    if (!el) {
        el = document.createElement('div');
        el.id = 'quest-board';
        document.getElementById('hud').appendChild(el);
    }
    el.style.display = state.showQuestBoard ? 'block' : 'none';
    if (!state.showQuestBoard) return;

    const active = activeQuests(state);
    const done = completedQuests(state);
    el.textContent = '';

    const header = document.createElement('div');
    header.className = 'qb-header';
    header.textContent = 'QUEST BOARD';
    const close = document.createElement('span');
    close.className = 'qb-close';
    close.textContent = 'X';
    close.onclick = () => { state.showQuestBoard = false; };
    header.appendChild(close);
    el.appendChild(header);

    const addBtn = document.createElement('div');
    addBtn.className = 'qb-add';
    addBtn.textContent = '+ ADD QUEST';
    el.appendChild(addBtn);

    const form = document.createElement('div');
    form.className = 'qb-form';
    form.style.display = 'none';

    const titleInput = document.createElement('input');
    titleInput.className = 'qb-input';
    titleInput.placeholder = 'Quest name...';
    form.appendChild(titleInput);

    const row1 = document.createElement('div');
    row1.className = 'qb-row';
    const diffSel = document.createElement('select');
    diffSel.className = 'qb-select';
    DifficultyRanks.forEach(r => {
        const opt = document.createElement('option');
        opt.value = r;
        opt.textContent = `${r} (${DifficultyXP[r]}xp)`;
        if (r === 'C') opt.selected = true;
        diffSel.appendChild(opt);
    });
    row1.appendChild(diffSel);
    const catSel = document.createElement('select');
    catSel.className = 'qb-select';
    QuestCategories.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c;
        opt.textContent = CategoryInfo[c].label;
        catSel.appendChild(opt);
    });
    row1.appendChild(catSel);
    form.appendChild(row1);

    const row2 = document.createElement('div');
    row2.className = 'qb-row';
    const submitBtn = document.createElement('button');
    submitBtn.className = 'qb-btn';
    submitBtn.textContent = 'INSCRIBE';
    submitBtn.onclick = () => {
        const t = titleInput.value.trim();
        if (!t) return;
        window._gameCallbacks?.addQuest({ title: t, difficulty: diffSel.value, category: catSel.value });
        form.style.display = 'none';
        titleInput.value = '';
    };
    row2.appendChild(submitBtn);
    const cancelBtn = document.createElement('button');
    cancelBtn.className = 'qb-btn dim';
    cancelBtn.textContent = 'CANCEL';
    cancelBtn.onclick = () => { form.style.display = 'none'; };
    row2.appendChild(cancelBtn);
    form.appendChild(row2);
    el.appendChild(form);
    addBtn.onclick = () => { form.style.display = form.style.display === 'none' ? 'block' : 'none'; };

    const secActive = document.createElement('div');
    secActive.className = 'qb-section';
    secActive.textContent = `ACTIVE (${active.length})`;
    el.appendChild(secActive);

    for (const q of active) {
        const cat = CategoryInfo[q.category] || {};
        const row = document.createElement('div');
        row.className = 'qb-quest';
        const rank = document.createElement('span');
        rank.className = 'qb-rank';
        rank.style.color = cat.color || 'var(--text-1)';
        rank.textContent = q.difficulty;
        row.appendChild(rank);
        const name = document.createElement('span');
        name.className = 'qb-name';
        name.textContent = q.title;
        row.appendChild(name);
        const xp = document.createElement('span');
        xp.className = 'qb-xp';
        xp.textContent = (DifficultyXP[q.difficulty] || 50) + 'xp';
        row.appendChild(xp);
        const check = document.createElement('span');
        check.className = 'qb-complete';
        check.textContent = '✓';
        check.onclick = () => { window._gameCallbacks?.completeQuest(q.id); };
        row.appendChild(check);
        el.appendChild(row);
    }

    if (done.length) {
        const secDone = document.createElement('div');
        secDone.className = 'qb-section';
        secDone.textContent = `COMPLETED (${done.length})`;
        el.appendChild(secDone);
        for (const q of done.slice(0, 10)) {
            const row = document.createElement('div');
            row.className = 'qb-quest done';
            const name = document.createElement('span');
            name.className = 'qb-name';
            name.textContent = q.title;
            row.appendChild(name);
            el.appendChild(row);
        }
    }
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
    alive.textContent = `${state.colonists.filter(c => c.state !== 'dead').length} alive`;
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

function updateColonistPanel(state, callbacks) {
    const panel = document.getElementById('colonist-panel');
    const col = selectedColonist(state);
    if (!col) { panel.style.display = 'none'; return; }
    panel.style.display = 'block';
    panel.className = 'corners';
    panel.textContent = '';

    const trait = Traits[col.trait];
    const weapon = WeaponTypes[col.weapon];

    const header = document.createElement('div');
    header.className = 'panel-header';
    const nameEl = document.createElement('span');
    nameEl.className = 'hud-panel-name';
    nameEl.textContent = col.name;
    const lvl = document.createElement('span');
    lvl.className = 'hud-panel-level';
    lvl.textContent = `Lv.${col.level}`;
    header.appendChild(nameEl);
    header.appendChild(lvl);
    panel.appendChild(header);

    const stateEl = document.createElement('div');
    stateEl.style.cssText = `color:${STATE_COLORS[col.state]};font-size:11px`;
    stateEl.textContent = col.state.toUpperCase();
    panel.appendChild(stateEl);

    const traitEl = document.createElement('div');
    traitEl.className = 'trait-badge';
    traitEl.textContent = `${trait.name.toUpperCase()} ${trait.desc}`;
    panel.appendChild(traitEl);

    panel.appendChild(createHR());
    panel.appendChild(createNeedBar('HP',  col.health,         '#ff453a'));
    panel.appendChild(createNeedBar('HNG', col.hunger,         '#30d158'));
    panel.appendChild(createNeedBar('O2',  col.oxygen,         '#64d2ff'));
    panel.appendChild(createNeedBar('STS', 100 - col.stress,   '#ff375f'));
    panel.appendChild(createNeedBar('SLP', col.sleep,          '#0071e3'));
    panel.appendChild(createHR());

    const statsTitle = document.createElement('div');
    statsTitle.style.cssText = 'font-size:10px;color:var(--text-2);font-weight:bold';
    statsTitle.textContent = 'STATS';
    panel.appendChild(statsTitle);

    panel.appendChild(createStatBar('STR', col.stats.str));
    panel.appendChild(createStatBar('INT', col.stats.int));
    panel.appendChild(createStatBar('AGI', col.stats.agi));
    panel.appendChild(createStatBar('END', col.stats.end));
    panel.appendChild(createStatBar('CHA', col.stats.cha));
    panel.appendChild(createXPBar(col));
    panel.appendChild(createHR());

    const jobLabel = document.createElement('div');
    jobLabel.style.cssText = 'font-size:10px;color:var(--text-2);font-weight:bold';
    jobLabel.textContent = `JOB: ${col.job.toUpperCase()}`;
    panel.appendChild(jobLabel);

    const jobBtns = document.createElement('div');
    jobBtns.className = 'job-buttons';
    ColonistJobs.forEach(job => {
        const btn = document.createElement('button');
        btn.className = 'job-btn' + (col.job === job ? ' active' : '');
        btn.textContent = job.slice(0, 4).toUpperCase();
        btn.onclick = () => {
            const idx = state.colonists.findIndex(c => c.id === state.selectedColonistId);
            if (idx >= 0) { state.colonists[idx].job = job; callbacks.onHudUpdate(); }
        };
        jobBtns.appendChild(btn);
    });
    panel.appendChild(jobBtns);
    panel.appendChild(createHR());

    const weaponEl = document.createElement('div');
    weaponEl.style.fontSize = '10px';
    weaponEl.textContent = `WEAPON: ${weapon.name}  DMG:${Math.floor(weapon.damage)} RNG:${weapon.range}`;
    panel.appendChild(weaponEl);

    const posEl = document.createElement('div');
    posEl.style.cssText = 'font-size:10px;color:var(--text-3)';
    posEl.textContent = `Pos: (${col.col}, ${col.row})`;
    panel.appendChild(posEl);

    panel.appendChild(createHR());
    const questTitleEl = document.createElement('div');
    questTitleEl.style.cssText = 'font-size:10px;color:var(--text-2);font-weight:bold';
    const cls = colonistClass(col);
    questTitleEl.textContent = cls ? `${cls.toUpperCase()} | ${col.questsCompleted || 0} QUESTS` : `${col.questsCompleted || 0} QUESTS DONE`;
    panel.appendChild(questTitleEl);

    if (col.activeQuest) {
        const aq = document.createElement('div');
        aq.style.cssText = 'font-size:11px;color:#ffd60a;margin-top:4px';
        aq.textContent = `Active: ${col.activeQuest.title}`;
        panel.appendChild(aq);
        const prog = document.createElement('div');
        prog.style.cssText = 'font-size:9px;color:var(--text-3)';
        const pct = Math.max(0, Math.floor((1 - col.activeQuest.ticksRemaining / QUEST_WORK_TICKS) * 100));
        prog.textContent = `Progress: ${pct}% | ${col.activeQuest.difficulty}-rank | ${col.activeQuest.category}`;
        panel.appendChild(prog);
    } else {
        const idle = document.createElement('div');
        idle.style.cssText = 'font-size:10px;color:var(--text-3);margin-top:2px';
        idle.textContent = 'No active quest';
        panel.appendChild(idle);
    }

    const recentQuests = (state.questLog || []).filter(l => l.colonist === col.name).slice(-3);
    if (recentQuests.length) {
        const logTitle = document.createElement('div');
        logTitle.style.cssText = 'font-size:9px;color:var(--text-3);margin-top:6px';
        logTitle.textContent = 'RECENT:';
        panel.appendChild(logTitle);
        for (const l of recentQuests) {
            const entry = document.createElement('div');
            entry.style.cssText = 'font-size:9px;color:var(--text-3);padding-left:4px';
            entry.textContent = `- ${l.quest}`;
            panel.appendChild(entry);
        }
    }
}

function createHR() { return document.createElement('hr'); }

function vitalColor(v) {
    return v > 60 ? '#30d158' : v > 30 ? '#ffd60a' : '#ff453a';
}

function createNeedBar(label, value, color) {
    const v = Math.max(0, Math.min(100, value));
    const c = color || vitalColor(v);
    const row = document.createElement('div');
    row.className = 'need-row';
    const lbl = document.createElement('span');
    lbl.className = 'need-label';
    lbl.textContent = label;
    const bg = document.createElement('div');
    bg.className = 'bar-bg';
    const fill = document.createElement('div');
    fill.className = 'bar-fill';
    fill.style.transform = `scaleX(${v / 100})`;
    fill.style.background = c;
    bg.appendChild(fill);
    const val = document.createElement('span');
    val.className = 'need-val';
    val.textContent = Math.floor(value);
    row.appendChild(lbl);
    row.appendChild(bg);
    row.appendChild(val);
    return row;
}

function createStatBar(label, value) {
    const row = document.createElement('div');
    row.className = 'need-row';
    const lbl = document.createElement('span');
    lbl.className = 'need-label';
    lbl.textContent = label;
    const dots = document.createElement('div');
    dots.className = 'stat-dots';
    for (let i = 0; i < 10; i++) {
        const dot = document.createElement('span');
        dot.className = 'stat-dot' + (i < value ? ' filled' : '');
        dots.appendChild(dot);
    }
    const val = document.createElement('span');
    val.className = 'need-val';
    val.textContent = value;
    row.appendChild(lbl);
    row.appendChild(dots);
    row.appendChild(val);
    return row;
}

function createXPBar(c) {
    const pct = colonistXpProgress(c) * 100;
    const row = document.createElement('div');
    row.className = 'need-row';
    const lbl = document.createElement('span');
    lbl.className = 'need-label';
    lbl.textContent = 'XP';
    const bg = document.createElement('div');
    bg.className = 'bar-bg';
    const fill = document.createElement('div');
    fill.className = 'bar-fill';
    fill.style.transform = `scaleX(${pct / 100})`;
    fill.style.background = '#ffd60a';
    bg.appendChild(fill);
    const val = document.createElement('span');
    val.className = 'need-val';
    val.style.width = '50px';
    val.textContent = `${c.xp}/${colonistXpForNext(c)}`;
    row.appendChild(lbl);
    row.appendChild(bg);
    row.appendChild(val);
    return row;
}

function updateGameLog(state) {
    const logEl = document.getElementById('game-log');
    logEl.textContent = '';
    state.gameLog.slice(-3).forEach(m => {
        const div = document.createElement('div');
        div.textContent = m;
        logEl.appendChild(div);
    });
}

const PHASE_COLORS = {
    [GamePhase.SURVIVAL]: 'var(--pink)',
    [GamePhase.GROWTH]:   'var(--yellow)',
    [GamePhase.MASTERY]:  'var(--accent)',
    [GamePhase.VICTORY]:  'var(--green)',
};

function updateTimeDisplay(state) {
    const phase = currentPhase(state);
    const el = document.getElementById('time-display');
    el.textContent = '';
    el.appendChild(document.createTextNode(`Day ${Math.floor(state.currentTick / 240) + 1} | ${state.currentHour}:00 | ${state.isNight ? 'NIGHT' : 'DAY'} | `));
    const phaseSpan = document.createElement('span');
    phaseSpan.style.cssText = `color:${PHASE_COLORS[phase] || 'var(--text-1)'};font-weight:bold`;
    phaseSpan.textContent = phase;
    el.appendChild(phaseSpan);
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
        ['B','Toggle build menu'], ['1-6','Select building'], ['X','Toggle demolish'],
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
        { title:'WELCOME',   body:'Welcome to Times Square. You control a group of survivors.',                          hint:'Click to continue' },
        { title:'NEEDS',     body:'Your colonists have NEEDS — hunger, oxygen, stress, sleep, health. Keep them alive.', hint:'Click to continue' },
        { title:'STATS',     body:'Each colonist has RPG STATS — STR, INT, AGI, END, CHA. Click a figure.',             hint:'Click a colonist' },
        { title:'CAMERA',    body:'WASD to pan the camera. Scroll to zoom.',                                            hint:'Click to continue' },
        { title:'BUILD',     body:'Press B to open the BUILD menu. Buildings keep your colony running.',                hint:'Press B' },
        { title:'SHELTER',   body:'Place a SHELTER to reduce stress and let colonists sleep.',                          hint:'Place a shelter' },
        { title:'COMMAND',   body:'Click a survivor, or drag a box around several. Click the ground to move them. Click a resource to gather it.', hint:'Click to continue' },
        { title:'UPKEEP',    body:'Every building burns materials. Let the pile hit zero and they break until you gather more.', hint:'Click to continue' },
        { title:'RAIDS',     body:'Every third night scavengers rob the stockpile. Put a survivor on PATROL near your buildings and they turn back.', hint:'Click to continue' },
        { title:'GOOD LUCK', body:'Press SPACE to pause. Ctrl+S to save. Esc deselects. Good luck.',   hint:'Click to dismiss' },
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
    if (step === 2 && event === 'colonistSelected') state.tutorialStep = 3;
    else if (step === 3 && event === 'wasdPressed') state.tutorialStep = 4;
    else if (step === 4 && event === 'buildMenuOpened') state.tutorialStep = 5;
    else if (step === 5 && event === 'shelterPlaced') state.tutorialStep = 6;
}
