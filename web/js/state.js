// Game state and models -- NYC + Quest integrated

let _nextId = 0;
export function uuid() { return `${++_nextId}-${Math.random().toString(36).slice(2, 8)}`; }

export const ResourceType = { food: 'food', power: 'power', materials: 'materials', oxygen: 'oxygen', cash: 'cash' };
export const ResourceTypes = ['food', 'power', 'materials', 'oxygen', 'cash'];
export const ResourceSymbol = { food: 'F', power: 'P', materials: 'M', oxygen: 'O', cash: '$' };

export const ColonistJob = { idle: 'idle', gather: 'gather', build: 'build', patrol: 'patrol', attack: 'attack', quest: 'quest' };
export const ColonistJobs = ['idle', 'gather', 'build', 'patrol', 'attack', 'quest'];

export const ColonyDirective = { idle: 'idle', gather: 'gather', build: 'build', patrol: 'patrol' };
export const ColonyDirectives = ['idle', 'gather', 'build', 'patrol'];

export const WeaponTypes = {
    fists:   { damage: 5,  range: 1, name: 'FISTS' },
    pipe:    { damage: 10, range: 1, name: 'PIPE' },
    bat:     { damage: 12, range: 1, name: 'BAT' },
    pistol:  { damage: 20, range: 5, name: 'PISTOL' },
    shotgun: { damage: 30, range: 3, name: 'SHOTGUN' },
    rifle:   { damage: 25, range: 8, name: 'RIFLE' },
};

export const Traits = {
    hustler:   { name: 'Hustler',   desc: '+20% XP gain' },
    scavenger: { name: 'Scavenger', desc: '+1 resource per harvest' },
    insomniac: { name: 'Insomniac', desc: '30% slower sleep decay' },
    ironlung:  { name: 'Ironlung',  desc: '30% slower oxygen decay' },
    anxious:   { name: 'Anxious',   desc: '2x stress gain' },
};
export const TraitKeys = Object.keys(Traits);

export const BuildingType = {
    shelter:       { name: 'Shelter',        cost: { materials: 10 },              desc: 'Reduces stress for nearby colonists',   size: [2,2] },
    foodStall:     { name: 'Food Stall',     cost: { materials: 8, cash: 5 },      desc: 'Converts food resources into meals',    size: [1,1] },
    generator:     { name: 'Generator',      cost: { materials: 15, cash: 10 },    desc: 'Produces power from materials',         size: [2,2] },
    filterStation: { name: 'Filter Station', cost: { materials: 12, power: 5 },    desc: 'Filters oxygen using power',            size: [2,2] },
    subwayAccess:  { name: 'Subway Access',  cost: { materials: 20, cash: 15 },    desc: 'Fast travel between subway stations',   size: [1,1] },
    billboard:     { name: 'Billboard',      cost: { materials: 5, cash: 20 },     desc: 'Generates cash over time',              size: [2,1] },
    questBoard:    { name: 'Quest Board',    cost: { materials: 15, cash: 10 },   desc: 'Posts real-life quests for colonists',   size: [2,2] },
    gym:           { name: 'Gym',            cost: { materials: 20, cash: 15 },   desc: 'Colonists train here (fitness quests)',  size: [2,2] },
    library:       { name: 'Library',        cost: { materials: 18, cash: 12 },   desc: 'Colonists study here (study quests)',    size: [2,2] },
    workshop:      { name: 'Workshop',       cost: { materials: 25, cash: 20 },   desc: 'Colonists work here (work quests)',      size: [2,2] },
};
export const BuildingTypes = Object.keys(BuildingType);

// Quest system types (absorbed from standalone Quest app)
export const DifficultyXP = { F: 10, D: 25, C: 50, B: 100, A: 200, S: 500 };
export const DifficultyRanks = ['F', 'D', 'C', 'B', 'A', 'S'];
export const QuestCategories = ['fitness', 'study', 'work', 'personal', 'creative', 'errand'];
export const CategoryInfo = {
    fitness:  { label: 'Fitness',  className: 'Warrior',  color: '#ff375f', statBoost: ['str', 'end'] },
    study:    { label: 'Study',    className: 'Mage',     color: '#0071e3', statBoost: ['int', 'cha'] },
    work:     { label: 'Work',     className: 'Rogue',    color: '#30d158', statBoost: ['agi', 'int'] },
    personal: { label: 'Personal', className: 'Ranger',   color: '#ff9f0a', statBoost: ['end', 'agi'] },
    creative: { label: 'Creative', className: 'Bard',     color: '#bf5af2', statBoost: ['cha', 'str'] },
    errand:   { label: 'Errand',   className: 'Merchant', color: '#ac8e68', statBoost: ['int', 'cha'] },
};
export const LevelTitles = ['Squire', 'Knight', 'Champion', 'Hero', 'Legend', 'Mythic'];

