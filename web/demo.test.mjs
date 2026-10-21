// Demo attract-mode: idle colonists act only when state.demoMode is true.
import { test } from 'node:test';
import assert from 'node:assert';
import { createGameState, createColonist } from './js/state.js';
import { generateWorld } from './js/world.js';
import { Pathfinder } from './js/pathfinder.js';
import { demoTick } from './js/systems.js';

function setup(demo) {
    const state = createGameState();
    const { grid, resources } = generateWorld();
    state.resourceNodes = resources;
    state.demoMode = demo;
    const pf = new Pathfinder();
    pf.buildGraph(grid);
    for (let i = 0; i < 8; i++) {
        const n = resources[i % resources.length];
        state.colonists.push(createColonist('C' + i, n.col + 2, n.row + 2));
    }
    return { state, grid, pf };
}

test('demoTick assigns work in demo mode only', () => {
    const d = setup(true);
    for (let i = 0; i < 400; i++) { d.state.currentTick++; demoTick(d.state, d.grid, d.pf); }
    assert.ok(d.state.colonists.some(c => c.job === 'gather'), 'demo colonists should get jobs');

    const p = setup(false);
    for (let i = 0; i < 400; i++) { p.state.currentTick++; demoTick(p.state, p.grid, p.pf); }
    assert.ok(p.state.colonists.every(c => c.job === 'idle'), 'player game must stay hands-off');
    assert.equal(p.state.buildings.length, 0);
});
