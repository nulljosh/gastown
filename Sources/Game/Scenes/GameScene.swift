import SpriteKit
import GameplayKit

@MainActor
final class GameScene: SKScene {
    let gameState: GameState
    private var tileMap: TileMap!
    private var timeSystem = TimeSystem()
    private var needsSystem = NeedsSystem()
    private var resourceSystem = ResourceSystem()
    private var buildSystem = BuildSystem()
    var jobSystem = JobSystem()
    var pathfinder: Pathfinder!
    private var inputHandler = InputHandler()
    var cameraController = CameraController()

    private var colonistNodes: [UUID: ColonistNode] = [:]
    private var buildingNodes: [UUID: BuildingNode] = [:]
    private var resourceNodes: [UUID: ResourceNode] = [:]

    private var lastUpdateTime: TimeInterval = 0
    var backdrop = MenuBackdropClock()

    // Drag selection
    private var selectionStart: CGPoint?
    private var selectionRect: SKShapeNode?
    private var dragMoved = false
    private var nightOverlay = SKSpriteNode()

    // Tutorial highlight nodes
    private var tutorialHighlights: [SKNode] = []

    // For loading from save
    var savedData: SaveData?

    /// Which theme the scene's colours were last painted for; see `update(_:)`.
    private var paintedDark = Theme.isDark

