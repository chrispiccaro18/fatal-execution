local Const               = require("const")
local Store               = require("store")
local Profiles            = require("profiles")
local cfg                 = require("ui.cfg")
local Display             = require("ui.display")
local Click               = require("ui.click")
local Menu                = require("ui.menus.menu")

local TURN_PHASES         = Const.TURN_PHASES
local ACTIONS             = Const.DISPATCH_ACTIONS

local GameLoop            = {}
GameLoop.profileIndex     = nil
GameLoop.lastHoveredIndex = nil
GameLoop.lastInputLocked  = false
GameLoop.pendingHoverRescanFrames = 0

function GameLoop.init(profileIndex, loadedModel)
  GameLoop.profileIndex = profileIndex
  Store.bootstrap(loadedModel)
  local phase = Store.getPhase()
  assert(phase, "GameLoop.init: No phase set in model!")
  if phase == TURN_PHASES.BEGIN_FIRST_TURN then
    Store.dispatch({ type = ACTIONS.BEGIN_TURN })
  end
end

function GameLoop.update(dt)
  Store.update(dt)

  local nowLocked = Store.view and Store.view.inputLocked or false

  -- When UI unlocks (animations finished), schedule a hover rescan next frame.
  if GameLoop.lastInputLocked and not nowLocked then
    GameLoop.pendingHoverRescanFrames = 2
  end
  GameLoop.lastInputLocked = nowLocked

  -- Deferred hover rescan (runs after Store.update on a following frame)
  if GameLoop.pendingHoverRescanFrames > 0 and not nowLocked then
    GameLoop.pendingHoverRescanFrames = GameLoop.pendingHoverRescanFrames - 1
    if GameLoop.pendingHoverRescanFrames == 0 then
      local mx, my = love.mouse.getPosition()
      local vx, vy = Display.toVirtual(mx, my)
      local hit = Click.hit(vx, vy)

      local newHoveredIndex, cardInstanceId = nil, nil
      if hit and hit.id == Const.HIT_IDS.CARD then
        newHoveredIndex = hit.payload.handIndex
        cardInstanceId = hit.payload.instanceId
      end

      -- Force a recompute regardless of previous debounce
      GameLoop.lastHoveredIndex = newHoveredIndex
      Store.scheduleIntent({
        kind = Const.UI.INTENTS.SET_HOVERED_CARD,
        handIndex = newHoveredIndex,
        cardInstanceId = cardInstanceId,
      })
    end
  end

  if Store.view and not nowLocked then
    if (not Store.model.tasks) or (#Store.model.tasks == 0) then
      Profiles.setCurrentRun(GameLoop.profileIndex, Store.model)
    end
  end
end

function GameLoop.draw()
  local lg = love.graphics
  lg.setCanvas(Display.canvas)
  lg.clear(cfg.colors.almostBlack[1], cfg.colors.almostBlack[2], cfg.colors.almostBlack[3])
  Store.draw()
  lg.setCanvas()

  lg.push()
  lg.translate(Display.offsetX, Display.offsetY)
  lg.scale(Display.scale, Display.scale)
  lg.setColor(cfg.colors.white)
  lg.draw(Display.canvas, 0, 0)
  lg.pop()

  Menu.draw()
end

local function inputLocked() return Store.view and Store.view.inputLocked end

function GameLoop.mousepressed(x, y, button)
  if Menu.mousepressed(x, y, button) then return end
  if inputLocked() then return end

  local vx, vy = Display.toVirtual(x, y)
  local hit = Click.hit(vx, vy)
  if not hit then return end

  if button == 1 then
    if hit.id == Const.END_TURN_BUTTON.ID then
      Store.dispatch({ type = ACTIONS.END_TURN_CLICKED })
    elseif hit.id == Const.HIT_IDS.CARD then
      Store.dispatch({ type = ACTIONS.PLAY_CARD, idx = hit.payload.handIndex })
    end
  elseif button == 2 and hit.id == Const.HIT_IDS.CARD then
    Store.dispatch({ type = ACTIONS.DISCARD_CARD, idx = hit.payload.handIndex })
  end
end

function GameLoop.mousemoved(x, y)
  if inputLocked() then return end

  local vx, vy = Display.toVirtual(x, y)
  local hit = Click.hit(vx, vy)
  local newHoveredIndex = nil
  local cardInstanceId = nil

  if hit and hit.id == Const.HIT_IDS.CARD then
    newHoveredIndex = hit.payload.handIndex
    cardInstanceId = hit.payload.instanceId
  end

  if newHoveredIndex ~= GameLoop.lastHoveredIndex then
    GameLoop.lastHoveredIndex = newHoveredIndex
    Store.scheduleIntent({
      kind = Const.UI.INTENTS.SET_HOVERED_CARD,
      handIndex = newHoveredIndex,
      cardInstanceId = cardInstanceId,
    })
  end
end

function GameLoop.keypressed(key)
  if Menu.keypressed(key) then return end
  if key == "escape" or key == "m" then
    Menu.toggle()
  end
end

return GameLoop
