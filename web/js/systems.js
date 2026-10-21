// Game systems: time, machines, gathering, building, orders, recruits

import { gameLog, createBuilding, createColonist, BuildingType, randomColonistName } from './state.js';
import { TileType, tileAt, setTile } from './world.js';

// TimeSystem -- uses real clock for day/night in wallpaper mode
export const TICKS_PER_DAY = 240;
let accumulated = 0;
let TICK_INTERVAL = 0.25;
export function setDifficulty(level) {
    if (level === 'easy')   { TICK_INTERVAL = 0.35; }
    if (level === 'medium') { TICK_INTERVAL = 0.25; }
    if (level === 'hard')   { TICK_INTERVAL = 0.15; }
}

export function timeTick(dt, state) {
    if (state.isPaused) return false;
    accumulated += dt;
    if (accumulated >= TICK_INTERVAL) {
        accumulated -= TICK_INTERVAL;
        state.currentTick++;
        if (state.wallpaperMode) {
            state.currentHour = new Date().getHours();
        } else {
            state.currentHour = Math.floor((state.currentTick % TICKS_PER_DAY) / 10);
        }
        state.isNight = state.currentHour >= 20 || state.currentHour < 6;
        return true;
    }
    return false;
}

// Machines run on their own, once per building per tick, whether or not anyone is nearby.
export const GATHER_EVERY = 4, DRILL_EVERY = 4, GEN_EVERY = 2, DRILL_REACH = 1, DRILL_YIELD = 1;
export function machineTick(state) {
    const t = state.currentTick;
    for (const b of state.buildings) {
        if (b.type === 'generator' && t % GEN_EVERY === 0) state.resources.power++;
        else if (b.type === 'drill' && t % DRILL_EVERY === 0 && state.resources.power >= 1) {
            const rn = nodeNear(state, b.col, b.row, DRILL_REACH);
            if (!rn) continue;
            state.resources.power--;
            state.resources[rn.type] += DRILL_YIELD; // ponytail: ore patches never run dry under a drill
        }
    }
}

export function nodeNear(state, col, row, reach) {
    return state.resourceNodes.find(rn => Math.abs(rn.col - col) + Math.abs(rn.row - row) <= reach) || null;
}

// ResourceSystem: nodes respawn; a colonist standing at a node harvests it.
export function resourceTick(state) {
    for (const rn of state.resourceNodes) {
        if (rn.remaining <= 0 && ++rn.ticksSinceDepleted >= rn.respawnTicks) {
            rn.remaining = rn.maxAmount;
            rn.ticksSinceDepleted = 0;
        }
    }
    if (state.currentTick % GATHER_EVERY !== 0) return;
    for (const c of state.colonists) {
        if (c.job !== 'gather') continue;
        const rn = state.resourceNodes.find(n => n.remaining > 0 && Math.abs(n.col - c.col) + Math.abs(n.row - c.row) <= 1);
        if (rn) { rn.remaining--; state.resources[rn.type]++; }
    }
}

// BuildSystem
export function canPlace(type, col, row, grid, state) {
    const bt = BuildingType[type];
    const [w, h] = bt.size;
    if (type === 'drill') { // one drill per ore patch
        const rn = nodeNear(state, col, row, DRILL_REACH);
        if (!rn || state.buildings.some(b => b.type === 'drill' && nodeNear(state, b.col, b.row, DRILL_REACH) === rn)) return false;
    }
    for (let r = row; r < row + h; r++) {
        for (let c = col; c < col + w; c++) {
            const t = tileAt(grid, c, r);
            if (t === null || !isWalkable(t)) return false;
            // never wall a survivor in
            if (state.colonists.some(k => k.col === c && k.row === r)) return false;
        }
    }
    for (const [res, amt] of Object.entries(bt.cost)) {
        if ((state.resources[res] || 0) < amt) return false;
    }
    return true;
}

function isWalkable(t) { return t === TileType.road || t === TileType.sidewalk || t === TileType.subway; }

export function placeBuilding(type, col, row, grid, state, pathfinder) {
    if (!canPlace(type, col, row, grid, state)) return null;
    const bt = BuildingType[type];
    for (const [res, amt] of Object.entries(bt.cost)) {
        state.resources[res] -= amt;
    }
    const [w, h] = bt.size;
    for (let r = row; r < row + h; r++) {
        for (let c = col; c < col + w; c++) {
            setTile(grid, c, r, TileType.building);
            pathfinder.removeNode(c, r);
        }
    }
    // Anyone routed through the new footprint re-plans; a stale path would walk them into the wall.
    for (const c of state.colonists) {
        for (let i = c.pathIndex; i < c.pathCols.length; i++) {
            const pc = c.pathCols[i], pr = c.pathRows[i];
            if (pc >= col && pc < col + w && pr >= row && pr < row + h) { c.pathCols = []; c.pathRows = []; c.pathIndex = 0; break; }
        }
    }
    const model = createBuilding(type, col, row);
    state.buildings.push(model);
    gameLog(state, `Built ${bt.name}`);
    return model;
}

