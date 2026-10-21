# Architecture

A survival colony builder where players place buildings, manage colonists, and balance five resources (food, power, materials, oxygen, cash) on a 128x128 grid. The core game loop runs on SpriteKit (macOS and iOS), with optional watchOS quick-reference and terminal versions for reference.

## How it runs

**macOS**: `Sources/App/NYCSurviveApp.swift` is the entry point. SwiftUI window hosts an `SKView` embedding `GameScene` for rendering and physics. User input (keyboard/mouse on macOS, touch on iOS) goes through `InputHandler`, which emits commands to `GameState`. Each frame, `GameScene` ticks all systems (BuildSystem, JobSystem, NeedsSystem, ResourceSystem, TimeSystem) in order. HUD overlays (built menu, colonist stats, resource bar) are SwiftUI Views layered on top.

**iOS**: `Sources/AppiOS/NYCSurviveApp.swift` is the entry point. Touch gestures (tap to select, pan to move camera, pinch to zoom) are captured by `InputHandler` and routed to the same `GameScene`. The game runs identically to macOS.

**Saving**: three save slots stored as JSON via `SaveManager`. Game state serializes to `SaveData` containing all colonists, buildings, resources, and grid state.

## macOS

| File | What it owns |
|---|---|
| `Sources/App/NYCSurviveApp.swift` | App entry point, scene setup, `SKView` hosting, macOS-specific key/mouse input setup |

## iOS

| File | What it owns |
|---|---|
| `Sources/AppiOS/NYCSurviveApp.swift` | App entry point, scene setup, `UIView` hosting, iOS-specific touch/gesture input setup |

## Game logic

| File | What it owns |
|---|---|
| `Sources/Models/GameState.swift` | @Observable central state: resources, colonists, buildings, resource nodes, selected IDs, pause flag, tutorial step, save slots, game log |
| `Sources/Game/Scenes/GameScene.swift` | Main game loop, 60 FPS tick, wires all systems, renders tile map and entities, updates camera, handles selection UI (rects, highlights), calls `performSave` on demand |
| `Sources/Game/Scenes/MenuScene.swift` | Title screen, load-game UI, new-game button, handles save-slot selection |
| `Sources/Game/Input/InputHandler.swift` | Platform-agnostic event capture (key down/up, mouse/touch down, scroll, pan, pinch), emits callbacks (onPlaceBuilding, onDemolish, onSelectEntity, onSave) |
| `Sources/Game/Camera/CameraController.swift` | SpriteKit camera node, pan direction, zoom level (0.5-3.0x), pan speed limits, center-on-entity |

## Game systems

| File | What it owns |
|---|---|
| `Sources/Game/Systems/BuildSystem.swift` | Building placement validation (grid bounds, non-walkable tiles), ghost node preview (shows where a building will land before placement), demolish (frees resources and tiles), tracks placed buildings |
| `Sources/Game/Systems/JobSystem.swift` | Colonist job assignment (idle, gather, build, patrol, attack), command-move path planning, job XP tracking, death on job failure, job-specific ticks (gather resource nodes, build buildings, combat with threats) |
| `Sources/Game/Systems/NeedsSystem.swift` | Hunger/thirst/oxygen depletion over time (with 120-tick grace period at game start), colonist death when a need reaches zero, end-game check |
| `Sources/Game/Systems/ResourceSystem.swift` | Resource node respawn tracking, resource consumption (via JobSystem gather ticks), starvation checks |
| `Sources/Game/Systems/TimeSystem.swift` | Tick counter, converts ticks to hours/days (240 ticks per day), pause flag, day/night cycle flag (every 120 ticks is night) |
| `Sources/Game/Systems/Pathfinder.swift` | GameplayKit graph pathfinding over the tile grid, builds/removes/adds nodes, finds shortest paths for colonist movement |

## Game world

| File | What it owns |
|---|---|
| `Sources/Game/World/TileMap.swift` | 128x128 grid of `TileType` (road, sidewalk, building, empty, etc.), tile size (32px), world position lookups, tile rendering |
| `Sources/Game/World/TileType.swift` | Enum of tile types with walkability, rendering asset names, raw string names |
| `Sources/Game/World/WorldGenerator.swift` | Procedural grid generation: Manhattan-style avenues/streets (16 and 12-tile spacing), sidewalk strips, empty grass, seed resource nodes (food/power/materials/oxygen/cash) |

## Game entities

| File | What it owns |
|---|---|
| `Sources/Game/Entities/Building.swift` | Sprite node for placed buildings, building ID and type, place animation |
| `Sources/Game/Entities/Colonist.swift` | Sprite node for colonists, health bar, selection indicator, movement animation (velocity-based), death animation |
| `Sources/Game/Entities/Resource.swift` | Sprite node for resource nodes, respawn timer, resource type |

