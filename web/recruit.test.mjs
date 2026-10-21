// Recruits arrive daily when there is a free bed and food; gathering levels colonists up.
import { test } from 'node:test';
import assert from 'node:assert';
import { createGameState, createColonist } from './js/state.js';
import { recruitTick, resourceTick, placeBuilding, canPlace, raidTick } from './js/systems.js';
import { Pathfinder } from './js/pathfinder.js';
import { GRID_SIZE, TileType } from './js/world.js';

function colony(n) {
    const s = createGameState();
    for (let i = 0; i < n; i++) s.colonists.push(createColonist('C' + i, 5, 5));
    s.resources.food = 100;
    return s;
}

test('no bed, no recruit; a shelter opens four beds', () => {
    const s = colony(8);
    s.currentTick = 240;
    assert.equal(recruitTick(s), null);
    s.buildings.push({ id: 'b', type: 'shelter', col: 1, row: 1, isActive: true });
    assert.ok(recruitTick(s));
    assert.equal(s.colonists.length, 9);
    assert.equal(s.resources.food, 90);
});

test('no food, no recruit', () => {
    const s = colony(2);
    s.currentTick = 240;
    s.resources.food = 5;
    assert.equal(recruitTick(s), null);
});

test('gathering earns XP', () => {
    const s = colony(1);
    s.colonists[0].job = 'gather';
    s.resourceNodes = [{ id: 'r', type: 'materials', col: 5, row: 5, remaining: 50, maxAmount: 50, respawnTicks: 60, ticksSinceDepleted: 0 }];
    for (let t = 4; t <= 2000; t += 20) { s.currentTick = t; resourceTick(s); }
    assert.ok(s.colonists[0].level > 0 || s.colonists[0].xp > 0);
});

test('building never traps a colonist: cannot place on them, clears paths through it', () => {
    const grid = Array.from({ length: GRID_SIZE }, () => Array.from({ length: GRID_SIZE }, () => TileType.sidewalk));
    const pf = new Pathfinder(); pf.buildGraph(grid);
    const s = colony(1); s.resources.materials = 100;
    const c = s.colonists[0]; // at 5,5
    assert.equal(canPlace('shelter', 5, 5, grid, s), false);
    c.pathCols = [6, 7, 8]; c.pathRows = [5, 5, 5]; c.pathIndex = 0;
    assert.ok(placeBuilding('shelter', 7, 4, grid, s, pf));
    assert.equal(c.pathCols.length, 0);
});

test('a raid takes 20% unless a patrol stands near the colony', () => {
    const s = colony(4); s.resources = { food: 100, materials: 50, cash: 10, power: 0, oxygen: 0 };
    s.currentTick = 3 * 240 + 220;
    const r = raidTick(s);
    assert.equal(r.guarded, false); assert.equal(s.resources.food, 80); assert.equal(s.resources.materials, 40);
    s.colonists[0].job = 'patrol';
    assert.equal(raidTick(s).guarded, true); assert.equal(s.resources.food, 80);
    s.currentTick = 4 * 240 + 220;
    assert.equal(raidTick(s), null, 'not a raid day');
});
