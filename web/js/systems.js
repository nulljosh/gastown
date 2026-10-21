// Game systems -- NeedsSystem, TimeSystem, ResourceSystem, BuildSystem, JobSystem, QuestSystem

import { grantXP, takeDamage, updateColonistState, gameLog, createBuilding, createColonist,
    WeaponTypes, BuildingType, QuestBuildings, CategoryInfo, DifficultyXP,
    activeQuests, addQuest, randomColonistName, colonistClass, syncQuestsToLocalStorage,
    currentPhase, GamePhase } from './state.js';
import { spawnDamage, spawnXP, spawnQuestComplete, spawnLevelUp } from './particles.js';
import { TileType, tileAt, setTile, GRID_SIZE } from './world.js';

// TimeSystem -- uses real clock for day/night in wallpaper mode
const TICKS_PER_DAY = 240;
let accumulated = 0;
let TICK_INTERVAL = 0.25;
export function setDifficulty(level) {
    if (level === 'easy')   { TICK_INTERVAL = 0.35; }
    if (level === 'medium') { TICK_INTERVAL = 0.25; }
    if (level === 'hard')   { TICK_INTERVAL = 0.15; }
}

export function timeTick(dt, state) {
    if (state.isPaused) return false;
    accumulated += dt;
    if (accumulated >= TICK_INTERVAL) {
        accumulated -= TICK_INTERVAL;
        state.currentTick++;
        if (state.wallpaperMode) {
            state.currentHour = new Date().getHours();
        } else {
            state.currentHour = Math.floor((state.currentTick % TICKS_PER_DAY) / 10);
        }
        state.isNight = state.currentHour >= 20 || state.currentHour < 6;
        return true;
    }
    return false;
}

// NeedsSystem -- reduced decay in wallpaper mode
const GRACE_PERIOD = 120;