export const QuestBuildings = {
    fitness: 'gym', study: 'library', work: 'workshop',
    personal: 'questBoard', creative: 'library', errand: 'questBoard',
};

export function questLevel(totalXP) { return Math.floor(Math.sqrt(totalXP / 50)); }
export function questTitle(level) { return LevelTitles[Math.min(Math.max(level, 0), LevelTitles.length - 1)]; }
export function questXPForNext(level) { return (level + 1) * (level + 1) * 50; }
export function questXPProgress(totalXP) {
    const level = questLevel(totalXP);
    const cur = level * level * 50;
    const next = (level + 1) * (level + 1) * 50;
    return { level, progress: totalXP - cur, needed: next - cur, percent: (totalXP - cur) / (next - cur) * 100 };
}

export function createReward(text) {
    return { id: crypto.randomUUID(), text, active: true };
}

export function createQuest({ title, difficulty = 'C', category = 'personal', notes = '', dueDate = null, autoGenerated = false }) {
    return {
        id: crypto.randomUUID(),
        title, difficulty, category, notes, dueDate, autoGenerated,
        completed: false, completedAt: null,
        createdAt: new Date().toISOString(),
    };
}

function randInt(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function randomStats() { return { str: randInt(1,10), int: randInt(1,10), agi: randInt(1,10), end: randInt(1,10), cha: randInt(1,10) }; }
function randomTrait() { return TraitKeys[randInt(0, TraitKeys.length - 1)]; }

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
    return {
        id: uuid(), name, col, row,
        hunger: 100, oxygen: 100, stress: 0, sleep: 100, health: 100,
        job: 'idle', jobOverride: false, state: 'healthy',
        weapon: 'fists', attackTargetId: null,
        inventory: {},
        pathCols: [], pathRows: [], pathIndex: 0,
        stats: randomStats(), xp: 0, level: 1,
        trait: randomTrait(),
        activeQuest: null,
        questBubble: null,
        questsCompleted: 0,
        dominantCategory: null,
    };
}

export function colonistClass(c) {
    if (!c.dominantCategory) return null;
    return CategoryInfo[c.dominantCategory]?.className || null;
}

export function colonistXpForNext(c) {
    if (c.level <= 3) return 50;
    if (c.level <= 6) return 100;
    if (c.level <= 9) return 200;
    return 300;
}
export function colonistXpProgress(c) { return c.xp / colonistXpForNext(c); }
export function grantXP(c, amount) {
    const adjusted = c.trait === 'hustler' ? Math.floor(amount * 1.2) : amount;
    c.xp += adjusted;
    const prevLevel = c.level;
    let next = colonistXpForNext(c);
    while (c.xp >= next) {
        c.xp -= next;
        c.level++;
        const stats = ['str','int','agi','end','cha'];
        const s = stats[randInt(0,4)];
        c.stats[s] = Math.min(10, c.stats[s] + 1);
        next = colonistXpForNext(c);
    }
    return c.level > prevLevel;
}

export function takeDamage(c, amount) {
    c.health = Math.max(0, c.health - amount);
    if (c.health <= 0) c.state = 'dead';
}

export function updateColonistState(c) {
    if (c.state === 'dead') return;
    if (c.health <= 0 || c.hunger <= 0 || c.oxygen <= 0 || c.sleep <= 0) { c.state = 'dead'; return; }
    if (c.hunger < 20) c.state = 'hungry';
    else if (c.oxygen < 20) c.state = 'suffocating';
    else if (c.sleep < 20) c.state = 'exhausted';
    else c.state = 'healthy';
}

export function createBuilding(type, col, row) {
    return { id: uuid(), type, col, row, isActive: true };
}

export function createResource(type, col, row, maxAmount) {
    return { id: uuid(), type, col, row, remaining: maxAmount, maxAmount, respawnTicks: 60, ticksSinceDepleted: 0 };
}

export function createGameState() {
    return {
        resources: { food: 60, power: 10, materials: 30, oxygen: 60, cash: 25 },
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
        showQuestBoard: false,
        wallpaperMode: false,
        demoMode: false,
        tutorialStep: 0,
        lastSaveSlot: null,
        autoSaveEnabled: true,
        showSaveIndicator: false,
        // Quest system (integrated)
        questList: [],            // full quest objects with CRUD
        rewardList: [],           // dopamine rewards
        questLog: [],             // completed quest log
        playerXP: 0,
        playerStreak: 0,
        playerLastActive: null,
        toastMessage: null,       // { text, ticks }
    };
}