    init(gameState: GameState) {
        self.gameState = gameState
        super.init(size: CGSize(width: 4096, height: 4096))
        self.scaleMode = .resizeFill
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        backgroundColor = ScenePalette.background

        let grid: [[TileType]]
        if let save = savedData {
            grid = SaveManager.shared.rebuildGrid(from: save)
            gameState.colonists = save.colonists
            gameState.buildings = save.buildings
            gameState.resourceNodes = save.resourceNodes
            gameState.resources = save.resources
            gameState.currentTick = save.currentTick
            gameState.currentHour = (save.currentTick % NeedsSystem.ticksPerDay) / 10
        } else {
            let result = WorldGenerator.generate()
            grid = result.grid
            gameState.resourceNodes = result.resources
        }

        tileMap = TileMap(grid: grid)
        addChild(tileMap.node)

        pathfinder = Pathfinder(columns: WorldGenerator.gridSize, rows: WorldGenerator.gridSize)
        pathfinder.buildGraph(grid: grid)
        jobSystem.pathfinder = pathfinder

        for model in gameState.resourceNodes {
            let node = ResourceNode(model: model, tileSize: TileMap.tileSize)
            node.position = tileMap.worldPosition(col: model.col, row: model.row)
            addChild(node)
            resourceNodes[model.id] = node
        }

        if savedData != nil {
            // Rebuild building nodes from loaded state
            for model in gameState.buildings {
                let node = BuildingNode(model: model, tileSize: TileMap.tileSize)
                node.position = CGPoint(x: CGFloat(model.col) * TileMap.tileSize, y: CGFloat(model.row) * TileMap.tileSize)
                addChild(node)
                buildingNodes[model.id] = node
            }
            // Rebuild colonist nodes from loaded state
            for model in gameState.colonists {
                let node = ColonistNode(id: model.id)
                node.position = tileMap.worldPosition(col: model.col, row: model.row)
                addChild(node)
                colonistNodes[model.id] = node
            }
        } else {
            // Fresh game: spawn colonists
            let names = ["Alex", "Jordan", "Casey", "Riley", "Morgan"]
            let center = WorldGenerator.gridSize / 2
            for i in 0..<5 {
                var walkableCol = center + i
                var walkableRow = center
                var found = false
                for dc in 0..<10 where !found {
                    for dr in 0..<10 where !found {
                        let c = center + dc + i
                        let r = center + dr
                        if let tile = tileMap.tileAt(col: c, row: r), tile.isWalkable {
                            walkableCol = c
                            walkableRow = r
                            found = true
                        }
                    }
                }
                let model = ColonistModel(id: UUID(), name: names[i], col: walkableCol, row: walkableRow)
                gameState.colonists.append(model)

                let node = ColonistNode(id: model.id)
                node.position = tileMap.worldPosition(col: model.col, row: model.row)
                addChild(node)
                colonistNodes[model.id] = node
            }

        }

        let center = WorldGenerator.gridSize / 2
        camera = cameraController.cameraNode
        addChild(cameraController.cameraNode)
        // Night tint rides on the camera so it covers the view at any pan or zoom (scaled up in update).
        nightOverlay = SKSpriteNode(color: SKColor(red: 0.04, green: 0.06, blue: 0.19, alpha: 1), size: CGSize(width: 8192, height: 8192))
        nightOverlay.zPosition = 90
        nightOverlay.alpha = 0
        cameraController.cameraNode.addChild(nightOverlay)
        cameraController.centerOn(position: tileMap.worldPosition(col: center, row: center))

        inputHandler.gameState = gameState
        inputHandler.cameraController = cameraController
        inputHandler.onSelectEntity = { [weak self] location in
            self?.selectEntity(at: location)
        }
        inputHandler.onPlaceBuilding = { [weak self] col, row in
            self?.placeBuilding(col: col, row: row)
        }
        inputHandler.onDemolish = { [weak self] location in
            self?.demolishAt(location: location)
        }
        inputHandler.onSave = { [weak self] in
            self?.performSave()
        }

        NotificationCenter.default.addObserver(
            forName: .performSaveToSlot,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let slot = notification.userInfo?["slot"] as? Int
            Task { @MainActor in
                if let slot {
                    self?.performSave(slot: slot)
                }
            }
        }

        if savedData != nil {
            gameState.log("Game loaded")
        } else {
            gameState.log("Welcome to NYC Survive")
        }
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // SpriteKit resolves colours at assign time, so repaint on any theme change (settings or system).
        // ponytail: a Bool compare per frame; swap for an observer if it ever shows in a profile.
        if paintedDark != Theme.isDark {
            paintedDark = Theme.isDark
            backgroundColor = ScenePalette.background
        }

        cameraController.update(deltaTime: dt)
        if gameState.isMenuBackdrop { animateBackdrop(dt) }
        let deep = gameState.currentHour >= 22 || gameState.currentHour < 4
        nightOverlay.alpha = gameState.isNight ? (deep ? 0.42 : 0.24) : 0

        let due = timeSystem.update(deltaTime: dt, gameState: gameState)
        guard due > 0 else { return }
        for _ in 0..<due where !gameState.isPaused {
            timeSystem.advance(gameState)
            needsSystem.tick(gameState: gameState)
            jobSystem.tick(gameState: gameState)
            resourceSystem.tick(gameState: gameState, tileMap: tileMap)
            needsSystem.recruitTick(gameState: gameState)
            needsSystem.raidTick(gameState: gameState)
            if !gameState.victoryShown, NeedsSystem.isVictory(gameState) {
                gameState.victoryShown = true
                gameState.isPaused = true
                gameState.log("TIMES SQUARE RECLAIMED. Victory on day \(gameState.currentTick / NeedsSystem.ticksPerDay).")
            }
        }

        // Auto-save every 60 ticks
        if gameState.autoSaveEnabled && gameState.currentTick > 0 && gameState.currentTick % 60 == 0 {
            if let slot = gameState.lastSaveSlot {
                performSave(slot: slot)
            }
        }

        for model in gameState.colonists {
            if let node = colonistNodes[model.id] {
                let target = tileMap.worldPosition(col: model.col, row: model.row)
                node.moveToward(target: target, speed: 4)
                node.update(model: model)
                let ringName = "selectionRing"
                let isPicked = selection.contains(model.id)
                if isPicked, node.childNode(withName: ringName) == nil {
                    let ring = SKShapeNode(circleOfRadius: 14)
                    ring.name = ringName
                    ring.strokeColor = ScenePalette.accentWarm
                    ring.fillColor = .clear
                    ring.lineWidth = 2
                    ring.zPosition = -1
                    node.addChild(ring)
                } else if !isPicked {
                    node.childNode(withName: ringName)?.removeFromParent()
                }
            }
        }

        for model in gameState.buildings {
            buildingNodes[model.id]?.alpha = model.isActive ? 1 : 0.4
        }

        for model in gameState.resourceNodes {
            if let node = resourceNodes[model.id] {
                node.update(model: model)
            }
        }

        // Tutorial highlights
        updateTutorialHighlights()

        #if os(macOS)
        if gameState.inputMode == .build, let type = gameState.selectedBuildingType {
            let mouseLocation = NSEvent.mouseLocation
            if let view = self.view {
                let viewPoint = view.convert(mouseLocation, from: nil)
                let scenePoint = convertPoint(fromView: viewPoint)
                let tilePos = tileMap.tilePosition(worldX: scenePoint.x, worldY: scenePoint.y)
                buildSystem.updateGhost(col: tilePos.col, row: tilePos.row, type: type, parent: self)
            }
        } else {
            buildSystem.removeGhost()
        }
        #else
        if gameState.inputMode != .build {
            buildSystem.removeGhost()
        }
        #endif
    }