export function needsTick(state) {
    // Machines run on their own, once per building per tick, whether or not anyone is nearby.
    // Upkeep: every building burns 1 materials per 10 ticks. Unpaid, it breaks (isActive=false)
    // until materials come back. Materials are the sink that keeps gathering worth doing.
    if (state.currentTick % 10 === 0) {
        for (const b of state.buildings) {
            if ((state.resources.materials || 0) >= 1) { state.resources.materials--; if (!b.isActive) { b.isActive = true; gameLog(state, `${BuildingType[b.type].name} repaired`); } }
            else if (b.isActive) { b.isActive = false; gameLog(state, `${BuildingType[b.type].name} broke down: no materials`); }
        }
    }
    for (const b of state.buildings) {
        if (!b.isActive) continue;
        if (b.type === 'generator') state.resources.power = (state.resources.power || 0) + 1;
        else if (b.type === 'billboard') state.resources.cash = (state.resources.cash || 0) + 1;
    }
    const inGrace = state.currentTick < GRACE_PERIOD; // no decay for the first GRACE_PERIOD ticks after spawn
    const wallpaperMult = state.wallpaperMode ? 0.3 : 1.0; // colonists survive longer in wallpaper

    for (let i = 0; i < state.colonists.length; i++) {
        const c = state.colonists[i];
        if (c.state === 'dead') continue;

        if (!inGrace) {
            // Trait/stat perks reduce or worsen specific need decay rates; a high
            // Endurance stat slows hunger loss, but the "insomniac"/"ironlung"/
            // "anxious" traits override the baseline for their own need regardless of stats.
            const endMult = 1.0 - c.stats.end * 0.05;
            const sleepMult = c.trait === 'insomniac' ? 0.7 : 1.0;
            const o2Mult = c.trait === 'ironlung' ? 0.7 : 1.0;
            const stressMult = c.trait === 'anxious' ? 2.0 : 1.0;

            c.hunger = Math.max(0, c.hunger - 0.0625 * endMult * wallpaperMult);
            c.oxygen = Math.max(0, c.oxygen - 0.025 * o2Mult * wallpaperMult);
            c.stress = Math.min(100, c.stress + 0.0375 * stressMult * wallpaperMult);
            c.sleep = Math.max(0, c.sleep - 0.0375 * sleepMult * wallpaperMult);
        }

        // Resting: an idle colonist recovers anywhere (faster near a shelter). Work drains, rest restores.
        // The food stockpile feeds the hungry on its own, so food is a production problem, not a babysitting one.
        if (c.job === 'idle' && c.pathIndex >= c.pathCols.length) {
            c.sleep = Math.min(100, c.sleep + 0.12);
            c.stress = Math.max(0, c.stress - 0.06);
            c.oxygen = Math.min(100, c.oxygen + 0.05);
        }
        if (c.hunger < 30 && (state.resources.food || 0) >= 3) {
            c.hunger = Math.min(100, c.hunger + 25);
            state.resources.food -= 3;
        }

        if (c.oxygen < 30 && (state.resources.oxygen || 0) >= 5) {
            c.oxygen = Math.min(100, c.oxygen + 20);
            state.resources.oxygen -= 5;
        }

        // CHA stress reduction from nearby colonists
        for (let j = 0; j < state.colonists.length; j++) {
            if (j === i || state.colonists[j].state === 'dead') continue;
            const dist = Math.abs(state.colonists[j].col - c.col) + Math.abs(state.colonists[j].row - c.row);
            if (dist <= 3) c.stress = Math.max(0, c.stress - c.stats.cha * 0.02);
        }

        // Building effects
        for (const b of state.buildings) {
            if (!b.isActive) continue;
            const dist = Math.abs(b.col - c.col) + Math.abs(b.row - c.row);
            if (dist > 3) continue;

            switch (b.type) {
                case 'shelter':
                    c.stress = Math.max(0, c.stress - 0.5);
                    c.sleep = Math.min(100, c.sleep + 0.4);
                    break;
                case 'foodStall':
                    if ((state.resources.food || 0) > 0 && c.hunger <= 98) {
                        c.hunger = Math.min(100, c.hunger + 2.0);
                        state.resources.food--;
                    }
                    break;
                case 'filterStation':
                    if ((state.resources.power || 0) > 0 && c.oxygen <= 98) {
                        c.oxygen = Math.min(100, c.oxygen + 1.0);
                        state.resources.power--;
                    }
                    break;
                // Quest buildings restore needs too
                case 'gym':
                    c.stress = Math.max(0, c.stress - 0.3);
                    c.health = Math.min(100, c.health + 0.1);
                    break;
                case 'library':
                    c.stress = Math.max(0, c.stress - 0.4);
                    c.sleep = Math.min(100, c.sleep + 0.2);
                    break;
                case 'workshop':
                    c.stress = Math.max(0, c.stress - 0.2);
                    break;
            }
        }

        updateColonistState(c);
        if (c.state === 'dead') gameLog(state, `${c.name} has died`);
    }
}

// ResourceSystem
export function resourceTick(state) {
    for (const rn of state.resourceNodes) {
        if (rn.remaining <= 0) {
            rn.ticksSinceDepleted++;
            if (rn.ticksSinceDepleted >= rn.respawnTicks) {
                rn.remaining = rn.maxAmount;
                rn.ticksSinceDepleted = 0;
            }
        }
    }

    for (const c of state.colonists) {
        if (c.job !== 'gather' || c.state === 'dead') continue;
        for (const rn of state.resourceNodes) {
            if (rn.remaining <= 0) continue;
            const dist = Math.abs(rn.col - c.col) + Math.abs(rn.row - c.row);
            if (dist <= 1) {
                const taken = Math.min(1, rn.remaining);
                rn.remaining -= taken;
                if (taken > 0) {
                    state.resources[rn.type] = (state.resources[rn.type] || 0) + taken;
                    if (state.currentTick % 5 === 0) grantXP(c, 1); // ponytail: tuned with web/sim.mjs so a steady player wins in ~1.5-2h
                }
                break;
            }
        }
    }
}

// BuildSystem
export function canPlace(type, col, row, grid, state) {
    const bt = BuildingType[type];
    const [w, h] = bt.size;
    for (let r = row; r < row + h; r++) {
        for (let c = col; c < col + w; c++) {
            const t = tileAt(grid, c, r);
            if (t === null || !isWalkable(t)) return false;
            // never wall a survivor in
            if (state.colonists.some(k => k.state !== 'dead' && k.col === c && k.row === r)) return false;
        }
    }
    for (const [res, amt] of Object.entries(bt.cost)) {
        if ((state.resources[res] || 0) < amt) return false;
    }
    return true;
}

