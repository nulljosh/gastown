// Input handler -- keyboard, mouse, touch

import { worldToTile, TILE_SIZE } from './world.js';
import { BuildingTypes } from './state.js';

function safe(fn) { try { fn(); } catch (e) { console.error('Input error:', e); } }

export function setupInput(canvas, camera, state, callbacks) {
    const keys = {};

    document.addEventListener('keydown', e => {
        if (e.repeat) return;
        keys[e.key.toLowerCase()] = true;

        // Cmd/Ctrl+S save
        if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 's') {
            e.preventDefault();
            safe(() => callbacks.onSave());
            return;
        }

        switch (e.key.toLowerCase()) {
            case 'arrowup': camera.panY = -1; break;
            case 'arrowdown': camera.panY = 1; break;
            case 'arrowleft': camera.panX = -1; break;
            case 'arrowright': camera.panX = 1; break;
            case 'w':
                if (e.shiftKey) {
                    // Shift+W = wallpaper mode
                    state.wallpaperMode = !state.wallpaperMode;
                    safe(() => callbacks.onHudUpdate());
                } else {
                    camera.panY = -1;
                }
                break;
            case 's': camera.panY = 1; break;
            case 'a': camera.panX = -1; break;
            case 'd': camera.panX = 1; break;
            case 'q':
                state.showQuestBoard = !state.showQuestBoard;
                safe(() => callbacks.onHudUpdate());
                break;
            case 'b':
                state.showBuildMenu = !state.showBuildMenu;
                if (!state.showBuildMenu) state.inputMode = 'normal';
                safe(() => callbacks.onHudUpdate());
                safe(() => callbacks.onTutorial('buildMenuOpened'));
                break;
            case ' ':
                e.preventDefault();
                state.isPaused = !state.isPaused;
                safe(() => callbacks.onHudUpdate());
                break;
            case '1': case '2': case '3': case '4': case '5': case '6':
                const idx = parseInt(e.key) - 1;
                if (idx < BuildingTypes.length) {
                    state.selectedBuildingType = BuildingTypes[idx];
                    state.inputMode = 'build';
                    state.showBuildMenu = true;
                    safe(() => callbacks.onHudUpdate());
                }
                break;
            case 'x':
                state.inputMode = state.inputMode === 'demolish' ? 'normal' : 'demolish';
                safe(() => callbacks.onHudUpdate());
                break;
            case 'escape':
                if (state.selectedColonistId || (state.selectedColonistIds && state.selectedColonistIds.size)) {
                    state.selectedColonistId = null;
                    state.selectedColonistIds = new Set();
                } else if (state.inputMode !== 'normal' || state.showBuildMenu) {
                    state.inputMode = 'normal';
                    state.selectedBuildingType = null;
                    state.showBuildMenu = false;
                } else {
                    state.showSettings = !state.showSettings;
                    state.isPaused = state.showSettings;
                }
                safe(() => callbacks.onHudUpdate());
                break;
        }

        safe(() => callbacks.onTutorial('wasdPressed'));
    });

    document.addEventListener('keyup', e => {
        keys[e.key.toLowerCase()] = false;
        switch (e.key.toLowerCase()) {
            case 'w': case 's': case 'arrowup': case 'arrowdown': camera.panY = 0; break;
            case 'a': case 'd': case 'arrowleft': case 'arrowright': camera.panX = 0; break;
        }
    });

    // Mouse
    let dragStart = null;
    let isDragging = false;
    let isSelecting = false;
    let selStart = null;
    let selClient = null;

    canvas.addEventListener('mousedown', e => {
        const rect = canvas.getBoundingClientRect();
        const sx = (e.clientX - rect.left) * (canvas.width / rect.width);
        const sy = (e.clientY - rect.top) * (canvas.height / rect.height);
        const world = camera.screenToWorld(sx, sy, canvas);

        if (e.button === 2 || e.button === 1) {
            dragStart = { sx: e.clientX, sy: e.clientY, cx: camera.x, cy: camera.y };
            isDragging = true;
            return;
        }

        if (e.shiftKey || state.inputMode === 'normal') {
            isSelecting = true;
            selStart = world;
            selClient = { x: e.clientX, y: e.clientY };
            return;
        }

        const tile = worldToTile(world.x, world.y);

        switch (state.inputMode) {
            case 'normal':
                safe(() => callbacks.onSelectEntity(world.x, world.y));
                break;
            case 'build':
                safe(() => callbacks.onPlaceBuilding(tile.col, tile.row));
                break;
            case 'demolish':
                safe(() => callbacks.onDemolish(world.x, world.y));
                break;
        }
    });

    canvas.addEventListener('mousemove', e => {
        if (isDragging && dragStart) {
            const dx = (e.clientX - dragStart.sx) * camera.zoom;
            const dy = (e.clientY - dragStart.sy) * camera.zoom;
            camera.x = dragStart.cx - dx;
            camera.y = dragStart.cy - dy;
            return;
        }

        if (isSelecting && selStart) {
            const rect = canvas.getBoundingClientRect();
            const sx = (e.clientX - rect.left) * (canvas.width / rect.width);
            const sy = (e.clientY - rect.top) * (canvas.height / rect.height);
            const world = camera.screenToWorld(sx, sy, canvas);
            state._selRect = {
                x: Math.min(selStart.x, world.x),
                y: Math.min(selStart.y, world.y),
                w: Math.abs(world.x - selStart.x),
                h: Math.abs(world.y - selStart.y),
            };
            return;
        }

        if (state.inputMode === 'build' && state.selectedBuildingType) {
            const rect = canvas.getBoundingClientRect();
            const sx = (e.clientX - rect.left) * (canvas.width / rect.width);
            const sy = (e.clientY - rect.top) * (canvas.height / rect.height);
            const world = camera.screenToWorld(sx, sy, canvas);
            const tile = worldToTile(world.x, world.y);
            state._ghostCol = tile.col;
            state._ghostRow = tile.row;
        }
    });

    canvas.addEventListener('mouseup', e => {
        if (isDragging) { isDragging = false; dragStart = null; return; }
        if (isSelecting && selStart) {
            const rect = canvas.getBoundingClientRect();
            const sx = (e.clientX - rect.left) * (canvas.width / rect.width);
            const sy = (e.clientY - rect.top) * (canvas.height / rect.height);
            const world = camera.screenToWorld(sx, sy, canvas);
            const moved = selClient && Math.hypot(e.clientX - selClient.x, e.clientY - selClient.y) > 6;
            if (moved) safe(() => callbacks.onBoxSelect(selStart, world));
            else safe(() => callbacks.onSelectEntity(selStart.x, selStart.y));
            isSelecting = false;
            selStart = null;
            state._selRect = null;
            return;
        }
    });

    canvas.addEventListener('wheel', e => {
        e.preventDefault();
        camera.zoomBy(e.deltaY * 0.002);
    }, { passive: false });

    canvas.addEventListener('contextmenu', e => e.preventDefault());

    // Touch support
    let touches = {};
    let lastPinchDist = null;

    canvas.addEventListener('touchstart', e => {
        e.preventDefault();
        for (const t of e.changedTouches) touches[t.identifier] = { x: t.clientX, y: t.clientY };

        if (Object.keys(touches).length === 1) {
            const t = e.changedTouches[0];
            dragStart = { sx: t.clientX, sy: t.clientY, cx: camera.x, cy: camera.y };
            isDragging = true;
        }
    }, { passive: false });

    canvas.addEventListener('touchmove', e => {
        e.preventDefault();
        for (const t of e.changedTouches) touches[t.identifier] = { x: t.clientX, y: t.clientY };

        const ids = Object.keys(touches);
        if (ids.length === 2) {
            const [a, b] = ids.map(id => touches[id]);
            const dist = Math.hypot(a.x - b.x, a.y - b.y);
            if (lastPinchDist !== null) {
                const delta = lastPinchDist - dist;
                camera.zoomBy(delta * 0.005);
            }
            lastPinchDist = dist;
        } else if (isDragging && dragStart && ids.length === 1) {
            const t = e.changedTouches[0];
            const dx = (t.clientX - dragStart.sx) * camera.zoom;
            const dy = (t.clientY - dragStart.sy) * camera.zoom;
            camera.x = dragStart.cx - dx;
            camera.y = dragStart.cy - dy;
        }
    }, { passive: false });

    canvas.addEventListener('touchend', e => {
        const t0 = e.changedTouches[0];
        if (dragStart && t0 && Object.keys(touches).length === 1 &&
            Math.hypot(t0.clientX - dragStart.sx, t0.clientY - dragStart.sy) < 8) {
            const rect = canvas.getBoundingClientRect();
            const sx = (t0.clientX - rect.left) * (canvas.width / rect.width);
            const sy = (t0.clientY - rect.top) * (canvas.height / rect.height);
            const world = camera.screenToWorld(sx, sy, canvas);
            const tile = worldToTile(world.x, world.y);
            if (state.inputMode === 'build') safe(() => callbacks.onPlaceBuilding(tile.col, tile.row));
            else if (state.inputMode === 'demolish') safe(() => callbacks.onDemolish(world.x, world.y));
            else safe(() => callbacks.onSelectEntity(world.x, world.y));
        }
        for (const t of e.changedTouches) delete touches[t.identifier];
        if (Object.keys(touches).length < 2) lastPinchDist = null;
        if (Object.keys(touches).length === 0) { isDragging = false; dragStart = null; }
    });
}