    #if os(macOS)
    override func keyDown(with event: NSEvent) {
        inputHandler.handleKeyDown(event: event)
    }

    override func keyUp(with event: NSEvent) {
        inputHandler.handleKeyUp(event: event)
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        if gameState.inputMode == .normal {
            dragMoved = false
            selectionStart = location
            return
        }
        inputHandler.handleMouseDown(location: location, tileMap: tileMap)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = selectionStart else { return }
        let current = event.location(in: self)
        // Jitter under 6 pt is a click, not an empty drag-box that clears the selection.
        if !dragMoved, hypot(current.x - start.x, current.y - start.y) < 6 * cameraController.cameraNode.xScale { return }
        dragMoved = true
        updateSelectionRect(from: start, to: current)
    }

    override func mouseUp(with event: NSEvent) {
        if let start = selectionStart {
            let end = event.location(in: self)
            if dragMoved {
                finalizeSelection(from: start, to: end)
            } else {
                inputHandler.handleMouseDown(location: start, tileMap: tileMap)
            }
            selectionStart = nil
            selectionRect?.removeFromParent()
            selectionRect = nil
            return
        }
    }

    override func scrollWheel(with event: NSEvent) {
        inputHandler.handleScrollWheel(deltaY: event.deltaY)
    }
    #else
    private var touchStartLocation: CGPoint?
    private var touchMoved = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchStartLocation = touch.location(in: self)
        touchMoved = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start = touchStartLocation else { return }
        let current = touch.location(in: self)
        let previous = touch.previousLocation(in: self)
        if hypot(current.x - start.x, current.y - start.y) > 8 {
            touchMoved = true
        }
        if touchMoved {
            inputHandler.handlePan(delta: CGPoint(x: current.x - previous.x, y: current.y - previous.y))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start = touchStartLocation else { return }
        if !touchMoved {
            inputHandler.handleTap(location: start, tileMap: tileMap)
        }
        touchStartLocation = nil
        touchMoved = false
        _ = touch
    }

    func applyPinch(scale: CGFloat) {
        inputHandler.handlePinch(scale: scale)
    }
    #endif

    private func updateSelectionRect(from start: CGPoint, to end: CGPoint) {
        selectionRect?.removeFromParent()
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        let node = SKShapeNode(rect: rect)
        node.strokeColor = ScenePalette.title.withAlphaComponent(0.8)
        node.fillColor = ScenePalette.title.withAlphaComponent(0.15)
        node.lineWidth = 2
        node.zPosition = 100
        addChild(node)
        selectionRect = node
    }

    private func finalizeSelection(from start: CGPoint, to end: CGPoint) {
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        gameState.selectedColonistIds.removeAll()
        gameState.selectedColonistId = nil
        for (id, node) in colonistNodes {
            if rect.contains(node.position) {
                gameState.selectedColonistIds.insert(id)
            }
        }
        if gameState.selectedColonistIds.count == 1 {
            gameState.selectedColonistId = gameState.selectedColonistIds.first
        }
        if !gameState.selectedColonistIds.isEmpty {
            gameState.log("Selected \(gameState.selectedColonistIds.count) colonists")
        }
    }

    /// Everyone the player has picked, whether by click or by drag-box.
    private var selection: [UUID] {
        var ids = gameState.selectedColonistIds
        if let id = gameState.selectedColonistId { ids.insert(id) }
        return Array(ids)
    }