function isWalkable(t) { return t === TileType.road || t === TileType.sidewalk || t === TileType.subway; }

export function placeBuilding(type, col, row, grid, state, pathfinder) {
    if (!canPlace(type, col, row, grid, state)) return null;
    const bt = BuildingType[type];
    for (const [res, amt] of Object.entries(bt.cost)) {
        state.resources[res] -= amt;
    }
    const [w, h] = bt.size;
    for (let r = row; r < row + h; r++) {
        for (let c = col; c < col + w; c++) {
            setTile(grid, c, r, TileType.building);
            pathfinder.removeNode(c, r);
        }
    }
    // Anyone routed through the new footprint re-plans; a stale path would walk them into the wall.
    for (const c of state.colonists) {
        for (let i = c.pathIndex; i < c.pathCols.length; i++) {
            const pc = c.pathCols[i], pr = c.pathRows[i];
            if (pc >= col && pc < col + w && pr >= row && pr < row + h) { c.pathCols = []; c.pathRows = []; c.pathIndex = 0; break; }
        }
    }
    const model = createBuilding(type, col, row);
    state.buildings.push(model);
    gameLog(state, `Built ${bt.name}`);
    return model;
}

export function demolishBuilding(id, grid, state, pathfinder) {
    const idx = state.buildings.findIndex(b => b.id === id);
    if (idx === -1) return;
    const b = state.buildings[idx];
    const bt = BuildingType[b.type];
    const [w, h] = bt.size;
    for (let r = b.row; r < b.row + h; r++) {
        for (let c = b.col; c < b.col + w; c++) {
            setTile(grid, c, r, TileType.sidewalk);
            pathfinder.addNode(c, r);
        }
    }
    state.buildings.splice(idx, 1);
    gameLog(state, `Demolished ${bt.name}`);
}

// JobSystem
export function jobTick(state, pathfinder) {
    for (let i = 0; i < state.colonists.length; i++) {
        const c = state.colonists[i];
        if (c.state === 'dead') continue;

        if (c.job === 'attack') {
            tickCombat(i, state, pathfinder);
        }

        if (c.pathIndex >= c.pathCols.length) {
            if (c.job === 'gather') {
                tickGather(c, state, pathfinder);
            } else if (c.job === 'patrol') {
                // On guard: stays put, earns a little XP, and keeps raiders off the stockpile (raidTick).
                if (state.currentTick % 20 === 0) awardXP(c, 1, 0, state);
            }
            continue;
        }

        const speed = Math.max(1, Math.floor(1.0 + c.stats.agi * 0.1));
        for (let s = 0; s < speed; s++) {
            if (c.pathIndex >= c.pathCols.length) break;
            c.col = c.pathCols[c.pathIndex];
            c.row = c.pathRows[c.pathIndex];
            c.pathIndex++;
        }
    }
}

// A `.gather` colonist with an exhausted path either just arrived at a node (stay put,
// resourceTick harvests this same frame) or has none assigned yet / their node depleted
// (find the nearest reachable one and walk there). Only goes idle when nothing is left.
function tickGather(c, state, pathfinder) {
    const alreadyAdjacent = state.resourceNodes.some(rn =>
        rn.remaining > 0 && Math.abs(rn.col - c.col) + Math.abs(rn.row - c.row) <= 1
    );
    if (alreadyAdjacent) return;

    const nodes = state.resourceNodes
        .filter(rn => rn.remaining > 0)
        .sort((a, b) =>
            (Math.abs(a.col - c.col) + Math.abs(a.row - c.row)) -
            (Math.abs(b.col - c.col) + Math.abs(b.row - c.row))
        );

    for (const rn of nodes) {
        const path = pathfinder.findPathNear(c.col, c.row, rn.col, rn.row);
        if (!path.length) continue;
        c.pathCols = path.map(p => p.col);
        c.pathRows = path.map(p => p.row);
        c.pathIndex = 0;
        return;
    }

    // Nothing reachable left to gather.
    awardXP(c, 10, 2, state);
    c.job = 'idle';
}