export function demolishBuilding(id, grid, state, pathfinder) {
    const idx = state.buildings.findIndex(b => b.id === id);
    if (idx === -1) return;
    const b = state.buildings[idx];
    const bt = BuildingType[b.type];
    const [w, h] = bt.size;
    for (let r = b.row; r < b.row + h; r++) {
        for (let c = b.col; c < b.col + w; c++) {
            setTile(grid, c, r, TileType.sidewalk);
            pathfinder.addNode(c, r);
        }
    }
    state.buildings.splice(idx, 1);
    gameLog(state, `Demolished ${bt.name}`);
}

// JobSystem: colonists only walk. Orders (input) set the path and job; resourceTick does the work.
export function jobTick(state) {
    for (const c of state.colonists) {
        if (c.pathIndex >= c.pathCols.length) continue;
        c.col = c.pathCols[c.pathIndex];
        c.row = c.pathRows[c.pathIndex];
        c.pathIndex++;
    }
}

// Recruits: once a day, a survivor walks in if there is a free bed and 10 food. They arrive idle.
export const BASE_BEDS = 4, BEDS_PER_SHELTER = 4, MAX_COLONISTS = 20;
export function recruitTick(state) {
    if (state.demoMode || state.currentTick === 0 || state.currentTick % TICKS_PER_DAY !== 0) return null;
    if (!state.colonists.length) return null;
    const beds = BASE_BEDS + BEDS_PER_SHELTER * state.buildings.filter(b => b.type === 'shelter').length;
    if (state.colonists.length >= Math.min(beds, MAX_COLONISTS) || state.resources.food < 10) return null;
    state.resources.food -= 10;
    const host = state.colonists[0];
    const c = createColonist(randomColonistName(state.colonists), host.col, host.row);
    state.colonists.push(c);
    gameLog(state, `${c.name} arrives, looking for work`);
    return c;
}

// Wallpaper auto-camera: slow drift
export function wallpaperCameraTick(camera, state) {
    if (!state.wallpaperMode && !state.demoMode) return;
    if (!state.colonists.length) return;
    const target = state.colonists[Math.floor(state.currentTick / 120) % state.colonists.length];
    camera.x += (target.col * 32 + 16 - camera.x) * 0.02;
    camera.y += (target.row * 32 + 16 - camera.y) * 0.02;
}

// DemoSystem: menu attract mode ONLY. Never runs in a real game: every call site
// and this guard require state.demoMode, set only for the throwaway menu background.
export function demoTick(state, grid, pathfinder) {
    if (!state.demoMode) return;
    for (const c of state.colonists) {
        if (c.job !== 'idle' || Math.random() > 0.05) continue;
        const nodes = state.resourceNodes.filter(n => n.remaining > 0);
        if (!nodes.length) continue;
        const n = nodes[Math.floor(Math.random() * nodes.length)];
        const path = pathfinder.findPath(c.col, c.row, n.col, n.row);
        if (!path.length) continue;
        c.job = 'gather';
        c.pathCols = path.map(p => p.col);
        c.pathRows = path.map(p => p.row);
        c.pathIndex = 0;
    }
    if (state.currentTick % 16 !== 0 || !state.colonists.length) return;
    const types = Object.keys(BuildingType).filter(t => t !== 'beacon');
    const type = types[Math.floor(Math.random() * types.length)];
    const near = state.colonists[Math.floor(Math.random() * state.colonists.length)];
    for (let i = 0; i < 12; i++) {
        let col = near.col + Math.floor(Math.random() * 11) - 5, row = near.row + Math.floor(Math.random() * 11) - 5;
        if (type === 'drill') { // a drill only works beside a resource
            const rn = state.resourceNodes[Math.floor(Math.random() * state.resourceNodes.length)];
            col = rn.col + Math.floor(Math.random() * 3) - 1; row = rn.row + Math.floor(Math.random() * 3) - 1;
        }
        if (placeBuilding(type, col, row, grid, state, pathfinder)) return;
    }
}
