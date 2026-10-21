# NYC Survive loop handoff (2026-10-21, late morning)

## What the loop is

A QA and polish cycle on the Mac build, the web port and the landing. The headless bot (`scripts/playthrough.sh`, bot in `scripts/playthrough/`, never in the app) is the win check. It exits 0 on victory.

## Where things stand

iOS 1.1.0 is live. Check macOS with `asc` before relying on it.

The game can be won. Native had ported the wrong XP curve (level N cost N*100), so the bot averaged level 5.2 after 200 days. With the web curve and 1 XP per harvest, the headless bot wins 3 of 3 worlds on days 21 to 23, about 1.5 hours at normal speed. A recorded run won on day 24 and was sent to Joshua.

Today's Mac QA also fixed these:
- the 7.7 second New Game freeze, now 0.05 seconds with a bitmap and BFS pathfinder
- map clicks lost to hand jitter
- the tutorial
- the HUD contrast
- the empty minimap

The menu now sits over a live city with hover buttons, NYC Sans and the new Empire State icon. The Dock name is "NYC Survive", the window resizes, and Settings has a Full screen switch. LICENSE is already Apache 2.0.

The landing is being rebuilt on the Hermes system and is not deployed.

## Next, in order

1. Settings QA after a game. The Full screen switch goes stale if the green window button is used. Check save slots, sound and appearance. The first click into an inactive window only focuses it.
2. Design system: Theme.accent is still #0071e3 next to brand blue #3d7bff, and the HUD mixes yellow, cyan and red. Record the NYC Sans override in brand/BRAND.md the way Coda does.
3. Landing: finish the Hermes-style rebuild. Run `scripts/build-site.sh`, deploy, and check nyc.jaybulb.com live.
4. Move nyc out of labs into its own public repo, nulljosh/nyc, the way curvely left on 2026-10-21. That means a clean root commit, CI moved into the repo, and the folder ignored in labs.

## Restart prompt

```
/loop NYC Survive. Work nyc/docs/LOOP-HANDOFF.md "Next, in order" top to bottom. scripts/playthrough.sh must keep winning after any rule change (same rules on web and native). Commit by exact path with git commit -o, never git add -A. Send screenshots of every visible change.
```