// Recruits: once a day, a survivor walks in if there is a free bed and food to feed them.
// Beds = 4 per shelter on top of a starting 8. Cap 20. No auto-assign: they arrive idle.
export const BEDS_PER_SHELTER = 4;
export const MAX_COLONISTS = 20;
export function recruitTick(state) {
    if (state.demoMode || state.currentTick === 0 || state.currentTick % TICKS_PER_DAY !== 0) return null;
    const alive = state.colonists.filter(c => c.state !== 'dead');
    if (!alive.length) return null;
    const beds = 8 + BEDS_PER_SHELTER * state.buildings.filter(b => b.type === 'shelter' && b.isActive).length;
    if (alive.length >= Math.min(beds, MAX_COLONISTS) || (state.resources.food || 0) < 10) return null;
    state.resources.food -= 10;
    const host = alive[0];
    const c = createColonist(randomColonistName(state.colonists), host.col, host.row);
    state.colonists.push(c);
    gameLog(state, `${c.name} arrives, looking for work`);
    return c;
}

// Raids: every third night scavengers hit the stockpile unless someone is on PATROL within
// RAID_GUARD_RANGE of the colony centre. The log warns at dawn of a raid day. Player-set, never automatic.
export const RAID_EVERY_DAYS = 3, RAID_HOUR = 22, RAID_GUARD_RANGE = 8, RAID_TAKE = 0.2;
export function raidTick(state) {
    if (state.demoMode) return null;
    const day = Math.floor(state.currentTick / TICKS_PER_DAY), hourTick = state.currentTick % TICKS_PER_DAY;
    const raidDay = day > 0 && day % RAID_EVERY_DAYS === 0;
    if (!raidDay) return null;
    if (hourTick === 60) { gameLog(state, 'Scavengers spotted nearby. Put someone on PATROL before 22:00.'); return null; }
    if (hourTick !== RAID_HOUR * 10) return null;
    const alive = state.colonists.filter(c => c.state !== 'dead');
    if (!alive.length) return null;
    // The stockpile lives in the buildings: a patrol near any building guards it. No buildings yet, any patrol will do.
    const guarded = alive.some(c => c.job === 'patrol' && (!state.buildings.length ||
        state.buildings.some(b => Math.abs(c.col - b.col) + Math.abs(c.row - b.row) <= RAID_GUARD_RANGE)));
    if (guarded) { gameLog(state, 'Scavengers turned back by the patrol.'); return { guarded: true }; }
    const lost = {};
    for (const k of ['food', 'materials', 'cash']) { lost[k] = Math.floor((state.resources[k] || 0) * RAID_TAKE); state.resources[k] -= lost[k]; }
    gameLog(state, `Scavengers raided the stockpile: -${lost.food} food, -${lost.materials} materials, -${lost.cash} cash.`);
    return { guarded: false, lost };
}

// QuestSystem -- colonists perform real-life quests
export const QUEST_WORK_TICKS = 30;

function awardXP(c, xpAmount, playerXPAmount, state) {
    const leveled = grantXP(c, xpAmount);
    state.playerXP += playerXPAmount;
    if (leveled) {
        spawnLevelUp(c.col, c.row, c.level);
        gameLog(state, `${c.name} reached level ${c.level}`);
    }
}

const questBubbles = {
    fitness: ['Hitting the gym', 'Lifting weights', 'Running laps', 'Working out', 'Getting strong'],
    study: ['Reading books', 'Taking notes', 'Studying hard', 'At the library', 'Deep focus'],
    work: ['Coding away', 'In the zone', 'Building apps', 'Shipping code', 'Deploying'],
    personal: ['Self-care time', 'Getting organized', 'Journaling', 'Meditating', 'Reflecting'],
    creative: ['Making art', 'Writing music', 'Designing', 'Creating', 'Brainstorming'],
    errand: ['Running errands', 'Getting supplies', 'Out and about', 'On a mission', 'Shopping'],
};