## Models and data

| File | What it owns |
|---|---|
| `Sources/Models/BuildingModel.swift` | Building type enum (shelter, foodStall, generator, etc.), display names, costs, tile sizes, building ID and model |
| `Sources/Models/ColonistModel.swift` | Colonist job enum (idle, gather, build, patrol, attack), weapon enum (fists through rifle), stats (health, energy, hunger, etc.), XP per job, name generation, traits |
| `Sources/Models/ResourceModel.swift` | Resource type enum (food, power, materials, oxygen, cash), symbols, resource node model with ID and respawn state |
| `Sources/Models/SaveManager.swift` | JSON serialization for save/load, three save slots, SaveSlot metadata (name, timestamp, day count, colonist count), SaveData structure (colonists, buildings, resources, grid state) |

## HUD (SwiftUI)

| File | What it owns |
|---|---|
| `Sources/HUD/HUDView.swift` | Top-level HUD layout: resource bar, build menu (conditional), colonist panel (conditional), minimap stub, tutorial overlay |
| `Sources/HUD/ResourceBar.swift` | Five resource pills (food, power, materials, oxygen, cash) showing current/max counts, compact layout on iOS (no words, icons only) |
| `Sources/HUD/BuildMenu.swift` | Building type grid with costs, enabled/disabled based on resources, building name and icon |
| `Sources/HUD/ColonistPanel.swift` | Selected colonist name, level, job, health/hunger/energy/oxygen bars, job XP, status pills (state color coding), job assignment buttons |
| `Sources/HUD/SettingsView.swift` | Audio toggle, theme picker (light/dark/auto), pause button, save slot selector |
| `Sources/HUD/TutorialView.swift` | Structured tutorial steps (0-7), hints and objectives, skip button, auto-advance on player actions |
| `Sources/HUD/MiniMap.swift` | Stub placeholder for future minimap (currently just a label) |
| `Sources/HUD/Theme.swift` | Color palette (yellow, red, green, cyan, light/dark), adapts to system theme or player choice, visual constants (spacing, corner radius, material styles), resource metadata (colors and symbols) |
| `Sources/HUD/View+Glass.swift` | Liquid Glass morphism modifier for iOS 18+ (fallback to thinMaterial on older OS) for floating controls |

## Sprite generation

| File | What it owns |
|---|---|
| `scripts/generate_sprites.py` | Python script to generate all Fez-style pixel art sprites at build time: colonists (walk cycle, dead), buildings (5 types), resources (5 types), outputs to `Resources/Assets.xcassets` |

## Platforms (non-game)

| File | What it owns |
|---|---|
| `watchos/NYCSurviveWatchApp.swift` + `watchos/ContentView.swift` | watchOS app entry, quick-reference tabs (buildings, traits, weapons stats), NOT a live save mirror, no pairing |
| `tui/main.swift` | Terminal UI reference card using SwiftTUI, quick-reference building costs and stats, NOT a live game |

## Audio

| File | What it owns |
|---|---|
| `Sources/Audio/AudioManager.swift` | Sound effects (building placed, combat hit, colonist death), AVAudioEngine, toggleable via UserDefaults |

## Testing

| File | What it owns |
|---|---|
| `Tests/SimTests.swift` | Unit tests for world generation, pathfinding, needs decay, death, build validation, resource consumption, job assignment, colonist movement |

## Landing / web

| File | What it owns |
|---|---|
| `landing/index.html` | Hero, game description, App Store links, screenshots, device frame CSS |
| `landing/devices.css` | Realistic device frames (iPhone, iPad, Mac) for rendering game screenshots in responsive layout |
| `scripts/build-site.sh` | Compose final site: landing at `/`, web app at `/app/` |

## Gotchas

**Save system**: three slots only, JSON serialization, no auto-save on every tick (too slow). Save is manual (Cmd+S or Settings).

**Pathfinding**: uses GameplayKit grid graph, rebuilds on world load, must stay in sync with TileMap walkability.

**No autoplay**: removed 2026-08-02. Colonists only act on player commands (select + tap destination or job pill). Do not reintroduce automatic assignment.

**Platform sync**: macOS and iOS run identical game loop, but input handling and view setup differ (SKView vs UIView). Ensure both update `GameScene` identically.

**Needs decay**: 120-tick grace period at game start, then each colonist loses hunger/oxygen/energy per tick. If any need reaches zero before replenished, colonist dies.

**Tutorial**: conditional on first launch, can be skipped. Uses `gameState.tutorialStep` to track progress (nil = done/skipped).

**WebGL reference**: `web/js/` is stale, not maintained. Game logic is the SpriteKit version only.