// Migrate quest data from standalone Quest app on first load
export function migrateQuestData(state) {
    try {
        const quests = localStorage.getItem('quest:quests');
        if (quests) {
            const parsed = JSON.parse(quests);
            if (parsed.length && !state.questList.length) {
                state.questList = parsed;
            }
        }
        const rewards = localStorage.getItem('quest:rewards');
        if (rewards) {
            const parsed = JSON.parse(rewards);
            if (parsed.length && !state.rewardList.length) {
                state.rewardList = parsed;
            }
        }
        const profile = localStorage.getItem('quest:profile');
        if (profile) {
            const p = JSON.parse(profile);
            if (p.totalXP && !state.playerXP) {
                state.playerXP = p.totalXP;
                state.playerStreak = p.currentStreak || 0;
                state.playerLastActive = p.lastActiveDate;
            }
        }
    } catch { /* no standalone data */ }
}

// Write back to quest:quests for backward compat
export function syncQuestsToLocalStorage(state) {
    try {
        localStorage.setItem('quest:quests', JSON.stringify(state.questList));
        localStorage.setItem('quest:profile', JSON.stringify({
            name: 'Adventurer',
            totalXP: state.playerXP,
            currentStreak: state.playerStreak,
            lastActiveDate: state.playerLastActive,
        }));
        localStorage.setItem('quest:rewards', JSON.stringify(state.rewardList));
    } catch { /* storage full */ }
}

export function addQuest(state, data) {
    const quest = createQuest(data);
    state.questList.unshift(quest);
    syncQuestsToLocalStorage(state);
    gameLog(state, `New quest: ${quest.title}`);
    return quest;
}

export function completeQuestInList(state, questId) {
    const quest = state.questList.find(q => q.id === questId);
    if (!quest || quest.completed) return null;
    quest.completed = true;
    quest.completedAt = new Date().toISOString();
    const xp = DifficultyXP[quest.difficulty] || 50;
    state.playerXP += xp;
    updatePlayerStreak(state);
    syncQuestsToLocalStorage(state);
    // Roll reward
    const active = state.rewardList.filter(r => r.active);
    if (active.length && Math.random() < 0.8) {
        const reward = active[Math.floor(Math.random() * active.length)];
        state.toastMessage = { text: reward.text, ticks: 120 };
    } else if (active.length) {
        state.toastMessage = { text: 'The gods demand more...', ticks: 80 };
    }
    return { quest, xp };
}

export function updatePlayerStreak(state) {
    const today = new Date().toISOString().slice(0, 10);
    if (state.playerLastActive === today) return;
    const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
    state.playerStreak = state.playerLastActive === yesterday ? state.playerStreak + 1 : 1;
    state.playerLastActive = today;
}

export function activeQuests(state) { return state.questList.filter(q => !q.completed); }
export function completedQuests(state) { return state.questList.filter(q => q.completed); }

export function gameLog(state, msg) {
    state.gameLog.push(msg);
    if (state.gameLog.length > 50) state.gameLog.shift();
}

export function selectedColonist(state) {
    if (!state.selectedColonistId) return null;
    return state.colonists.find(c => c.id === state.selectedColonistId) || null;
}

// Game phases and victory
export const GamePhase = {
    SURVIVAL: 'SURVIVAL',
    GROWTH: 'GROWTH',
    MASTERY: 'MASTERY',
    VICTORY: 'VICTORY',
};

export function currentPhase(state) {
    const alive = state.colonists.filter(c => c.state !== 'dead');
    if (!alive.length) return GamePhase.SURVIVAL;
    const avgLevel = alive.reduce((s, c) => s + c.level, 0) / alive.length;
    if (alive.length >= 15 && avgLevel >= 8) return GamePhase.VICTORY;
    if (alive.length >= 10 && avgLevel >= 5) return GamePhase.MASTERY;
    if (alive.length >= 5) return GamePhase.GROWTH;
    return GamePhase.SURVIVAL;
}

export function checkVictory(state) {
    const alive = state.colonists.filter(c => c.state !== 'dead');
    if (!alive.length) return false;
    const avgLevel = alive.reduce((s, c) => s + c.level, 0) / alive.length;
    return alive.length >= 15 && avgLevel >= 8 && alive.some(c => c.level >= 10);
}
