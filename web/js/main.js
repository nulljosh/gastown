// Main entry -- game loop, init, auto-start

import { createGameState, createColonist, gameLog, grantXP, BuildingType, migrateQuestData,
    randomColonistName, activeQuests, addQuest, completeQuestInList, syncQuestsToLocalStorage,
    checkVictory, currentPhase } from './state.js';
import { initClaudeBridge } from './claude.js';
import { generateWorld, GRID_SIZE, TILE_SIZE, tileAt, worldToTile } from './world.js';
import { Pathfinder } from './pathfinder.js';
import { raidTick, recruitTick, timeTick, needsTick, resourceTick, jobTick, placeBuilding, demolishBuilding,
    questTick, wallpaperCameraTick, setDifficulty, demoTick } from './systems.js';
import { Camera } from './camera.js';
import { renderWorld, renderMinimap } from './renderer.js';
import { setupInput } from './input.js';
import { updateHUD, checkTutorialAdvance } from './hud.js';
import { saveGame, loadGame, listSlots, rebuildGrid } from './save.js';
import { tickParticles, spawnBuildDust } from './particles.js';
import { initTheme, toggleTheme, resolvedTheme } from './theme.js';

let selectedDifficulty = 'medium';
let state = null;
let grid = null;
let pathfinder = null;
let camera = null;
let canvas = null;
let ctx = null;
let minimapCanvas = null;
let minimapCtx = null;
let lastTime = 0;
let running = false;
let loopId = 0;

function init() {
    initTheme();
    canvas = document.getElementById('game');
    ctx = canvas.getContext('2d');
    minimapCanvas = document.getElementById('minimap');
    minimapCtx = minimapCanvas.getContext('2d');
    if (!ctx || !minimapCtx) return;

    resizeCanvas();
    window.addEventListener('resize', resizeCanvas);

    showMenu();
}

function resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
}

function showMenu() {
    const menu = document.getElementById('menu');
    const hud = document.getElementById('hud');
    menu.style.display = 'flex';
    menu.style.opacity = '1';
    hud.style.display = 'none';
    canvas.style.cursor = 'default';

    startGame(null, true); // live demo game as the menu background

    // ponytail: /app/?bg embeds just the attract-mode game (landing page hero)
    if (new URLSearchParams(location.search).has('bg')) {
        menu.style.visibility = 'hidden';
        return;
    }

    const slots = listSlots();
    const slotsContainer = document.getElementById('menu-slots');
    slotsContainer.textContent = '';

    for (let i = 0; i < 3; i++) {
        const s = slots[i];
        const btn = document.createElement('button');
        btn.className = 'menu-slot-btn' + (s ? '' : ' empty');
        if (s) {
            btn.textContent = `SLOT ${i + 1} -- Day ${s.dayCount} | ${s.colonistCount} alive`;
            const slot = i + 1;
            btn.onclick = () => zoomIntoGame(slot);
        } else {
            btn.textContent = `SLOT ${i + 1} -- EMPTY --`;
            btn.disabled = true;
        }
        slotsContainer.appendChild(btn);
    }

    const panels = { load: document.getElementById('menu-panel-load'), settings: document.getElementById('menu-panel-settings') };
    const toggle = which => { for (const k in panels) panels[k].hidden = k !== which || !panels[k].hidden; };
    document.getElementById('menu-load').onclick = () => toggle('load');
    document.getElementById('menu-settings').onclick = () => toggle('settings');
    document.getElementById('menu-new').onclick = () => {
        setDifficulty(selectedDifficulty);
        zoomIntoGame(null);
    };

    const themeBtn = document.getElementById('menu-theme');
    const labelTheme = () => { themeBtn.textContent = resolvedTheme() === 'dark' ? 'Dark' : 'Light'; };
    labelTheme();
    themeBtn.onclick = () => { toggleTheme(); labelTheme(); };
}

