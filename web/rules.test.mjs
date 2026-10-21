// The 2.0 rules: orders gather, machines run on their own, beds gate recruits, the Beacon wins.
import { test } from 'node:test';
import assert from 'node:assert';
import { createGameState, createColonist, checkVictory } from './js/state.js';
import { machineTick, resourceTick, recruitTick, canPlace, placeBuilding } from './js/systems.js';
import { Pathfinder } from './js/pathfinder.js';
import { GRID_SIZE, TileType } from './js/world.js';

const grid = () => Array.from({ length: GRID_SIZE }, () => Array.from({ length: GRID_SIZE }, () => TileType.sidewalk));
const node = (col, row, type = 'materials') => ({ id: 'n' + col, type, col, row, remaining: 50, maxAmount: 50, respawnTicks: 60, ticksSinceDepleted: 0 });

test('a gathering colonist at a node harvests; an idle one does not', () => {
    const s = createGameState(); s.resources.materials = 0;
    s.resourceNodes = [node(5, 5)];
    s.colonists.push(createColonist('A', 5, 6), createColonist('B', 5, 4));
    s.colonists[0].job = 'gather';
    for (let t = 1; t <= 40; t++) { s.currentTick = t; resourceTick(s); }
    assert.equal(s.resources.materials, 10);
});

test('drill needs a node and power; generator makes the power', () => {
    const s = createGameState(); const g = grid(); const pf = new Pathfinder(); pf.buildGraph(g);
    s.resources.materials = 100; s.resources.power = 2;
    s.resourceNodes = [node(10, 10)];
    assert.ok(!canPlace('drill', 30, 30, g, s), 'no node nearby');
    assert.ok(placeBuilding('drill', 10, 11, g, s, pf));
    s.resources.materials = 0; s.resources.power = 0;
    for (let t = 1; t <= 40; t++) { s.currentTick = t; machineTick(s); }
    assert.equal(s.resources.materials, 0, 'dry drill stalls');
    s.buildings.push({ id: 'g', type: 'generator', col: 0, row: 0 });
    for (let t = 41; t <= 80; t++) { s.currentTick = t; machineTick(s); }
    assert.ok(s.resources.materials > 0, 'powered drill mines');
});

test('no bed, no recruit; a shelter opens four beds', () => {
    const s = createGameState(); s.resources.food = 100;
    for (let i = 0; i < 4; i++) s.colonists.push(createColonist('C' + i, 5, 5));
    s.currentTick = 240;
    assert.equal(recruitTick(s), null);
    s.buildings.push({ id: 'b', type: 'shelter', col: 1, row: 1 });
    assert.ok(recruitTick(s));
    assert.equal(s.resources.food, 90);
});

test('the Beacon is the win', () => {
    const s = createGameState();
    assert.ok(!checkVictory(s));
    s.buildings.push({ id: 'x', type: 'beacon', col: 0, row: 0 });
    assert.ok(checkVictory(s));
});