    /// One rule for everything: click a colonist to pick them, click a resource to send the
    /// picked ones to gather it, click the ground to send them there. Selection stays until Esc.
    private func selectEntity(at location: CGPoint) {
        for (id, node) in colonistNodes {
            let expandedFrame = node.frame.insetBy(dx: -10, dy: -10)
            if expandedFrame.contains(location) {
                gameState.selectedColonistIds = [id]
                gameState.selectedColonistId = id
                gameState.log("Selected \(gameState.colonists.first { $0.id == id }?.name ?? "colonist")")
                TutorialView.checkAdvance(gameState: gameState, event: .colonistSelected)
                return
            }
        }
        let picked = selection
        guard !picked.isEmpty else { return }
        let tilePos = tileMap.tilePosition(worldX: location.x, worldY: location.y)
        if let node = gameState.resourceNodes.first(where: { !$0.isDepleted && abs($0.col - tilePos.col) <= 1 && abs($0.row - tilePos.row) <= 1 }) {
            for id in picked {
                jobSystem.commandGather(colonistId: id, node: node, gameState: gameState, pathfinder: pathfinder)
            }
            return
        }
        for id in picked {
            jobSystem.commandMove(colonistId: id, destCol: tilePos.col, destRow: tilePos.row, gameState: gameState, pathfinder: pathfinder)
        }
    }

    private func placeBuilding(col: Int, row: Int) {
        guard let type = gameState.selectedBuildingType else { return }
        if let model = buildSystem.place(type: type, col: col, row: row, tileMap: tileMap, gameState: gameState, pathfinder: pathfinder) {
            let node = BuildingNode(model: model, tileSize: TileMap.tileSize)
            node.position = CGPoint(x: CGFloat(col) * TileMap.tileSize, y: CGFloat(row) * TileMap.tileSize)
            addChild(node)
            node.playPlaceAnimation()
            buildingNodes[model.id] = node
            AudioManager.shared.buildingPlaced()

            if type == .shelter {
                TutorialView.checkAdvance(gameState: gameState, event: .shelterPlaced)
            }

            // Grant build XP to nearby colonists
            for i in gameState.colonists.indices {
                if gameState.colonists[i].job == .build && !gameState.colonists[i].isDead {
                    let dist = abs(gameState.colonists[i].col - col) + abs(gameState.colonists[i].row - row)
                    if dist <= 5 {
                        gameState.colonists[i].grantXP(10)
                    }
                }
            }
        }
    }

    private func demolishAt(location: CGPoint) {
        for (id, node) in buildingNodes {
            if node.frame.contains(location) {
                buildSystem.demolish(id: id, tileMap: tileMap, gameState: gameState, pathfinder: pathfinder)
                node.removeFromParent()
                buildingNodes.removeValue(forKey: id)
                return
            }
        }
    }

    private func updateTutorialHighlights() {
        // Remove old highlights
        for node in tutorialHighlights { node.removeFromParent() }
        tutorialHighlights.removeAll()

        guard let step = gameState.tutorialStep else { return }

        switch step {
        case 2:
            // Pulse circles around colonists
            for (_, node) in colonistNodes {
                let pulse = SKShapeNode(circleOfRadius: 20)
                pulse.strokeColor = ScenePalette.accentWarm.withAlphaComponent(0.9)
                pulse.fillColor = .clear
                pulse.lineWidth = 2
                pulse.position = node.position
                pulse.zPosition = 50
                let grow = SKAction.scale(to: 1.5, duration: 0.6)
                let shrink = SKAction.scale(to: 1.0, duration: 0.6)
                let fade = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.3, duration: 0.6),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.6)
                ])
                pulse.run(SKAction.repeatForever(SKAction.group([SKAction.sequence([grow, shrink]), fade])))
                addChild(pulse)
                tutorialHighlights.append(pulse)
            }
        default:
            break
        }
    }

    private func performSave(slot: Int? = nil) {
        let targetSlot = slot ?? gameState.lastSaveSlot ?? 1
        do {
            try SaveManager.shared.save(slot: targetSlot, gameState: gameState, grid: tileMap.grid)
            gameState.lastSaveSlot = targetSlot
            gameState.showSaveIndicator = true
            gameState.log("Game saved to slot \(targetSlot)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.gameState.showSaveIndicator = false
            }
        } catch {
            gameState.log("Save failed: \(error.localizedDescription)")
        }
    }
}
