// Particle system -- floating text, sparkles, dust

import { TILE_SIZE } from './world.js';

const particles = [];

export function spawnParticle({ x, y, text, color, life = 40, vx = 0, vy = -0.5, size = 7 }) {
    particles.push({ x, y, text, color, life, maxLife: life, vx, vy, size });
}

export function spawnAtTile(col, row, opts) {
    spawnParticle({ x: col * TILE_SIZE + TILE_SIZE / 2, y: row * TILE_SIZE + TILE_SIZE / 2, ...opts });
}

export function spawnDamage(col, row, amount) {
    spawnAtTile(col, row, { text: `-${Math.floor(amount)}`, color: '#ff375f', life: 30, vy: -0.8 });
}

export function spawnXP(col, row, amount) {
    spawnAtTile(col, row, { text: `+${amount} XP`, color: '#ffd60a', life: 35, vy: -0.6 });
}

export function spawnLevelUp(col, row, level) {
    spawnAtTile(col, row, { text: `LVL ${level}`, color: '#ffd60a', life: 50, vy: -0.4, size: 9 });
    // Burst particles
    for (let i = 0; i < 6; i++) {
        const angle = (i / 6) * Math.PI * 2;
        spawnAtTile(col, row, {
            text: '*', color: '#ffd60a', life: 25,
            vx: Math.cos(angle) * 1.2, vy: Math.sin(angle) * 1.2, size: 6,
        });
    }
}

export function spawnBuildDust(col, row, w, h) {
    for (let i = 0; i < 4; i++) {
        spawnParticle({
            x: col * TILE_SIZE + Math.random() * w * TILE_SIZE,
            y: row * TILE_SIZE + h * TILE_SIZE,
            text: '.', color: 'rgba(255,255,255,0.4)', life: 20,
            vx: (Math.random() - 0.5) * 1.5, vy: -Math.random() * 0.8, size: 5,
        });
    }
}

export function spawnQuestComplete(col, row) {
    spawnAtTile(col, row, { text: '\u2713', color: '#30d158', life: 40, vy: -0.5, size: 10 });
}

export function tickParticles() {
    for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.life--;
        if (p.life <= 0) particles.splice(i, 1);
    }
}

export function renderParticles(ctx) {
    for (const p of particles) {
        const alpha = Math.min(1, p.life / (p.maxLife * 0.3));
        ctx.globalAlpha = alpha;
        ctx.fillStyle = p.color;
        ctx.font = `bold ${p.size}px -apple-system, sans-serif`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(p.text, p.x, p.y);
    }
    ctx.globalAlpha = 1;
}
