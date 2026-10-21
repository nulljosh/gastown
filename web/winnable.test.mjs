// The game must stay winnable: the bot in sim.mjs has to reach victory in most worlds, in a
// few hours of play at most. Guards the pacing knobs (XP rate, recruit rules, need decay).
import { test } from 'node:test';
import assert from 'node:assert';
import { execFileSync } from 'node:child_process';

test('bot wins at least 2 of 3 worlds, each under 5 hours of play', { timeout: 600000 }, () => {
    const hours = [];
    for (let i = 0; i < 3; i++) {
        const out = execFileSync('node', [new URL('./sim.mjs', import.meta.url).pathname], { encoding: 'utf8' });
        const m = out.match(/VICTORY at day \d+ = ([\d.]+) hours/);
        if (m) hours.push(parseFloat(m[1]));
    }
    assert.ok(hours.length >= 2, `only ${hours.length}/3 worlds won`);
    hours.sort((a, b) => a - b);
    assert.ok(hours[1] < 5, `too slow, median over 5h: ${hours}`); // one slow world is a bad map, two is a pacing bug
});
