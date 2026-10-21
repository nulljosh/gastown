// Canvas renderer -- 16-bit style sprites, cached to offscreen canvases

import { TILE_SIZE, TileColors, GRID_SIZE } from './world.js';
import { BuildingType, ResourceSymbol } from './state.js';
import { renderParticles } from './particles.js';

const GAP = 1;
const TILE_R = 4;

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
    clearTileSprites();
}

export function clearTileSprites() {
    for (const k in tileSprites) delete tileSprites[k];
}

const JOB_COLORS = { idle: '#8e8e93', gather: '#30d158' };

const RESOURCE_COLORS = {
    food: '#30d158',
    power: '#ffd60a',
    materials: '#ff9f0a',
};

const BUILDING_COLORS = {
    shelter: 'rgba(41, 151, 255, 0.25)',
    generator: 'rgba(255, 214, 10, 0.25)',
    drill: 'rgba(255, 159, 10, 0.25)',
    beacon: 'rgba(255, 55, 95, 0.3)',
};

const BUILDING_BORDER = {
    shelter: 'rgba(41, 151, 255, 0.5)',
    generator: 'rgba(255, 214, 10, 0.5)',
    drill: 'rgba(255, 159, 10, 0.5)',
    beacon: 'rgba(255, 55, 95, 0.6)',
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
const tileSprites = {};
function getTileSprite(tileType, col, row) {
    const variant = (col * 7 + row * 13) % 4;
    const key = `${tileType}_${variant}`;
    if (tileSprites[key]) return tileSprites[key];
    const size = TILE_SIZE;
    const c = document.createElement('canvas');
    c.width = size;
    c.height = size;
    const cx = c.getContext('2d');
    const baseColor = TileColors[tileType] || INK.tile;

    // Parse and shift brightness
    const shift = [-6, -3, 0, 4][variant];
    cx.fillStyle = shiftColor(baseColor, shift);
    roundRect(cx, GAP, GAP, size - GAP * 2, size - GAP * 2, TILE_R);
    cx.fill();

    // Sidewalk details (deterministic per position)
    if (tileType === 1 && variant === 0) { // sidewalk + variant 0 = manhole
        cx.fillStyle = INK.detail;
        cx.fillRect(10, 10, 12, 12);
    } else if (tileType === 1 && variant === 3) { // cracks
        cx.strokeStyle = INK.crack;
        cx.lineWidth = 1;
        cx.beginPath();
        cx.moveTo(8, 16);
        cx.lineTo(24, 18);
        cx.stroke();
    }

    tileSprites[key] = c;
    return c;
}

function shiftColor(hex, amount) {
    if (hex.startsWith('rgba')) return hex;
    const r = Math.max(0, Math.min(255, parseInt(hex.slice(1, 3), 16) + amount));
    const g = Math.max(0, Math.min(255, parseInt(hex.slice(3, 5), 16) + amount));
    const b = Math.max(0, Math.min(255, parseInt(hex.slice(5, 7), 16) + amount));
    return `rgb(${r},${g},${b})`;
}

// Skin tones from name hash
const SKIN_TONES = ['#f5d0a9', '#e8b88a', '#d4956b', '#c47a50', '#8d5524', '#6b3e1f'];
function skinTone(name) {
    let hash = 0;
    for (let i = 0; i < name.length; i++) hash = ((hash << 5) - hash + name.charCodeAt(i)) | 0;
    return SKIN_TONES[Math.abs(hash) % SKIN_TONES.length];
}

// Render tick for walk animation
let renderTick = 0;

// Draw a 16-bit style colonist directly (no cache for simplicity + dynamic state)
function drawColonist16bit(ctx, c, x, y, state) {
    const bodyColor = JOB_COLORS[c.job] || '#666';
    const skin = skinTone(c.name);
    const isMoving = c.pathIndex < c.pathCols.length;
    // 4-frame walk cycle: 0=right-forward, 1=neutral, 2=left-forward, 3=neutral
    const walkFrame = isMoving ? Math.floor(renderTick % 16 / 4) : -1;

    // Legs (2px wide, 5px long) -- 4-frame cycle
    ctx.fillStyle = '#2c2c2e';
    if (walkFrame === 0) {
        ctx.fillRect(x - 3, y + 5, 2, 5);
        ctx.fillRect(x + 1, y + 3, 2, 5);
    } else if (walkFrame === 2) {
        ctx.fillRect(x - 3, y + 3, 2, 5);
        ctx.fillRect(x + 1, y + 5, 2, 5);
    } else {
        ctx.fillRect(x - 3, y + 3, 2, 6);
        ctx.fillRect(x + 1, y + 3, 2, 6);
    }

    // Body (8x10 torso)
    ctx.fillStyle = bodyColor;
    ctx.fillRect(x - 4, y - 5, 8, 10);

    // Arms (2px wide) -- 4-frame swing
    ctx.fillStyle = skin;
    if (walkFrame === 0) {
        ctx.fillRect(x - 6, y - 3, 2, 5);
        ctx.fillRect(x + 4, y - 5, 2, 5);
    } else if (walkFrame === 2) {
        ctx.fillRect(x - 6, y - 5, 2, 5);
        ctx.fillRect(x + 4, y - 3, 2, 5);
    } else {
        ctx.fillRect(x - 6, y - 4, 2, 5);
        ctx.fillRect(x + 4, y - 4, 2, 5);
    }

    // Head (8x8 circle-ish)
    ctx.fillStyle = skin;
    ctx.beginPath();
    ctx.arc(x, y - 9, 4, 0, Math.PI * 2);
    ctx.fill();

    // Eyes (2 black dots)
    ctx.fillStyle = '#000';
    ctx.fillRect(x - 2, y - 10, 1, 1);
    ctx.fillRect(x + 1, y - 10, 1, 1);

    // Mouth
    ctx.fillRect(x - 1, y - 8, 2, 1);

}

// Building icon symbols
const BUILDING_ICONS = {
    shelter: (cx, x, y, w, h) => {
        // House with roof
        cx.fillStyle = 'rgba(41, 151, 255, 0.6)';
        cx.beginPath();
        cx.moveTo(x + w/2, y + 4);
        cx.lineTo(x + w - 6, y + h/2 - 2);
        cx.lineTo(x + 6, y + h/2 - 2);
        cx.closePath();
        cx.fill();
        cx.fillRect(x + w/2 - 6, y + h/2 - 2, 12, h/2 - 4);
        // Window
        cx.fillStyle = INK.wash;
        cx.fillRect(x + w/2 - 2, y + h/2, 4, 4);
    },
    generator: (cx, x, y, w, h) => {
        // Box with lightning bolt
        cx.fillStyle = 'rgba(255, 214, 10, 0.4)';
        cx.fillRect(x + 8, y + 8, w - 16, h - 16);
        cx.strokeStyle = 'rgba(255, 214, 10, 0.8)';
        cx.lineWidth = 2;
        cx.beginPath();
        cx.moveTo(x + w/2 + 2, y + 10);
        cx.lineTo(x + w/2 - 2, y + h/2);
        cx.lineTo(x + w/2 + 2, y + h/2);
        cx.lineTo(x + w/2 - 2, y + h - 10);
        cx.stroke();
    },
    drill: (cx, x, y, w, h) => {
        // Bit and shaft
        cx.fillStyle = 'rgba(255, 159, 10, 0.7)';
        cx.beginPath();
        cx.moveTo(x + w/2 - 7, y + 6);
        cx.lineTo(x + w/2 + 7, y + 6);
        cx.lineTo(x + w/2, y + h - 6);
        cx.closePath();
        cx.fill();
    },
    beacon: (cx, x, y, w, h) => {
        // Spire and light
        cx.fillStyle = 'rgba(255, 55, 95, 0.7)';
        cx.fillRect(x + w/2 - 3, y + 14, 6, h - 20);
        cx.beginPath();
        cx.arc(x + w/2, y + 10, 5, 0, Math.PI * 2);
        cx.fill();
    },
};

export function renderWorld(ctx, canvas, camera, grid, state) {
    renderTick++;
    ctx.save();
    camera.applyTransform(ctx, canvas);

    const bounds = camera.visibleBounds(canvas);

    // Tiles (sprite-cached with terrain variation)
    for (let r = bounds.minRow; r <= bounds.maxRow; r++) {
        for (let c = bounds.minCol; c <= bounds.maxCol; c++) {
            ctx.drawImage(getTileSprite(grid[r][c], c, r), c * TILE_SIZE, r * TILE_SIZE);
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
        ctx.beginPath();
        ctx.arc(x, y, 11, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalAlpha = 1;

        ctx.fillStyle = '#fff';
        ctx.font = 'bold 11px -apple-system, sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(ResourceSymbol[rn.type] || '', x, y);
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

        ctx.fillStyle = BUILDING_COLORS[b.type] || INK.track;
        roundRect(ctx, bx, by, bw, bh, TILE_R + 2);
        ctx.fill();

        ctx.strokeStyle = BUILDING_BORDER[b.type] || INK.washSoft;
        ctx.lineWidth = 1;
        roundRect(ctx, bx, by, bw, bh, TILE_R + 2);
        ctx.stroke();

        // Draw building icon
        const iconFn = BUILDING_ICONS[b.type];
        if (iconFn) {
            iconFn(ctx, bx, by, bw, bh);
        }

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

        // ponytail: scale the 12px pixel figure up in place rather than redraw it at a new size
        ctx.save(); ctx.translate(x, y); ctx.scale(1.8, 1.8); ctx.translate(-x, -y);
        drawColonist16bit(ctx, c, x, y, state);
        ctx.restore();

        // Name
        ctx.fillStyle = INK.label;
        ctx.font = '600 7px -apple-system, sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(c.name, x, y - 22);

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
