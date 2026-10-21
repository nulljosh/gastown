// WebMCP tool registration -- exposes the game to browser-side AI agents via
// window.modelContext (see https://github.com/webmachinelearning/webmcp).
// Every tool below wraps an existing function; no game logic lives here.
//
// ponytail: no manual mcGetState-in-tool tricks -- main.js already owns the
// module-scoped `state`, so we just import thin accessor exports from it
// instead of duplicating state tracking in this file.

import { mcpGetState, mcpStartGame, mcpLoadSave, mcpSaveGame } from './main.js';
import { listSlots, deleteSlot } from './save.js';

// Registered on DOMContentLoaded, added after main.js's own listener (module
// scripts run in document order), so the menu/canvas are already initialised
// by the time tools go live.
document.addEventListener('DOMContentLoaded', () => {
    const mc = document.modelContext;
    if (!mc?.registerTool) return;

    const tools = [
        // -- read-only --
        {
            name: 'get_game_state',
            description: 'Get the current city state: resources, tick/hour, pause state, colonist counts, building count, and quest progress. Returns null if no game is currently loaded (still on the menu).',
            inputSchema: { type: 'object', properties: {} },
            execute: async () => mcpGetState(),
        },
        {
            name: 'list_saves',
            description: 'List the 3 local save slots with day count and living colonist count for each. Empty slots are returned as null.',
            inputSchema: { type: 'object', properties: {} },
            execute: async () => listSlots(),
        },
        // -- reversible writes --
        {
            name: 'start_game',
            description: 'Start a brand new game, discarding any unsaved progress in the current session. Does not touch existing save slots.',
            inputSchema: {
                type: 'object',
                properties: {
                    difficulty: { type: 'string', enum: ['easy', 'medium', 'hard'], description: 'Starting resource multiplier and difficulty curve. Defaults to the menu selection if omitted.' },
                },
            },
            execute: async (args) => { mcpStartGame(args?.difficulty); return mcpGetState(); },
        },
        {
            name: 'load_save',
            description: 'Load a game from one of the 3 save slots, replacing the current session.',
            inputSchema: {
                type: 'object',
                properties: {
                    slot: { type: 'number', description: 'Save slot number, 1 through 3.' },
                },
                required: ['slot'],
            },
            execute: async (args) => { mcpLoadSave(args.slot); return mcpGetState(); },
        },
        {
            name: 'save_game',
            description: 'Save the current game to a slot (defaults to the last-used slot if none is given).',
            inputSchema: {
                type: 'object',
                properties: {
                    slot: { type: 'number', description: 'Save slot number, 1 through 3. Omit to save to the last-used slot.' },
                },
            },
            execute: async (args) => { mcpSaveGame(args?.slot); return mcpGetState(); },
        },
        // -- requires human confirmation --
        {
            name: 'delete_save',
            description: 'Permanently delete a save slot. This cannot be undone.',
            inputSchema: {
                type: 'object',
                properties: {
                    slot: { type: 'number', description: 'Save slot number, 1 through 3, to delete.' },
                },
                required: ['slot'],
            },
            requiresConfirmation: true,
            execute: async (args) => { deleteSlot(args.slot); return listSlots(); },
        },
    ];

    for (const tool of tools) {
        try {
            mc.registerTool(tool);
        } catch (e) {
            console.warn(`webmcp: failed to register tool "${tool.name}"`, e);
        }
    }
});
