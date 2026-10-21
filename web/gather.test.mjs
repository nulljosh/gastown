// Gather job: the GATH button sets job='gather' with no path assigned. jobTick must path the
// colonist to a resource node itself, not cancel back to idle before resourceTick ever runs.
import { test } from 'node:test';
import assert from 'node:assert';
import { createGameState, createColonist } from './js/state.js';
import { Pathfinder } from './js/pathfinder.js';
import { jobTick, resourceTick } from './js/systems.js';
import { GRID_SIZE, TileType } from './js/world.js';

function grid() {
    return Array.from({ length: GRID_SIZE }, () => Array.from({ length: GRID_SIZE }, () => TileType.sidewalk));
}

test('gather job walks to the nearest node and harvests', () => {
    const state = createGameState();
    state.colonists.push(createColonist('Miner', 5, 5));
    state.colonists[0].job = 'gather';
    state.resourceNodes = [
        { id: 'r1', type: 'materials', col: 5, row: 8, remaining: 5, maxAmount: 5, respawnTicks: 60, ticksSinceDepleted: 0 }
    ];
    state.resources.materials = 0;

    const pf = new Pathfinder();
    pf.buildGraph(grid());

    for (let i = 0; i < 40; i++) {
        jobTick(state, pf);
        resourceTick(state);
    }

    const c = state.colonists[0];
    assert.equal(c.col, 5);
    assert.equal(c.row, 8);
    assert.ok(state.resources.materials > 0, 'gather should have walked to the node and harvested');
    assert.equal(state.resourceNodes[0].remaining, 0, '5 remaining at ~1/tick over 40 ticks should fully deplete');
});

test('gather retargets the next node once the first depletes', () => {
    const state = createGameState();
    state.colonists.push(createColonist('Miner', 0, 0));
    state.colonists[0].job = 'gather';
    state.resourceNodes = [
        { id: 'r1', type: 'materials', col: 0, row: 2, remaining: 1, maxAmount: 1, respawnTicks: 999, ticksSinceDepleted: 0 },
        { id: 'r2', type: 'materials', col: 0, row: 6, remaining: 3, maxAmount: 3, respawnTicks: 999, ticksSinceDepleted: 0 }
    ];
    state.resources.materials = 0;

    const pf = new Pathfinder();
    pf.buildGraph(grid());

    for (let i = 0; i < 60; i++) {
        jobTick(state, pf);
        resourceTick(state);
    }

    assert.equal(state.resourceNodes[0].remaining, 0);
    assert.equal(state.resourceNodes[1].remaining, 0, 'colonist should retarget the second node once the first is empty');
    assert.equal(state.resources.materials, 4);
});
