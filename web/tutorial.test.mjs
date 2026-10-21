// Regression check: a new game must actually show the tutorial.
// (68e72d5 nulled tutorialStep in freshWorld() as autoplay-removal collateral,
//  which silently killed the tutorial for every new game.)
import assert from 'node:assert';

// ponytail: minimal DOM stub so theme.js can be imported outside a browser
globalThis.window = { matchMedia: () => ({ matches: false, addEventListener() {} }) };
globalThis.document = { documentElement: { setAttribute() {} } };
globalThis.localStorage = { getItem: () => null, setItem() {} };

const { createGameState } = await import('./js/state.js');
const { checkTutorialAdvance } = await import('./js/hud.js');
const mainSrc = await import('node:fs').then(fs => fs.readFileSync(new URL('./js/main.js', import.meta.url), 'utf8'));

assert.strictEqual(createGameState().tutorialStep, 0, 'new game must start at tutorial step 0');
assert.ok(!/freshWorld[\s\S]*?tutorialStep = null/.test(mainSrc), 'freshWorld() must not clear the tutorial');

const s = createGameState();
s.tutorialStep = 2;
checkTutorialAdvance(s, 'colonistSelected'); assert.strictEqual(s.tutorialStep, 3);
checkTutorialAdvance(s, 'wasdPressed');      assert.strictEqual(s.tutorialStep, 4);
checkTutorialAdvance(s, 'buildMenuOpened');  assert.strictEqual(s.tutorialStep, 5);
checkTutorialAdvance(s, 'shelterPlaced');    assert.strictEqual(s.tutorialStep, 6);

s.tutorialStep = null;
checkTutorialAdvance(s, 'colonistSelected'); assert.strictEqual(s.tutorialStep, null, 'dismissed tutorial stays dismissed');

console.log('ok: tutorial starts on new game and advances');
