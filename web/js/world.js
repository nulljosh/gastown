// World generation -- direct port from Swift WorldGenerator + TileType + TileMap

import { createResource } from './state.js';

export const GRID_SIZE = 128;
export const TILE_SIZE = 32;

const AVENUE_SPACING = 16;
const STREET_SPACING = 12;
const AVENUE_WIDTH = 4;
const STREET_WIDTH = 3;

export const TileType = { road: 0, sidewalk: 1, building: 2, billboard: 3, subway: 4, sewer: 5, empty: 6 };

// Canvas can't read CSS custom properties, so the world palette is duplicated
// per theme here. Keep the keys in sync with the --bg/--pink/--yellow tokens.
const TILE_PALETTES = {
    dark: {
        [TileType.road]:      '#1c1c1e',
        [TileType.sidewalk]:  '#3a3a3c',
        [TileType.building]:  '#0a0a0c',
        [TileType.billboard]: '#ff375f',
        [TileType.subway]:    '#ffd60a',
        [TileType.sewer]:     '#2c3e2c',
        [TileType.empty]:     '#0a0a0c',
    },
    light: {
        [TileType.road]:      '#c9c9cd',
        [TileType.sidewalk]:  '#e4e4e7',
        [TileType.building]:  '#a8a8ae',
        [TileType.billboard]: '#c9134a',
        [TileType.subway]:    '#c99700',
        [TileType.sewer]:     '#9db29d',
        [TileType.empty]:     '#ececee',
    },
};

// Live binding — importers see reassignment, so setTilePalette() repaints everyone.
export let TileColors = TILE_PALETTES.dark;

export function setTilePalette(theme) {
    TileColors = TILE_PALETTES[theme] || TILE_PALETTES.dark;
}

export const WalkableTiles = new Set([TileType.road, TileType.sidewalk, TileType.subway]);

function isAvenueCol(col) { const o = col % AVENUE_SPACING; return o >= 0 && o < AVENUE_WIDTH; }
function isStreetRow(row) { const o = row % STREET_SPACING; return o >= 0 && o < STREET_WIDTH; }
function isAvenueSidewalkCol(col) { const o = col % AVENUE_SPACING; return o === AVENUE_WIDTH || (o === AVENUE_SPACING - 1 && col > 0); }
function isStreetSidewalkRow(row) { const o = row % STREET_SPACING; return o === STREET_WIDTH || (o === STREET_SPACING - 1 && row > 0); }

export function generateWorld() {
    const grid = [];
    for (let r = 0; r < GRID_SIZE; r++) {
        grid[r] = new Int8Array(GRID_SIZE);
        grid[r].fill(TileType.building);
    }

    for (let r = 0; r < GRID_SIZE; r++) {
        for (let c = 0; c < GRID_SIZE; c++) {
            if (isAvenueCol(c) || isStreetRow(r)) grid[r][c] = TileType.road;
            else if (isAvenueSidewalkCol(c) || isStreetSidewalkRow(r)) grid[r][c] = TileType.sidewalk;
        }
    }

    for (let r = STREET_SPACING; r < GRID_SIZE; r += STREET_SPACING) {
        for (let c = AVENUE_SPACING; c < GRID_SIZE; c += AVENUE_SPACING) {
            if (r < GRID_SIZE && c < GRID_SIZE) grid[r][c] = TileType.subway;
        }
    }

    for (let r = 0; r < GRID_SIZE; r++) {
        for (let c = 0; c < GRID_SIZE; c++) {
            if (grid[r][c] === TileType.building) {
                const adjAvenue = isAvenueSidewalkCol(c - 1) || isAvenueSidewalkCol(c + 1);
                if (adjAvenue && Math.random() < 0.2) grid[r][c] = TileType.billboard;
            }
        }
    }

    const resources = [];
    const resTypes = ['food','food','food','materials','materials','power','oxygen','cash'];
    const maxAmounts = { food: 10, materials: 15, power: 8, oxygen: 12, cash: 20 };

    for (let r = 0; r < GRID_SIZE; r++) {
        for (let c = 0; c < GRID_SIZE; c++) {
            if (grid[r][c] === TileType.sidewalk && Math.random() < 0.025) {
                const rtype = resTypes[Math.floor(Math.random() * resTypes.length)];
                resources.push(createResource(rtype, c, r, maxAmounts[rtype]));
            }
        }
    }

    return { grid, resources };
}

export function tileAt(grid, col, row) {
    if (col < 0 || col >= GRID_SIZE || row < 0 || row >= GRID_SIZE) return null;
    return grid[row][col];
}

export function setTile(grid, col, row, type) {
    if (col >= 0 && col < GRID_SIZE && row >= 0 && row < GRID_SIZE) grid[row][col] = type;
}

export function worldToTile(wx, wy) {
    return {
        col: Math.max(0, Math.min(Math.floor(wx / TILE_SIZE), GRID_SIZE - 1)),
        row: Math.max(0, Math.min(Math.floor(wy / TILE_SIZE), GRID_SIZE - 1)),
    };
}

export function tileToWorld(col, row) {
    return { x: col * TILE_SIZE + TILE_SIZE / 2, y: row * TILE_SIZE + TILE_SIZE / 2 };
}