// Zoom the demo camera in, fade the menu out, then hand over a real game.
function zoomIntoGame(loadSlot) {
    const menu = document.getElementById('menu');
    const startZoom = camera ? camera.zoom : 1;
    const t0 = performance.now();
    const DURATION = 700;
    (function step(now) {
        const t = Math.min(1, (now - t0) / DURATION);
        const e = t * t * (3 - 2 * t);
        if (camera) camera.zoom = startZoom + (0.7 - startZoom) * e;
        menu.style.opacity = String(1 - e);
        if (t < 1) return requestAnimationFrame(step);
        startGame(loadSlot);
    })(t0);
}

function startGame(loadSlot, demo = false) {
    document.getElementById('menu').style.display = demo ? 'flex' : 'none';
    document.getElementById('hud').style.display = demo ? 'none' : 'block';

    state = createGameState();
    state.demoMode = demo;
    pathfinder = new Pathfinder();
    camera = new Camera();

    if (loadSlot) {
        const save = loadGame(loadSlot);
        if (save) {
            grid = rebuildGrid(save);
            state.colonists = save.colonists;
            state.selectedColonistIds = new Set();
            state.buildings = save.buildings;
            state.resourceNodes = save.resourceNodes;
            state.resources = save.resources;
            state.currentTick = save.currentTick;
            state.currentHour = Math.floor((save.currentTick % 240) / 10);
            state.lastSaveSlot = loadSlot;
            state.tutorialStep = null;
            // Restore quest data from save
            if (save.questList) state.questList = save.questList;
            if (save.rewardList) state.rewardList = save.rewardList;
            if (save.playerXP) state.playerXP = save.playerXP;
            if (save.playerStreak) state.playerStreak = save.playerStreak;
            if (save.playerLastActive) state.playerLastActive = save.playerLastActive;
            gameLog(state, 'Game loaded');
        } else {
            freshWorld();
        }
    } else {
        freshWorld();
        const mult = selectedDifficulty === 'easy' ? 1.5 : selectedDifficulty === 'hard' ? 0.6 : 1;
        Object.keys(state.resources).forEach(k => { state.resources[k] = Math.round((state.resources[k] || 0) * mult); });
    }

    // Migrate quest data from standalone Quest app
    migrateQuestData(state);

    pathfinder.buildGraph(grid);

    const center = GRID_SIZE / 2;
    camera.x = center * TILE_SIZE;
    camera.y = center * TILE_SIZE;
    if (demo) {
        camera.zoom = 1.9;
        Object.keys(state.resources).forEach(k => { state.resources[k] = (state.resources[k] || 0) + 400; });
    }

    // Expose state for quest board HUD
    window._gameState = state;
    window._camera = camera;
    window._gameCallbacks = {
        addQuest: (data) => { addQuest(state, data); updateHUD(state, hudCallbacks); },
        completeQuest: (id) => { completeQuestInList(state, id); updateHUD(state, hudCallbacks); },
        toggleWallpaper: () => {
            state.wallpaperMode = !state.wallpaperMode;
            updateHUD(state, hudCallbacks);
        },
    };

    initClaudeBridge(state);

    if (!demo) setupInput(canvas, camera, state, {
        onSelectEntity: (wx, wy) => selectEntity(wx, wy),
        onPlaceBuilding: (col, row) => handlePlace(col, row),
        onDemolish: (wx, wy) => handleDemolish(wx, wy),
        onBoxSelect: (start, end) => boxSelect(start, end),
        onSave: () => performSave(),
        onHudUpdate: () => updateHUD(state, hudCallbacks),
        onTutorial: (event) => { checkTutorialAdvance(state, event); updateHUD(state, hudCallbacks); },
    });

    if (!demo) updateHUD(state, hudCallbacks);

    running = true;
    loopId++;
    lastTime = 0;
    const myLoop = loopId;
    requestAnimationFrame(ts => gameLoop(ts, myLoop));
}

function freshWorld() {
    const result = generateWorld();
    grid = result.grid;
    state.resourceNodes = result.resources;

    const center = GRID_SIZE / 2;
    for (let i = 0; i < 8; i++) {
        const name = randomColonistName(state.colonists);
        let col = center, row = center;
        for (let dc = 0; dc < 10; dc++) {
            for (let dr = 0; dr < 10; dr++) {
                const c = center + dc + i;
                const r = center + dr;
                const t = tileAt(grid, c, r);
                if (t !== null && (t === 0 || t === 1 || t === 4)) { col = c; row = r; dc = 99; break; }
            }
        }
        state.colonists.push(createColonist(name, col, row));
    }

    state.colonists[0].job = 'gather';
    state.colonists[1].job = 'gather';
    state.lastSaveSlot = 1;

    gameLog(state, 'Welcome to Times Square');
}

