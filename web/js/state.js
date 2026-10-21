// Game state and models. 2.0: gather with a swarm, build machines, raise the Beacon.

let _nextId = 0;
export function uuid() { return `${++_nextId}-${Math.random().toString(36).slice(2, 8)}`; }

export const ResourceTypes = ['food', 'materials', 'power'];
export const ResourceSymbol = { food: 'F', materials: 'M', power: 'P' };

// Machines run on their own (systems.js machineTick). The Beacon is the win.
export const BuildingType = {
    shelter:   { name: 'Shelter',   cost: { materials: 10 },                desc: '+4 beds',                          size: [2,2] },
    generator: { name: 'Generator', cost: { materials: 15 },                desc: '+1 power every 2 ticks',            size: [2,2] },
    drill:     { name: 'Drill',     cost: { materials: 12, power: 2 },      desc: 'Next to a resource: +1 every 2 ticks, burns power', size: [1,1] },
    beacon:    { name: 'Beacon',    cost: { materials: 8000, power: 1000 },   desc: 'Raise it to win',                   size: [2,2] },
};
export const BuildingTypes = Object.keys(BuildingType);

function randInt(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }

const COLONIST_NAMES = [
    'Alex', 'Jordan', 'Casey', 'Riley', 'Morgan', 'Sam', 'Taylor', 'Avery', 'Quinn', 'Blake',
    'Charlie', 'Drew', 'Emery', 'Finley', 'Harper', 'Jesse', 'Dakota', 'Sage', 'Rowan', 'Phoenix',
    'Kai', 'Reese', 'Ellis', 'Skyler', 'Marley', 'Lennox', 'River', 'Hayden', 'Remy', 'Kit',
];

export function randomColonistName(existing) {
    const used = new Set(existing.map(c => c.name));
    const available = COLONIST_NAMES.filter(n => !used.has(n));
    return available.length ? available[randInt(0, available.length - 1)] : `Agent-${randInt(100,999)}`;
}

export function createColonist(name, col, row) {
    return { id: uuid(), name, col, row, job: 'idle', pathCols: [], pathRows: [], pathIndex: 0 };
}

export function createBuilding(type, col, row) {
    return { id: uuid(), type, col, row };
}

export function createResource(type, col, row, maxAmount) {
    return { id: uuid(), type, col, row, remaining: maxAmount, maxAmount, respawnTicks: 60, ticksSinceDepleted: 0 };
}

export function createGameState() {
    return {
        resources: { food: 30, materials: 40, power: 0 },
        colonists: [],
        buildings: [],
        resourceNodes: [],
        selectedColonistId: null,
        selectedColonistIds: new Set(),
        isPaused: false,
        currentTick: 0,
        currentHour: 0,
        isNight: false,
        inputMode: 'normal',
        selectedBuildingType: null,
        gameLog: [],
        showBuildMenu: false,
        showSettings: false,
        wallpaperMode: false,
        demoMode: false,
        tutorialStep: 0,
        lastSaveSlot: null,
        autoSaveEnabled: true,
        showSaveIndicator: false,
        toastMessage: null,       // { text, ticks }
    };
}

export function gameLog(state, msg) {
    state.gameLog.push(msg);
    if (state.gameLog.length > 50) state.gameLog.shift();
}

export function selectedColonist(state) {
    if (!state.selectedColonistId) return null;
    return state.colonists.find(c => c.id === state.selectedColonistId) || null;
}

// Victory: the Beacon stands.
export function checkVictory(state) {
    return state.buildings.some(b => b.type === 'beacon');
}
