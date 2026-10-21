// Canvas renderer -- 16-bit style sprites, cached to offscreen canvases

import { TILE_SIZE, TileColors, GRID_SIZE } from './world.js';
import { BuildingType } from './state.js';
import { renderParticles } from './particles.js';

const GAP = 1;
const TILE_R = 4;

// Sprites come from scripts/gen_sprites.py: the same noir pixel art the native app ships, at 2x.
// Nothing draws until its image has loaded.
const TILE_SPRITE = ['tile_road', 'tile_sidewalk', 'tile_building', 'tile_billboard', 'tile_subway', 'tile_sewer', 'tile_empty'];
const sprites = {};
for (const n of [...TILE_SPRITE, 'colonist_idle', 'colonist_walk1', 'colonist_walk2', 'shelter', 'generator', 'drill', 'beacon', 'res_food', 'res_materials', 'res_power']) {
    const im = new Image();
    im.src = `sprites/${n}.png`;
    sprites[n] = im;
}
const sprite = n => (sprites[n]?.complete && sprites[n].naturalWidth > 0 ? sprites[n] : null);

// Canvas can't read CSS custom properties. Neutral "ink" (labels, washes, tile
// detail) has to flip with the theme or it vanishes; saturated status colors don't.
const INK_DARK = {
    label:       'rgba(255,255,255,0.85)',
    labelSoft:   'rgba(255,255,255,0.7)',
    labelStrong: 'rgba(255,255,255,0.9)',
    wash:        'rgba(255,255,255,0.3)',
    washSoft:    'rgba(255,255,255,0.2)',
    track:       'rgba(255,255,255,0.1)',
    detail:      'rgba(255,255,255,0.06)',
    crack:       'rgba(255,255,255,0.05)',
    tile:        '#0a0a0c',
};
const INK_LIGHT = {
    label:       'rgba(0,0,0,0.80)',
    labelSoft:   'rgba(0,0,0,0.62)',
    labelStrong: 'rgba(0,0,0,0.85)',
    wash:        'rgba(0,0,0,0.22)',
    washSoft:    'rgba(0,0,0,0.14)',
    track:       'rgba(0,0,0,0.10)',
    detail:      'rgba(0,0,0,0.07)',
    crack:       'rgba(0,0,0,0.08)',
    tile:        '#ececee',
};
let INK = INK_DARK;

export function setRenderTheme(theme) {
    INK = theme === 'light' ? INK_LIGHT : INK_DARK;
}

const JOB_COLORS = { idle: '#8e8e93', gather: '#30d158' };

const RESOURCE_COLORS = {
    food: '#30d158',
    power: '#ffd60a',
    materials: '#ff9f0a',
};

function roundRect(ctx, x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y);
    ctx.quadraticCurveTo(x + w, y, x + w, y + r);
    ctx.lineTo(x + w, y + h - r);
    ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
    ctx.lineTo(x + r, y + h);
    ctx.quadraticCurveTo(x, y + h, x, y + h - r);
    ctx.lineTo(x, y + r);
    ctx.quadraticCurveTo(x, y, x + r, y);
    ctx.closePath();
}

// Tile sprites with terrain variation (4 brightness variants per type)
// Render tick for walk animation
let renderTick = 0;

