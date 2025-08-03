local GameState = require("game_state.index")
local Display = require("ui.display")
local Click = require("ui.click")
local Renderer = require("renderer")
local Menu = require("ui.menu")
local EndGameUI = require("ui.elements.end_game")
local Animation = require("ui.animate")
local Decorators = require("ui.decorators")

local GameLoop = {}

function GameLoop.init(initialState)
  love.gameState = initialState or GameState.beginTurn(GameState.init())
end

function GameLoop.update(dt)
  Animation.update(dt)
  Decorators.updateAll(dt)
  Decorators.consumeAndDispatch()
end

function GameLoop.draw()
  local lg = love.graphics

  lg.setCanvas(Display.canvas)
  lg.clear(0.07, 0.07, 0.07)
  Renderer.drawUI()
  Animation.draw()
  lg.setCanvas()

  lg.push()
  lg.translate(Display.offsetX, Display.offsetY)
  lg.scale(Display.scale, Display.scale)
  lg.setColor(1, 1, 1)
  lg.draw(Display.canvas, 0, 0)
  lg.pop()

  Menu.draw()
  EndGameUI.draw()
end

function GameLoop.mousepressed(x, y, button)
  if Menu.mousepressed(x, y, button) then return end
  if EndGameUI.mousepressed(x, y, button) then return end

  local vx, vy = Display.toVirtual(x, y)
  local hit = Click.hit(vx, vy)
  if not hit then return end

  if button == 1 then
    if hit.id == "endTurn" then
      love.gameState = GameState.endTurn(love.gameState)
    elseif hit.id == "card" then
      love.gameState = GameState.playCard(love.gameState, hit.payload.handIndex)
    end
  elseif button == 2 and hit.id == "card" then
    love.gameState = GameState.discardCardForRam(love.gameState, hit.payload.handIndex)
  end

  if love.gameState then
    local phase = love.gameState.turn.phase
    if (phase == "won" or phase == "lost") and not EndGameUI.isOpen then
      EndGameUI.isOpen = true
    end
  end
end

function GameLoop.keypressed(key)
  if Menu.keypressed(key) then return end

  if key == "escape" then
    love.event.quit()
  elseif key == "m" then
    Menu.toggle()
  end
end

return GameLoop

