# API

NYC Survive has no HTTP API. It's a client-only browser game built from plain ES
modules with no server and no bundler — all game state lives in memory in the
page, and saves are written straight to the browser's `localStorage` (keys
`nyc_save_1` / `nyc_save_2` / `nyc_save_3`, one per save slot) by `web/js/save.js`.

## WebMCP

The web app (`web/index.html`) registers tools via [WebMCP](https://github.com/webmachinelearning/webmcp)
(`window.modelContext`) so a browser-based AI agent can inspect and drive the
game. Registration happens in `web/js/webmcp.js`, wired in with its own
`<script type="module">` tag after `main.js`. If the browser has no
`window.modelContext`, the script no-ops.

### Read-only

| tool | what it does |
|------|---------------|
| `get_game_state` | Returns the current city state: resources, tick/hour, pause state, game phase, colonist counts, building count, and quest/XP progress. Returns `null` if no game is loaded yet (still on the menu). |
| `list_saves` | Lists the 3 local save slots with day count and living colonist count for each. Empty slots are `null`. |

### Reversible writes

| tool | what it does |
|------|---------------|
| `start_game` | Starts a brand new game (optional `difficulty`: `easy`/`medium`/`hard`), discarding unsaved progress in the current session. Does not touch existing save slots. |
| `load_save` | Loads a game from a save slot (1-3), replacing the current session. |
| `save_game` | Saves the current game to a slot (defaults to the last-used slot). |

### Requires human confirmation

| tool | what it does |
|------|---------------|
| `delete_save` | Permanently deletes a save slot (`deleteSlot` in `web/js/save.js`). Gated with `requiresConfirmation: true` since it can't be undone. |
