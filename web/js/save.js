// Save/load -- localStorage, 3 slots

const SAVE_KEY = 'nyc_save_';

export function saveGame(slot, state, grid) {
    const flatGrid = [];
    for (let r = 0; r < grid.length; r++) {
        for (let c = 0; c < grid[r].length; c++) {
            flatGrid.push(grid[r][c]);
        }
    }

    const data = {
        colonists: state.colonists.map(c => ({
            ...c,
            selectedColonistIds: undefined,
        })),
        buildings: state.buildings,
        resourceNodes: state.resourceNodes,
        resources: state.resources,
        currentTick: state.currentTick,
        flatGrid,
        gridSize: grid.length,
        // Quest data
        questList: state.questList,
        rewardList: state.rewardList,
        playerXP: state.playerXP,
        playerStreak: state.playerStreak,
        playerLastActive: state.playerLastActive,
        questLog: state.questLog,
        slot: {
            slot,
            saveName: `Slot ${slot}`,
            timestamp: Date.now(),
            dayCount: Math.floor(state.currentTick / 240),
            colonistCount: state.colonists.filter(c => c.state !== 'dead').length,
        }
    };

    try {
        localStorage.setItem(SAVE_KEY + slot, JSON.stringify(data));
    } catch { /* quota exceeded or private browsing */ }
    return data.slot;
}

export function loadGame(slot) {
    const raw = localStorage.getItem(SAVE_KEY + slot);
    if (!raw) return null;
    try {
        const data = JSON.parse(raw);
        // Restore Set for selectedColonistIds
        for (const c of data.colonists) {
            if (!c.pathCols) c.pathCols = [];
            if (!c.pathRows) c.pathRows = [];
        }
        delete data.autoplay; // old saves may have it, engine deleted
        return data;
    } catch { return null; }
}

export function listSlots() {
    return [1, 2, 3].map(slot => {
        const data = loadGame(slot);
        return data ? data.slot : null;
    });
}

export function deleteSlot(slot) {
    try { localStorage.removeItem(SAVE_KEY + slot); } catch { /* private browsing */ }
}

export function rebuildGrid(saveData) {
    const size = saveData.gridSize;
    const grid = [];
    for (let r = 0; r < size; r++) {
        grid[r] = new Int8Array(size);
        for (let c = 0; c < size; c++) {
            const idx = r * size + c;
            grid[r][c] = idx < saveData.flatGrid.length ? saveData.flatGrid[idx] : 6;
        }
    }
    return grid;
}