export function questTick(state, grid, pathfinder) {
    const quests = activeQuests(state);

    const questBuildings = state.buildings.filter(b =>
        ['questBoard', 'gym', 'library', 'workshop'].includes(b.type) && b.isActive
    );

    for (const c of state.colonists) {
        if (c.state === 'dead') continue;

        // Convert pending quest to active when colonist arrives at building
        if (c._questPending && c.pathIndex >= c.pathCols.length) {
            const nearBuilding = questBuildings.some(b =>
                Math.abs(c.col - b.col) + Math.abs(c.row - b.row) <= 3
            );
            if (nearBuilding) {
                c.activeQuest = { ...c._questPending, ticksRemaining: QUEST_WORK_TICKS };
                c._questPending = null;
                const bubbles = questBubbles[c.activeQuest.category] || questBubbles.personal;
                c.questBubble = { text: bubbles[Math.floor(Math.random() * bubbles.length)], ticks: 40 };
            } else {
                // Path ended but not near building -- reset
                c._questPending = null;
                c.job = 'idle';
            }
        }

        // Already on a quest -- tick it down (only when actually working at building)
        if (c.activeQuest) {
            c.activeQuest.ticksRemaining--;
            if (c.activeQuest.ticksRemaining <= 0) {
                const xp = DifficultyXP[c.activeQuest.difficulty] || 50;
                const prevLevel = c.level;
                grantXP(c, xp);
                spawnXP(c.col, c.row, xp);
                if (c.level > prevLevel) spawnLevelUp(c.col, c.row, c.level);
                spawnQuestComplete(c.col, c.row);
                c.questsCompleted = (c.questsCompleted || 0) + 1;
                if (!c._catCounts) c._catCounts = {};
                const cat = c.activeQuest.category;
                c._catCounts[cat] = (c._catCounts[cat] || 0) + 1;
                const topCat = Object.entries(c._catCounts).sort((a,b) => b[1]-a[1])[0];
                if (topCat) c.dominantCategory = topCat[0];
                const info = CategoryInfo[cat];
                if (info && c.questsCompleted % 5 === 0) {
                    for (const stat of info.statBoost) {
                        c.stats[stat] = Math.min(10, c.stats[stat] + 1);
                    }
                    gameLog(state, `${c.name} grew stronger from ${info.label} training`);
                }
                c.questBubble = { text: `Done: ${c.activeQuest.title}`, ticks: 40 };
                gameLog(state, `${c.name} completed: ${c.activeQuest.title}`);
                state.questLog.push({ colonist: c.name, quest: c.activeQuest.title, tick: state.currentTick });
                state.playerXP += xp;
                c.activeQuest = null;
                c.job = 'idle';
            }
            continue;
        }

        // Skip if already traveling to quest or busy
        if (c._questPending) continue;
        if (c.job !== 'idle' || c.jobOverride) continue;
        if (!quests.length || !questBuildings.length) continue;

        // Pick a quest
        const quest = quests[Math.floor(Math.random() * quests.length)];
        const targetType = QuestBuildings[quest.category] || 'questBoard';
        const target = questBuildings.find(b => b.type === targetType) || questBuildings[0];

        const dist = Math.abs(c.col - target.col) + Math.abs(c.row - target.row);
        if (dist <= 3) {
            // Already at building -- start immediately
            c.job = 'quest';
            c.activeQuest = { ...quest, ticksRemaining: QUEST_WORK_TICKS };
            const bubbles = questBubbles[quest.category] || questBubbles.personal;
            c.questBubble = { text: bubbles[Math.floor(Math.random() * bubbles.length)], ticks: 40 };
        } else {
            // Find walkable tile adjacent to building (building tiles are removed from pathfinder)
            const bt = BuildingType[target.type];
            const [bw, bh] = bt ? bt.size : [2, 2];
            let destCol = -1, destRow = -1, bestDist = Infinity;
            for (let dr = -1; dr <= bh; dr++) {
                for (let dc = -1; dc <= bw; dc++) {
                    if (dr >= 0 && dr < bh && dc >= 0 && dc < bw) continue; // skip building tiles
                    const tc = target.col + dc;
                    const tr = target.row + dr;
                    if (tc < 0 || tr < 0 || tc >= GRID_SIZE || tr >= GRID_SIZE) continue;
                    const t = tileAt(grid, tc, tr);
                    if (t === null || t === TileType.building) continue;
                    const d = Math.abs(c.col - tc) + Math.abs(c.row - tr);
                    if (d < bestDist) { destCol = tc; destRow = tr; bestDist = d; }
                }
            }
            if (destCol < 0) continue; // no walkable neighbor

            const path = pathfinder.findPath(c.col, c.row, destCol, destRow);
            if (path.length) {
                c.job = 'quest';
                c.pathCols = path.map(p => p.col);
                c.pathRows = path.map(p => p.row);
                c.pathIndex = 0;
                c._questPending = { ...quest };
                c.questBubble = { text: quest.title, ticks: 30 };
            }
        }
    }

    // Tick down speech bubbles and toast
    for (const c of state.colonists) {
        if (c.questBubble) {
            c.questBubble.ticks--;
            if (c.questBubble.ticks <= 0) c.questBubble = null;
        }
    }
    if (state.toastMessage) {
        state.toastMessage.ticks--;
        if (state.toastMessage.ticks <= 0) state.toastMessage = null;
    }
}

