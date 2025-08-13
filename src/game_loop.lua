local Const     = require("const")
local Store     = require("store")
local Profiles  = require("profiles")
local cfg       = require("ui.cfg")
local Display   = require("ui.display")
local Renderer  = require("ui.renderer")
local Click     = require("ui.click")
local Menu      = require("ui.menus.menu")
-- local EndGameUI = require("ui.elements.end_game")

local TURN_PHASES = Const.TURN_PHASES
local ACTIONS = Const.DISPATCH_ACTIONS

local GameLoop  = {}
GameLoop.profileIndex = nil

function GameLoop.init(profileIndex, loadedModel)
  GameLoop.profileIndex = profileIndex
  Store.bootstrap(loadedModel)
  -- Kick into a playable state if needed:
  local phase = Store.getPhase()
  assert(phase, "GameLoop.init: No phase set in model!")
  if phase == TURN_PHASES.BEGIN_FIRST_TURN then
    Store.dispatch({ type = ACTIONS.BEGIN_TURN })
  end
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
  -- EndGameUI.draw()
end

local function inputLocked() return Store.view and Store.view.inputLocked end

function GameLoop.mousepressed(x, y, button)
  if Menu.mousepressed(x, y, button) then return end
  -- if EndGameUI.mousepressed(x, y, button) then return end
  if inputLocked() then return end

  local vx, vy = Display.toVirtual(x, y)
  local hit = Click.hit(vx, vy)
  if not hit then return end

  if button == 1 then
    if hit.id == Const.END_TURN_BUTTON.ID then
      Store.dispatch({ type = ACTIONS.END_TURN })
    elseif hit.id == Const.HIT_IDS.CARD then
      Store.dispatch({ type = ACTIONS.PLAY_CARD, idx = hit.payload.handIndex })
    end
  elseif button == 2 and hit.id == Const.HIT_IDS.CARD then
    Store.dispatch({ type = ACTIONS.DISCARD_CARD, idx = hit.payload.handIndex })
  end

  -- end-game overlay
  -- local phase = Store.model.turn.phase
  -- if (phase == "won" or phase == "lost") and not EndGameUI.isOpen then
  --   EndGameUI.isOpen = true
  -- end
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
