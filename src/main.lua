-- local Const = require("const")
local GameState = require("game_state.index")
local Display = require("ui.display")
local Click = require("ui.click")
local Renderer = require("renderer")
local Menu = require("ui.menu")
local EndGameUI = require("ui.elements.end_game")
local Animation = require("ui.animate")
local Decorators = require("ui.decorators")

package.path = package.path
    .. ";src/?.lua"
    .. ";src/?/init.lua"
    .. ";src/?/?.lua"

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  math.randomseed(os.time())

  -- Initialize the game state
  local state = GameState.init()

  -- Begin the first turn
  state = GameState.beginTurn(state)

  -- Store the initial state in love's userdata for access in other modules
  love.gameState = state
end

function love.update(dt)
  Animation.update(dt)
  Decorators.updateAll(dt)
  Decorators.consumeAndDispatch()
end

function love.draw()
  -- local boardImage = love.graphics.newImage("assets/ui-sketch-no-resize.png")
  -- love.graphics.draw(boardImage, 0, 0, 0, Const.SCALE, Const.SCALE)
  love.graphics.setCanvas(Display.canvas)
  love.graphics.clear(0.07, 0.07, 0.07) -- Dark gray background
  Renderer.drawUI()
  Animation.draw()
  love.graphics.setCanvas()             -- Reset to the main canvas

  love.graphics.push()
  love.graphics.translate(Display.offsetX, Display.offsetY)
  love.graphics.scale(Display.scale, Display.scale)
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(Display.canvas, 0, 0)
  love.graphics.pop()

  Menu.draw()
  EndGameUI.draw()
end

function love.mousepressed(x, y, button)
  if EndGameUI.mousepressed(x, y, button) then return end

  local vx, vy = Display.toVirtual(x, y)
  local hit = Click.hit(vx, vy)
  if not hit then return end

  if button == 1 then -- Left mouse button
    if hit.id == "endTurn" then
      love.gameState = GameState.endTurn(love.gameState)

      -- if love.gameState.turn.phase == "start" or love.gameState.turn.phase == "in_progress" then
      --   love.gameState = GameState.beginTurn(love.gameState)
      -- end
    elseif hit.id == "card" then
      local payload = hit.payload -- which card was clicked
      love.gameState = GameState.playCard(love.gameState, payload.handIndex)
    end
  end

  if button == 2 then -- Right mouse button clicked
    if hit.id == "card" then
      local payload = hit.payload
      love.gameState = GameState.discardCardForRam(love.gameState, payload.handIndex)
    end
  end

  local phaseAfterClick = love.gameState.turn.phase
  if (phaseAfterClick == "won" or phaseAfterClick == "lost") and not EndGameUI.isOpen then
    EndGameUI.isOpen = true
  end
end

function love.keypressed(key)
  if Menu.keypressed(key) then return end

  if key == "escape" then
    love.event.quit() -- Exit the game
  elseif key == "m" then
    Menu.toggle()     -- Toggle the menu
  end
end

-- Debugging code to check the working directory and file existence
-- print("Working Directory:", love.filesystem.getWorkingDirectory())
-- local fileInfo = love.filesystem.getInfo("assets/ui-sketch-no-resize.png")
-- if not fileInfo then
--     print("File not found: ../assets/ui-sketch-no-resize.png")
-- else
--     print("File found!")
-- end

-- math.randomseed(os.time())

-- local GameState = require("game_state.index")

-- local state = GameState.init()
-- state = GameState.beginTurn(state)

-- local function printState(state)
--   print("\n============================")
--   print("Environment Effect:", state.envEffect)
--   print("Turn:", state.turn.turnCount)
--   print("RAM:", state.ram)
--   print("Threat:", state.threat.value .. "/" .. state.threat.max)
--   local nextDestructorCard = state.destructorQueue[1]
--   local destructorText = "Destructor Queue Empty :)"
--   if nextDestructorCard then
--     destructorText = nextDestructorCard.name .. " (" .. nextDestructorCard.destructorEffect.type .. " " .. nextDestructorCard.destructorEffect.amount .. ")"
--   end
--   print("Next Destructor Card:", destructorText)
--   local system = state.systems[state.currentSystemIndex]
--   print("Restoring:", system.name)
--   print("Progress:", system.progress .. "/" .. system.required)

--   print("\nHand:")
--   for i, card in ipairs(state.hand) do
--     print(string.format(" [%d] %s (Cost: %d) — Effect: %s %d / Destructor: %s %d",
--       i, card.name, card.cost,
--       card.playEffect.type, card.playEffect.amount,
--       card.destructorEffect.type, card.destructorEffect.amount
--     ))
--   end

--   print("\nRecent Log:")
--   for i = math.max(1, #state.log - 5), #state.log do
--     print(" -", state.log[i])
--   end
--   print("============================\n")
-- end

-- local function prompt()
--   print("Choose an action:")
--   print(" 1. Play card [index]")
--   print(" 2. Discard card for RAM [index]")
--   print(" 3. End turn")
--   print(" 4. Exit game")
--   io.write("> ")
--   return io.read()
-- end

-- while true do
--   printState(state)

--   if state.turn.phase == "won" or state.turn.phase == "lost" then
--     print("== GAME OVER ==")
--     break
--   end

--   local input = prompt()

--   local cmd, arg = input:match("^(%d)%s*(%d*)$")
--   cmd = tonumber(cmd)
--   arg = tonumber(arg)

--   if cmd == 1 and arg then
--     state = GameState.playCard(state, arg)
--   elseif cmd == 2 and arg then
--     state = GameState.discardCardForRam(state, arg)
--   elseif cmd == 3 then
--     state = GameState.endTurn(state)
--     if state.turn.phase == "start" or state.turn.phase == "in_progress" then
--       state = GameState.beginTurn(state)
--     end
--   elseif cmd == 4 then
--     print("Exiting...")
--     os.exit()
--     break
--   else
--     print("Invalid input.")
--   end
-- end
