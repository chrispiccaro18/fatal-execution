local Const     = require("const")
local Display   = require("ui.display")
local Renderer  = require("renderer")
local Click     = require("ui.click")
local Menu      = require("ui.menus.menu")
local EndGameUI = require("ui.elements.end_game")
local Store     = require("store")
local Profiles  = require("profiles")
local cfg       = require("ui.cfg")

local GameLoop  = {}

function GameLoop.init(profileIndex, loadedModel)
  Store.bootstrap(loadedModel)
  -- Kick into a playable state if needed:
  if Store.model.turn.phase ~= Const.TURN_PHASES.IN_PROGRESS then
    Store.dispatch({ type = "BEGIN_TURN" })
  end
  GameLoop.profileIndex = profileIndex
end

function GameLoop.update(dt)
  Store.update(dt)
  -- optional: when safe, autosave debounced
  if Store.view and not Store.view.inputLocked then
    -- save only when no tasks/animations pending
    if (not Store.model.tasks) or (#Store.model.tasks == 0) then
      Profiles.setCurrentRun(GameLoop.profileIndex, Store.model) -- debounced under the hood
    end
  end
end

function GameLoop.draw()
  local lg = love.graphics
  lg.setCanvas(Display.canvas)
  lg.clear(cfg.colors.almostBlack[1], cfg.colors.almostBlack[2], cfg.colors.almostBlack[3])
  Renderer.drawUI(Store.model, Store.view) -- draw from state only
  lg.setCanvas()

  lg.push()
  lg.translate(Display.offsetX, Display.offsetY)
  lg.scale(Display.scale, Display.scale)
  lg.setColor(cfg.colors.white)
  lg.draw(Display.canvas, 0, 0)
  lg.pop()

  Menu.draw()
  EndGameUI.draw()
end

local function inputLocked() return Store.view and Store.view.inputLocked end

function GameLoop.mousepressed(x, y, button)
  if Menu.mousepressed(x, y, button) then return end
  if EndGameUI.mousepressed(x, y, button) then return end
  if inputLocked() then return end

  local vx, vy = Display.toVirtual(x, y)
  local hit = Click.hit(vx, vy)
  if not hit then return end

  if button == 1 then
    if hit.id == "endTurn" then
      Store.dispatch({ type = "END_TURN" })
    elseif hit.id == "card" then
      Store.dispatch({ type = "PLAY_CARD", idx = hit.payload.handIndex })
    end
  elseif button == 2 and hit.id == "card" then
    Store.dispatch({ type = "DISCARD_CARD", idx = hit.payload.handIndex })
  end

  -- end-game overlay
  local phase = Store.model.turn.phase
  if (phase == "won" or phase == "lost") and not EndGameUI.isOpen then
    EndGameUI.isOpen = true
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
