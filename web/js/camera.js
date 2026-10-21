// Camera -- pan/zoom for canvas

import { GRID_SIZE, TILE_SIZE } from './world.js';

export class Camera {
    constructor() {
        this.x = (GRID_SIZE * TILE_SIZE) / 2;
        this.y = (GRID_SIZE * TILE_SIZE) / 2;
        this.zoom = 1.0;
        this.minZoom = 0.3;
        this.maxZoom = 3.0;
        this.panSpeed = 400;
        this.panX = 0;
        this.panY = 0;
        this.dragging = false;
        this.dragStartX = 0;
        this.dragStartY = 0;
        this.dragCamStartX = 0;
        this.dragCamStartY = 0;
    }

    update(dt) {
        this.x += this.panX * this.panSpeed * dt * this.zoom;
        this.y += this.panY * this.panSpeed * dt * this.zoom;
    }

    zoomBy(amount) {
        this.zoom = Math.max(this.minZoom, Math.min(this.maxZoom, this.zoom - amount));
    }

    applyTransform(ctx, canvas) {
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        ctx.translate(canvas.width / 2, canvas.height / 2);
        ctx.scale(1 / this.zoom, 1 / this.zoom);
        ctx.translate(-this.x, -this.y);
    }

    screenToWorld(sx, sy, canvas) {
        const wx = (sx - canvas.width / 2) * this.zoom + this.x;
        const wy = (sy - canvas.height / 2) * this.zoom + this.y;
        return { x: wx, y: wy };
    }

    worldToScreen(wx, wy, canvas) {
        const sx = (wx - this.x) / this.zoom + canvas.width / 2;
        const sy = (wy - this.y) / this.zoom + canvas.height / 2;
        return { x: sx, y: sy };
    }

    // Visible tile bounds (for culling)
    visibleBounds(canvas) {
        const halfW = (canvas.width / 2) * this.zoom;
        const halfH = (canvas.height / 2) * this.zoom;
        return {
            minCol: Math.max(0, Math.floor((this.x - halfW) / TILE_SIZE)),
            maxCol: Math.min(GRID_SIZE - 1, Math.ceil((this.x + halfW) / TILE_SIZE)),
            minRow: Math.max(0, Math.floor((this.y - halfH) / TILE_SIZE)),
            maxRow: Math.min(GRID_SIZE - 1, Math.ceil((this.y + halfH) / TILE_SIZE)),
        };
    }
}
