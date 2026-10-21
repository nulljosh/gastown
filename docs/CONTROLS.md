# Controls

How to play NYC Survive on iPhone, iPad and Mac. These match the input code in
`Sources/Game/Input/InputHandler.swift` and the Controls list in Settings.

## Touch (iPhone and iPad)

| Gesture | Action |
|---------|--------|
| Drag | Pan the camera |
| Pinch | Zoom in and out |
| Tap | Select a colonist or building, or place the building you picked |
| Tap a colonist, then tap a tile | Move the selected colonist there |

## Keyboard and mouse (Mac)

| Input | Action |
|-------|--------|
| W A S D or arrow keys | Pan the camera (hold to keep moving) |
| Scroll wheel | Zoom in and out |
| Click | Select, place, or demolish, depending on the current mode |
| Click a colonist, then click the ground | Move that colonist |
| Click a colonist, then click a resource | Send that colonist to gather it |
| Drag over empty ground | Box-select several colonists (a drag under 6 pt is a click) |
| Settings, then Full screen | Full screen on or off. The window also resizes |
| B | Open or close the build menu |
| 1 to 6 | Pick a building to place (1 shelter, 2 food stall, 3 generator, 4 filter station, 5 subway access, 6 billboard) |
| X | Toggle demolish mode, then click a building to remove it |
| Space | Pause or resume |
| Cmd+S | Save |
| Esc | Clear the selection, or leave build or demolish mode, or open Settings |

Esc works in steps. If a colonist is selected, the first Esc deselects them. If you
are in build or demolish mode, the next Esc returns to normal. Otherwise Esc opens
Settings and pauses the game.

## Mode notes

- Build mode: after you pick a building, each tap places one. Press B or Esc to stop.
- Demolish mode: press X, then click or tap a building to remove it. Press X again to stop.
- Colonists only move or gather when you tell them to. Select one, then tap where it should go.
