// Headless bot: plays the web game start to finish and reports pace. node web/sim.mjs
import { createGameState, createColonist, checkVictory, randomColonistName } from './js/state.js';
import { generateWorld, GRID_SIZE } from './js/world.js';
import { Pathfinder } from './js/pathfinder.js';
import { machineTick, jobTick, resourceTick, recruitTick, placeBuilding, canPlace, nodeNear } from './js/systems.js';

const TPD = 240, TICK_S = 0.25;
const w = generateWorld(); const grid = w.grid;
const state = createGameState(); state.resourceNodes = w.resources;
const pf = new Pathfinder(); pf.buildGraph(grid);
const c0 = GRID_SIZE / 2;
for (let i = 0; i < 4; i++) {
    let col = c0, row = c0;
    outer: for (let dc = 0; dc < 10; dc++) for (let dr = 0; dr < 10; dr++) {
        const t = grid[c0 + dr]?.[c0 + dc + i]; if (t === 0 || t === 1 || t === 4) { col = c0 + dc + i; row = c0 + dr; break outer; }
    }
    state.colonists.push(createColonist(randomColonistName(state.colonists), col, row));
}
const R = state.resources, count = t => state.buildings.filter(b => b.type === t).length;
const dist = (a, b) => Math.abs(a.col - b.col) + Math.abs(a.row - b.row);
const hq = () => state.colonists[0];

function order(c, rn) { // what a human does: select, click the resource
    const path = pf.findPathNear(c.col, c.row, rn.col, rn.row);
    if (!path.length) return false;
    c.job = 'gather'; c.pathCols = path.map(p => p.col); c.pathRows = path.map(p => p.row); c.pathIndex = 0;
    return true;
}
function tryBuild(type) {
    const a = hq();
    if (type === 'drill') {
        for (const rn of [...state.resourceNodes].filter(n => n.type === 'materials').sort((x, y) => dist(x, a) - dist(y, a)))
            for (const [dc, dr] of [[1,0],[-1,0],[0,1],[0,-1]]) {
                const col = rn.col + dc, row = rn.row + dr;
                if (canPlace('drill', col, row, grid, state)) return !!placeBuilding('drill', col, row, grid, state, pf);
            }
        return false;
    }
    for (let d = 2; d < 40; d++) for (const [dc, dr] of [[d,0],[-d,0],[0,d],[0,-d],[d,d],[-d,-d],[d,-d],[-d,d]]) {
        const col = a.col + dc, row = a.row + dr;
        if (canPlace(type, col, row, grid, state)) return !!placeBuilding(type, col, row, grid, state, pf);
    }
    return false;
}
let won = null;
const note = {};
for (let t = 1; t <= TPD * 400; t++) {
    state.currentTick = t; state.currentHour = Math.floor((t % TPD) / 10);
    if (t % 60 === 0) {
        const n = state.colonists.length;
        // build order: beacon when rich, else power, drills, beds
        if (R.materials >= 8000 && R.power >= 1000) tryBuild('beacon');
        else {
            if (n >= 4 + 4 * count('shelter') && R.materials >= 10) tryBuild('shelter');
            else if (count('generator') <= count('drill') && R.materials >= 15) tryBuild('generator');
            else if (R.materials >= 12 && R.power >= 2) tryBuild('drill');
        }
        // idle hands go to the resource we are short of
        const want = R.food < 20 ? 'food' : (R.power < 100 && count('generator') === 0 ? 'power' : 'materials');
        for (const c of state.colonists) if (c.job === 'idle' && c.pathIndex >= c.pathCols.length) {
            const rn = state.resourceNodes.filter(x => x.type === want).sort((x, y) => dist(x, c) - dist(y, c))[0];
            if (rn) order(c, rn);
        }
    }
    machineTick(state); jobTick(state); resourceTick(state); recruitTick(state);
    for (const [k, v] of Object.entries(R)) { if (!Number.isFinite(v) || v < 0) note[k + '-bad'] = 1; }
    if (t % (TPD * 5) === 0) console.log(`day ${t / TPD} | ${(t * TICK_S / 60).toFixed(0)} min | crew ${state.colonists.length} | drills ${count('drill')} gens ${count('generator')} shelters ${count('shelter')} | F${R.food} M${R.materials} P${R.power}`);
    if (checkVictory(state)) { won = t; break; }
}
console.log('anomalies', JSON.stringify(note));
console.log(won ? `VICTORY at day ${(won / TPD).toFixed(0)} = ${(won * TICK_S / 3600).toFixed(2)} hours of play` : 'NO VICTORY in 400 days');
