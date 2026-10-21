// BFS pathfinder -- replaces GKGridGraph from GameplayKit

import { GRID_SIZE, WalkableTiles } from './world.js';

export class Pathfinder {
    constructor() {
        this.walkable = null;
    }

    buildGraph(grid) {
        this.walkable = new Uint8Array(GRID_SIZE * GRID_SIZE);
        for (let r = 0; r < GRID_SIZE; r++) {
            for (let c = 0; c < GRID_SIZE; c++) {
                this.walkable[r * GRID_SIZE + c] = WalkableTiles.has(grid[r][c]) ? 1 : 0;
            }
        }
    }

    removeNode(col, row) {
        if (this.walkable && col >= 0 && col < GRID_SIZE && row >= 0 && row < GRID_SIZE) {
            this.walkable[row * GRID_SIZE + col] = 0;
        }
    }

    addNode(col, row) {
        if (this.walkable && col >= 0 && col < GRID_SIZE && row >= 0 && row < GRID_SIZE) {
            this.walkable[row * GRID_SIZE + col] = 1;
        }
    }

    findPath(fromCol, fromRow, toCol, toRow) {
        if (!this.walkable) return [];
        if (fromCol === toCol && fromRow === toRow) return [];

        const idx = (c, r) => r * GRID_SIZE + c;
        const startIdx = idx(fromCol, fromRow);
        const endIdx = idx(toCol, toRow);

        if (!this.walkable[startIdx] || !this.walkable[endIdx]) return [];

        // BFS with max step limit
        const maxSteps = 2000;
        const visited = new Uint8Array(GRID_SIZE * GRID_SIZE);
        const parent = new Int32Array(GRID_SIZE * GRID_SIZE).fill(-1);
        const queue = [startIdx];
        visited[startIdx] = 1;

        const dirs = [[0,1],[0,-1],[1,0],[-1,0]];
        let steps = 0;

        while (queue.length > 0 && steps < maxSteps) {
            const cur = queue.shift();
            if (cur === endIdx) break;
            steps++;

            const cr = Math.floor(cur / GRID_SIZE);
            const cc = cur % GRID_SIZE;

            for (const [dc, dr] of dirs) {
                const nc = cc + dc;
                const nr = cr + dr;
                if (nc < 0 || nc >= GRID_SIZE || nr < 0 || nr >= GRID_SIZE) continue;
                const ni = idx(nc, nr);
                if (visited[ni] || !this.walkable[ni]) continue;
                visited[ni] = 1;
                parent[ni] = cur;
                if (ni === endIdx) { queue.length = 0; break; }
                queue.push(ni);
            }
        }

        if (!visited[endIdx]) return [];

        // Reconstruct path
        const path = [];
        let cur = endIdx;
        while (cur !== startIdx && cur !== -1) {
            path.push({ col: cur % GRID_SIZE, row: Math.floor(cur / GRID_SIZE) });
            cur = parent[cur];
        }
        path.reverse();
        return path;
    }

    /// Path to the tile, or to any of its four neighbours when the tile itself is blocked
    /// (resource nodes can sit on building tiles; harvesting works from one tile away).
    findPathNear(fromCol, fromRow, toCol, toRow) {
        for (const [dc, dr] of [[0,0],[1,0],[-1,0],[0,1],[0,-1]]) {
            const p = this.findPath(fromCol, fromRow, toCol + dc, toRow + dr);
            if (p.length) return p;
        }
        return [];
    }
}