const hudCallbacks = {
    onHudUpdate: () => updateHUD(state, hudCallbacks),
    onSaveSlot: (slot) => performSave(slot),
};

function gameLoop(timestamp, id) {
    if (!running || id !== loopId) return; // ponytail: one loop wins; demo loop dies on handoff

    try {
        const dt = lastTime === 0 ? 0 : (timestamp - lastTime) / 1000;
        lastTime = timestamp;

        camera.update(dt);
        wallpaperCameraTick(camera, state);

        if (timeTick(dt, state)) {
            needsTick(state);
            jobTick(state, pathfinder);
            resourceTick(state);
            questTick(state, grid, pathfinder);
            recruitTick(state);
            raidTick(state);
            demoTick(state, grid, pathfinder);
            tickParticles();

            // Victory check
            if (!state.demoMode && checkVictory(state) && !state.victoryShown) {
                state.victoryShown = true;
                state.isPaused = true;
                gameLog(state, 'TIMES SQUARE RECLAIMED');
                const elapsed = Math.floor(state.currentTick / 60);
                state.toastMessage = { text: `Victory in ${elapsed} minutes`, ticks: 300 };
            }

            if (!state.demoMode && state.autoSaveEnabled && state.currentTick > 0 && state.currentTick % 60 === 0 && state.lastSaveSlot) {
                performSave(state.lastSaveSlot);
            }

            // Sync quests to localStorage periodically
            if (!state.demoMode && state.currentTick % 120 === 0) syncQuestsToLocalStorage(state);

            if (!state.demoMode) updateHUD(state, hudCallbacks);
        }

        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = resolvedTheme() === 'light' ? '#ececee' : '#0a0a0c';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        renderWorld(ctx, canvas, camera, grid, state);

        if (Math.floor(timestamp / 16) % 10 === 0) {
            renderMinimap(minimapCtx, minimapCanvas, grid, state, camera);
        }
    } catch (e) {
        console.error('Game loop error:', e);
    }

    requestAnimationFrame(ts => gameLoop(ts, id));
}

// One rule: click a colonist to pick them, click a resource to send the picked ones to gather,
// click the ground to send them there. Selection stays until Esc.
function pickedIds() {
    const ids = new Set(state.selectedColonistIds || []);
    if (state.selectedColonistId) ids.add(state.selectedColonistId);
    return [...ids];
}

function selectEntity(wx, wy) {
    for (const c of state.colonists) {
        const cx = c.col * TILE_SIZE + TILE_SIZE / 2;
        const cy = c.row * TILE_SIZE + TILE_SIZE / 2;
        if (Math.abs(wx - cx) < 20 && Math.abs(wy - cy) < 20) {
            state.selectedColonistId = c.id;
            state.selectedColonistIds = new Set([c.id]);
            gameLog(state, `Selected ${c.name}`);
            updateHUD(state, hudCallbacks);
            return;
        }
    }
    const tile = worldToTile(wx, wy);
    const node = state.resourceNodes.find(rn => rn.remaining > 0 &&
        Math.abs(rn.col - tile.col) <= 1 && Math.abs(rn.row - tile.row) <= 1);
    for (const id of pickedIds()) {
        const c = state.colonists.find(k => k.id === id);
        if (!c || c.state === 'dead') continue;
        const path = node ? pathfinder.findPathNear(c.col, c.row, node.col, node.row) : pathfinder.findPath(c.col, c.row, tile.col, tile.row);
        if (!path.length) continue;
        c.job = node ? 'gather' : 'idle';
        c.pathCols = path.map(p => p.col);
        c.pathRows = path.map(p => p.row);
        c.pathIndex = 0;
    }
    updateHUD(state, hudCallbacks);
}

