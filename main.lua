-----------------------------------
-- main.lua
-----------------------------------

local cellSize = 64
local gridWidth = 10
local gridHeight = 10

-- We'll give ourselves extra vertical space for UI at the bottom
local windowWidth  = gridWidth  * cellSize
local windowHeight = gridHeight * cellSize + 100

-- Player & Goal
local player = { x = 1, y = 1 }

-- Guards (1-step-per-turn movement)
local guards = {
    { x = 5, y = 5, route = {"right","left"} },
    { x = 8, y = 2, route = {"left","right"} },
}

-- Level Data
local levels = {
    {
        "P........G",
        ".#####....",
        "...#......",
        "..###.....",
        "..........",
        "....#####.",
        "...#......",
        "...#......",
        "..........",
        "....#####.",
    },
    {
        "P....#####",
        ".....#...G",
        ".....#....",
        ".....#....",
        "..........",
        "####......",
        "..........",
        "...#####..",
        "..........",
        "..........",
    },
}
local currentLevel = 1
local levelData = levels[currentLevel]

-- Movement planning
local plannedMoves = {}
local maxMovesPerTurn = 3

-- UI warning (shows messages like "No more moves!")
local warningMessage = ""

-- Sprites
local playerSprite, goalSprite, guardSprite, wallSprite
local upArrow, downArrow, leftArrow, rightArrow

----------------------------------------------------------------
-- LOVE Callbacks
----------------------------------------------------------------

function love.load()
    -- Set a fixed window size
    love.window.setMode(windowWidth, windowHeight, {resizable = false})
    love.window.setTitle("The Masterplan - Turn-Based Movement")

    -- Load Sprites
    playerSprite = love.graphics.newImage("sprites/player.png")
    goalSprite   = love.graphics.newImage("sprites/goal.png")
    guardSprite  = love.graphics.newImage("sprites/guard.png")
    wallSprite   = love.graphics.newImage("sprites/wall.png")

    upArrow    = love.graphics.newImage("sprites/up.png")
    downArrow  = love.graphics.newImage("sprites/down.png")
    leftArrow  = love.graphics.newImage("sprites/left.png")
    rightArrow = love.graphics.newImage("sprites/right.png")

    resetGame()
end

function love.update(dt)
    -- (No timed movement here; we move everything turn-by-turn.)
end

function love.draw()
    -- Draw the level grid (walls/floor)
    drawLevel()

    -- Draw grid lines on top so each cell is clearly visible
    drawGridLines()

    -- Draw player, goal, and guards
    drawSprite(playerSprite, player.x, player.y, cellSize)
    drawGoal()
    drawGuards()

    -- Draw planned moves (arrows) at bottom
    drawPlannedMoves()

    -- Show any warning message at the bottom
    if warningMessage and warningMessage ~= "" then
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.print(warningMessage, 10, gridHeight * cellSize + 60)
        love.graphics.setColor(1,1,1)
    end
end

function love.keypressed(key)
    -- Plan up to maxMovesPerTurn moves
    if key == "up" or key == "down" or key == "left" or key == "right" then
        if #plannedMoves < maxMovesPerTurn then
            table.insert(plannedMoves, key)
            warningMessage = ""
            if #plannedMoves == maxMovesPerTurn then
                warningMessage = "3 moves used! Press SPACE to confirm."
            end
        else
            warningMessage = "You can't move any further, 3 moves max!"
        end
    elseif key == "space" then
        -- Execute player's planned moves, then enemy moves
        if #plannedMoves > 0 then
            executePlayerMoves()
            moveEnemies()
            -- Reset for next turn
            plannedMoves = {}
            warningMessage = ""
        else
            warningMessage = "No moves planned!"
        end
    elseif key == "r" then
        -- Reset the level
        resetGame()
    end
end

----------------------------------------------------------------
-- Turn & Movement Logic
----------------------------------------------------------------

-- Apply each of the planned moves in quick succession
function executePlayerMoves()
    for i=1, #plannedMoves do
        local move = plannedMoves[i]
        movePlayer(move)
    end
end