// Wallpaper auto-camera -- slow drift
let cameraDriftAngle = 0;
export function wallpaperCameraTick(camera, state) {
    if (!state.wallpaperMode && !state.demoMode) return;
    cameraDriftAngle += 0.002;
    const alive = state.colonists.filter(c => c.state !== 'dead');
    if (!alive.length) return;
    // Follow a random alive colonist, slowly
    const target = alive[Math.floor(state.currentTick / 120) % alive.length];
    const targetX = target.col * 32 + 16;
    const targetY = target.row * 32 + 16;
    camera.x += (targetX - camera.x) * 0.02;
    camera.y += (targetY - camera.y) * 0.02;
}

function tickCombat(i, state, pathfinder) {
    const attacker = state.colonists[i];
    if (!attacker.attackTargetId) { attacker.job = 'idle'; return; }
    const targetIdx = state.colonists.findIndex(c => c.id === attacker.attackTargetId);
    if (targetIdx === -1) { attacker.job = 'idle'; attacker.attackTargetId = null; return; }

    const target = state.colonists[targetIdx];
    if (target.state === 'dead') {
        attacker.job = 'idle';
        attacker.attackTargetId = null;
        awardXP(attacker, 30, 10, state);
        gameLog(state, `${attacker.name} killed ${target.name}`);
        return;
    }

    const dist = Math.abs(attacker.col - target.col) + Math.abs(attacker.row - target.row);
    const weapon = WeaponTypes[attacker.weapon];

    if (dist <= weapon.range) {
        const dmg = weapon.damage * (1.0 + attacker.stats.str * 0.1);
        takeDamage(target, dmg);
        spawnDamage(target.col, target.row, dmg);
        awardXP(attacker, 5, 1, state);
    } else if (attacker.pathIndex >= attacker.pathCols.length) {
        const path = pathfinder.findPath(attacker.col, attacker.row, target.col, target.row);
        if (path.length) {
            attacker.pathCols = path.map(p => p.col);
            attacker.pathRows = path.map(p => p.row);
            attacker.pathIndex = 0;
        }
    }
}


// DemoSystem -- menu attract mode ONLY. Never runs in a real game: every call site
// and this guard require state.demoMode, which is set only for the throwaway menu
// background state. Player-controlled games stay player-controlled (see jobTick).
export function demoTick(state, grid, pathfinder) {
    if (!state.demoMode) return;

    for (const c of state.colonists) {
        if (c.state === 'dead' || c.job !== 'idle') continue;
        if (Math.random() > 0.05) continue;
        const nodes = state.resourceNodes.filter(n => n.remaining > 0);
        if (!nodes.length) continue;
        const n = nodes[Math.floor(Math.random() * nodes.length)];
        const path = pathfinder.findPath(c.col, c.row, n.col, n.row);
        if (!path.length) continue;
        c.job = 'gather';
        c.pathCols = path.map(p => p.col);
        c.pathRows = path.map(p => p.row);
        c.pathIndex = 0;
    }

    if (state.currentTick % 40 !== 0) return;
    const types = Object.keys(BuildingType);
    const type = types[Math.floor(Math.random() * types.length)];
    const alive = state.colonists.filter(c => c.state !== 'dead');
    if (!alive.length) return;
    const near = alive[Math.floor(Math.random() * alive.length)];
    for (let i = 0; i < 12; i++) {
        const col = near.col + Math.floor(Math.random() * 11) - 5;
        const row = near.row + Math.floor(Math.random() * 11) - 5;
        if (placeBuilding(type, col, row, grid, state, pathfinder)) return;
    }
}
