// Theme resolution: explicit player choice wins, otherwise follow the system.
// CSS reads data-theme; the canvas can't, so world + renderer get told directly.

import { setTilePalette } from './world.js';
import { setRenderTheme } from './renderer.js';

const KEY = 'nyc-theme';
const darkQuery = window.matchMedia('(prefers-color-scheme: dark)');

function stored() {
    try { return localStorage.getItem(KEY); } catch { return null; }
}

// 'light' | 'dark' — what should actually be painted right now.
export function resolvedTheme() {
    const choice = stored();
    if (choice === 'light' || choice === 'dark') return choice;
    return darkQuery.matches ? 'dark' : 'light';
}

function paint(theme) {
    document.documentElement.dataset.theme = theme;
    setTilePalette(theme);
    setRenderTheme(theme);
}

export function applyTheme() {
    paint(resolvedTheme());
}

export function toggleTheme() {
    const next = resolvedTheme() === 'dark' ? 'light' : 'dark';
    try { localStorage.setItem(KEY, next); } catch { /* private mode: session-only */ }
    paint(next);
    return next;
}

export function initTheme() {
    applyTheme();
    // Only follow the system while the player hasn't made an explicit choice.
    darkQuery.addEventListener('change', () => { if (!stored()) applyTheme(); });
}