-- Guards each move one step along their route
function moveEnemies()
    for _, guard in ipairs(guards) do
        local nextMove = guard.route[1]
        if nextMove == "right" and guard.x < gridWidth then
            guard.x = guard.x + 1
        elseif nextMove == "left" and guard.x > 1 then
            guard.x = guard.x - 1
        end
        -- Swap route directions
        guard.route[1], guard.route[2] = guard.route[2], guard.route[1]
    end
end

----------------------------------------------------------------
-- Game Setup & Helpers
----------------------------------------------------------------

function resetGame()
    plannedMoves = {}
    warningMessage = ""

    -- Load the level's player/goal positions
    for y, row in ipairs(levelData) do
        for x = 1, #row do
            local cell = row:sub(x, x)
            if cell == "P" then
                player.x, player.y = x, y
            elseif cell == "G" then
                goalX, goalY = x, y
            end
        end
    end

    -- Reset guard positions to defaults
    guards[1].x, guards[1].y = 5, 5
    guards[1].route = {"right","left"}

    guards[2].x, guards[2].y = 8, 2
    guards[2].route = {"left","right"}
end

-- Move the player if target cell is passable
function movePlayer(direction)
    local dx, dy = 0, 0
    if direction == "up"    then dy = -1
    elseif direction == "down"  then dy =  1
    elseif direction == "left"  then dx = -1
    elseif direction == "right" then dx =  1
    end

    local newX = player.x + dx
    local newY = player.y + dy

    if isPassable(newX, newY) then
        player.x, player.y = newX, newY
    end
end

function isPassable(x, y)
    if x < 1 or y < 1 or x > gridWidth or y > gridHeight then
        return false
    end
    local cell = levelData[y]:sub(x, x)
    return (cell ~= "#")
end

----------------------------------------------------------------
-- Drawing Functions
----------------------------------------------------------------

function drawLevel()
    for y, row in ipairs(levelData) do
        for x = 1, #row do
            local cell = row:sub(x, x)
            if cell == "#" then
                -- Draw wall sprite, scaled
                drawSprite(wallSprite, x, y, cellSize)
            else
                -- Floor background
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.rectangle("fill",
                    (x - 1) * cellSize,
                    (y - 1) * cellSize,
                    cellSize,
                    cellSize
                )
                love.graphics.setColor(1,1,1)
            end
        end
    end
end

function drawGridLines()
    love.graphics.setColor(0, 0, 0)
    for i = 0, gridWidth do
        local gx = i * cellSize
        love.graphics.line(gx, 0, gx, gridHeight * cellSize)
    end
    for j = 0, gridHeight do
        local gy = j * cellSize
        love.graphics.line(0, gy, gridWidth * cellSize, gy)
    end
    love.graphics.setColor(1,1,1)
end

function drawSprite(sprite, gx, gy, cSize)
    local spriteW = sprite:getWidth()
    local spriteH = sprite:getHeight()

    local scaleX = cSize / spriteW
    local scaleY = cSize / spriteH

    -- Center in the cell
    local offsetX = (cSize - spriteW * scaleX) / 2
    local offsetY = (cSize - spriteH * scaleY) / 2

    love.graphics.draw(
        sprite,
        (gx - 1) * cSize + offsetX,
        (gy - 1) * cSize + offsetY,
        0,
        scaleX,
        scaleY
    )
end

function drawGoal()
    -- Search for G in the levelData to find the goal coords
    for y, row in ipairs(levelData) do
        for x = 1, #row do
            local cell = row:sub(x, x)
            if cell == "G" then
                drawSprite(goalSprite, x, y, cellSize)
                return
            end
        end
    end
end

function drawGuards()
    for _, guard in ipairs(guards) do
        drawSprite(guardSprite, guard.x, guard.y, cellSize)
    end
end

function drawPlannedMoves()
    for i, move in ipairs(plannedMoves) do
        local icon
        if move == "up"    then icon = upArrow
        elseif move == "down"  then icon = downArrow
        elseif move == "left"  then icon = leftArrow
        elseif move == "right" then icon = rightArrow
        end

        local scale = 0.5
        local iconX = 10 + (i - 1) * 70
        local iconY = gridHeight * cellSize + 20

        if icon then
            love.graphics.draw(icon, iconX, iconY, 0, scale, scale)
        end
    end
end