function boxSelect(start, end) {
    const minX = Math.min(start.x, end.x);
    const maxX = Math.max(start.x, end.x);
    const minY = Math.min(start.y, end.y);
    const maxY = Math.max(start.y, end.y);

    state.selectedColonistIds = new Set();
    state.selectedColonistId = null;

    for (const c of state.colonists) {
        const cx = c.col * TILE_SIZE + TILE_SIZE / 2;
        const cy = c.row * TILE_SIZE + TILE_SIZE / 2;
        if (cx >= minX && cx <= maxX && cy >= minY && cy <= maxY) {
            state.selectedColonistIds.add(c.id);
        }
    }

    if (state.selectedColonistIds.size === 1) {
        state.selectedColonistId = state.selectedColonistIds.values().next().value;
    }
    if (state.selectedColonistIds.size > 0) {
        gameLog(state, `Selected ${state.selectedColonistIds.size} colonists`);
    }
    updateHUD(state, hudCallbacks);
}

function handlePlace(col, row) {
    if (!state.selectedBuildingType) return;
    const model = placeBuilding(state.selectedBuildingType, col, row, grid, state, pathfinder);
    if (model) {
        const bt = BuildingType[state.selectedBuildingType];
        spawnBuildDust(col, row, bt.size[0], bt.size[1]);
        for (const c of state.colonists) {
            if (c.job === 'build' && c.state !== 'dead') {
                const dist = Math.abs(c.col - col) + Math.abs(c.row - row);
                if (dist <= 5) grantXP(c, 10);
            }
        }
        updateHUD(state, hudCallbacks);
    }
}

function handleDemolish(wx, wy) {
    const tile = worldToTile(wx, wy);
    for (const b of state.buildings) {
        const bt = BuildingType[b.type];
        const [w, h] = bt.size;
        if (tile.col >= b.col && tile.col < b.col + w && tile.row >= b.row && tile.row < b.row + h) {
            demolishBuilding(b.id, grid, state, pathfinder);
            updateHUD(state, hudCallbacks);
            return;
        }
    }
}

function performSave(slot) {
    const targetSlot = slot || state.lastSaveSlot || 1;
    saveGame(targetSlot, state, grid);
    state.lastSaveSlot = targetSlot;
    state.showSaveIndicator = true;
    gameLog(state, `Saved to slot ${targetSlot}`);
    updateHUD(state, hudCallbacks);
    setTimeout(() => { state.showSaveIndicator = false; updateHUD(state, hudCallbacks); }, 2000);
}

document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.diff-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.diff-btn').forEach(b => b.classList.remove('selected'));
            btn.classList.add('selected');
            selectedDifficulty = btn.dataset.diff;
        });
    });
    document.querySelector('.diff-btn[data-diff="medium"]').classList.add('selected');

    init();

    const mm = document.getElementById('minimap');
    mm.addEventListener('click', e => {
        if (!camera || !grid) return;
        const rect = mm.getBoundingClientRect();
        const px = (e.clientX - rect.left) / rect.width;
        const py = (e.clientY - rect.top) / rect.height;
        camera.x = px * GRID_SIZE * TILE_SIZE;
        camera.y = py * GRID_SIZE * TILE_SIZE;
    });
});

// Accessors for webmcp.js -- keep module state private, expose only what agents need
export function mcpGetState() {
    if (!state) return null;
    return {
        resources: state.resources,
        currentTick: state.currentTick,
        currentHour: state.currentHour,
        isNight: state.isNight,
        isPaused: state.isPaused,
        phase: currentPhase(state),
        colonistsAlive: state.colonists.filter(c => c.state !== 'dead').length,
        colonistsTotal: state.colonists.length,
        buildingCount: state.buildings.length,
        playerXP: state.playerXP,
        playerStreak: state.playerStreak,
        lastSaveSlot: state.lastSaveSlot,
        difficulty: selectedDifficulty,
    };
}

export function mcpStartGame(difficulty) {
    if (difficulty) {
        selectedDifficulty = difficulty;
        setDifficulty(difficulty);
    }
    startGame(null);
}

export function mcpLoadSave(slot) {
    startGame(slot);
}

export function mcpSaveGame(slot) {
    performSave(slot);
}