export function renderWorld(ctx, canvas, camera, grid, state) {
    renderTick++;
    ctx.save();
    camera.applyTransform(ctx, canvas);

    const bounds = camera.visibleBounds(canvas);

    ctx.imageSmoothingEnabled = false; // pixel art

    // Tiles
    for (let r = bounds.minRow; r <= bounds.maxRow; r++) {
        for (let c = bounds.minCol; c <= bounds.maxCol; c++) {
            const im = sprite(TILE_SPRITE[grid[r][c]]);
            if (im) ctx.drawImage(im, c * TILE_SIZE, r * TILE_SIZE, TILE_SIZE, TILE_SIZE);
        }
    }

    // Time-based colored lighting
    const hour = state.currentHour;
    let lightColor = null;
    if (hour >= 6 && hour < 8) lightColor = 'rgba(255, 180, 80, 0.1)'; // dawn
    else if (hour >= 18 && hour < 20) lightColor = 'rgba(255, 120, 40, 0.15)'; // sunset
    else if (hour >= 20 || hour < 6) lightColor = 'rgba(10, 10, 60, 0.3)'; // night
    if (lightColor) {
        ctx.fillStyle = lightColor;
        ctx.fillRect(bounds.minCol * TILE_SIZE, bounds.minRow * TILE_SIZE,
            (bounds.maxCol - bounds.minCol + 1) * TILE_SIZE,
            (bounds.maxRow - bounds.minRow + 1) * TILE_SIZE);
    }

    // Resource nodes
    for (const rn of state.resourceNodes) {
        if (rn.col < bounds.minCol || rn.col > bounds.maxCol || rn.row < bounds.minRow || rn.row > bounds.maxRow) continue;
        const x = rn.col * TILE_SIZE + TILE_SIZE / 2;
        const y = rn.row * TILE_SIZE + TILE_SIZE / 2;
        const alpha = rn.remaining <= 0 ? 0.12 : Math.max(0.3, rn.maxAmount > 0 ? rn.remaining / rn.maxAmount : 0);

        ctx.globalAlpha = alpha * 0.3;
        ctx.fillStyle = RESOURCE_COLORS[rn.type] || INK.label;
        ctx.beginPath();
        ctx.arc(x, y, 18, 0, Math.PI * 2);
        ctx.fill();

        ctx.globalAlpha = alpha;
        const im = sprite('res_' + rn.type);
        if (im) ctx.drawImage(im, x - 12, y - 12, 24, 24);
        ctx.globalAlpha = 1;
        if (rn.remaining > 0) {
            ctx.fillStyle = INK.labelStrong;
            ctx.font = '600 9px -apple-system, sans-serif';
            ctx.fillText(`${rn.type} ${rn.remaining}`, x, y + 22);
        }
    }

    // Buildings -- glass style with icons
    for (const b of state.buildings) {
        const bt = BuildingType[b.type];
        if (!bt) continue;
        const [w, h] = bt.size;
        const bx = b.col * TILE_SIZE + GAP;
        const by = b.row * TILE_SIZE + GAP;
        const bw = w * TILE_SIZE - GAP * 2;
        const bh = h * TILE_SIZE - GAP * 2;
        if (bx + bw < bounds.minCol * TILE_SIZE || bx > (bounds.maxCol + 1) * TILE_SIZE) continue;
        if (by + bh < bounds.minRow * TILE_SIZE || by > (bounds.maxRow + 1) * TILE_SIZE) continue;

        const bim = sprite(b.type);
        if (bim) ctx.drawImage(bim, b.col * TILE_SIZE, b.row * TILE_SIZE, w * TILE_SIZE, h * TILE_SIZE);

        // Name label
        ctx.fillStyle = INK.labelSoft;
        ctx.font = '600 7px -apple-system, sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'bottom';
        ctx.fillText(bt.name, bx + bw / 2, by + bh - 2);
        ctx.globalAlpha = 1;
    }

    // Colonists -- 16-bit style with smooth interpolation
    for (const c of state.colonists) {
        if (c.col < bounds.minCol - 2 || c.col > bounds.maxCol + 2 || c.row < bounds.minRow - 2 || c.row > bounds.maxRow + 2) continue;
        // Smooth position lerp
        const targetX = c.col * TILE_SIZE + TILE_SIZE / 2;
        const targetY = c.row * TILE_SIZE + TILE_SIZE / 2;
        if (c._renderX === undefined) { c._renderX = targetX; c._renderY = targetY; }
        c._renderX += (targetX - c._renderX) * 0.25;
        c._renderY += (targetY - c._renderY) * 0.25;
        const x = c._renderX;
        const y = c._renderY;

        // Selection ring
        const isSelected = c.id === state.selectedColonistId || (state.selectedColonistIds && state.selectedColonistIds.has(c.id));
        if (isSelected) {
            ctx.strokeStyle = 'rgba(255, 214, 10, 0.7)';
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.arc(x, y, 22, 0, Math.PI * 2);
            ctx.stroke();
        }

        // Job ring under the feet, then the sprite: walk frames while moving
        ctx.fillStyle = JOB_COLORS[c.job] || '#666';
        ctx.globalAlpha = 0.55;
        ctx.beginPath();
        ctx.ellipse(x, y + 12, 11, 4, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalAlpha = 1;
        const moving = c.pathIndex < c.pathCols.length;
        const cim = sprite(moving ? (Math.floor(renderTick / 8) % 2 ? 'colonist_walk1' : 'colonist_walk2') : 'colonist_idle');
        if (cim) ctx.drawImage(cim, x - 18, y - 22, 36, 36);

        // Name
        ctx.fillStyle = INK.label;
        ctx.font = '600 7px -apple-system, sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(c.name, x, y - 26);

    }

    // Particles
    renderParticles(ctx);

    // Build ghost
    if (state.inputMode === 'build' && state.selectedBuildingType && state._ghostCol != null) {
        const bt = BuildingType[state.selectedBuildingType];
        if (bt) {
            const [w, h] = bt.size;
            const gx = state._ghostCol * TILE_SIZE + GAP;
            const gy = state._ghostRow * TILE_SIZE + GAP;
            ctx.fillStyle = 'rgba(41, 151, 255, 0.15)';
            roundRect(ctx, gx, gy, w * TILE_SIZE - GAP * 2, h * TILE_SIZE - GAP * 2, TILE_R + 2);
            ctx.fill();
            ctx.strokeStyle = 'rgba(41, 151, 255, 0.5)';
            ctx.lineWidth = 1;
            roundRect(ctx, gx, gy, w * TILE_SIZE - GAP * 2, h * TILE_SIZE - GAP * 2, TILE_R + 2);
            ctx.stroke();
        }
    }

    // Selection rectangle
    if (state._selRect) {
        const r = state._selRect;
        ctx.strokeStyle = 'rgba(41, 151, 255, 0.6)';
        ctx.fillStyle = 'rgba(41, 151, 255, 0.08)';
        ctx.lineWidth = 2;
        roundRect(ctx, r.x, r.y, r.w, r.h, 4);
        ctx.fill();
        roundRect(ctx, r.x, r.y, r.w, r.h, 4);
        ctx.stroke();
    }

    ctx.restore();

    // Night: a soft blue dusk over the whole view, deepest from 22:00 to 04:00. Pikmin-style day pressure you can see.
    if (state.isNight) {
        const h = state.currentHour, deep = h >= 22 || h < 4;
        ctx.save(); ctx.setTransform(1, 0, 0, 1, 0, 0);
        ctx.fillStyle = deep ? 'rgba(10, 16, 48, 0.42)' : 'rgba(10, 16, 48, 0.24)';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.restore();
    }
}

// Minimap
export function renderMinimap(ctx, canvas, grid, state, camera) {
    const mw = canvas.width;
    const mh = canvas.height;
    const scale = mw / (GRID_SIZE * TILE_SIZE);

    ctx.fillStyle = '#0a0a0c';
    ctx.fillRect(0, 0, mw, mh);

    const step = Math.max(1, Math.floor(GRID_SIZE / mw));
    for (let r = 0; r < GRID_SIZE; r += step) {
        if (!grid[r]) continue;
        for (let c = 0; c < GRID_SIZE; c += step) {
            ctx.fillStyle = TileColors[grid[r][c]] || '#0a0a0c';
            const px = (c * TILE_SIZE) * scale;
            const py = (r * TILE_SIZE) * scale;
            const ps = TILE_SIZE * scale * step;
            ctx.fillRect(px, py, Math.max(1, ps), Math.max(1, ps));
        }
    }

    ctx.fillStyle = '#30d158';
    for (const c of state.colonists) {
        const px = c.col * TILE_SIZE * scale;
        const py = c.row * TILE_SIZE * scale;
        ctx.beginPath();
        ctx.arc(px, py, 1.5, 0, Math.PI * 2);
        ctx.fill();
    }

    const bounds = camera.visibleBounds(document.getElementById('game'));
    ctx.strokeStyle = INK.wash;
    ctx.lineWidth = 1;
    ctx.strokeRect(
        bounds.minCol * TILE_SIZE * scale,
        bounds.minRow * TILE_SIZE * scale,
        (bounds.maxCol - bounds.minCol) * TILE_SIZE * scale,
        (bounds.maxRow - bounds.minRow) * TILE_SIZE * scale
    );
}
