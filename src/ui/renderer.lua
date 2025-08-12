local SystemsUI          = require("ui.elements.systems")
-- local LogsUI             = require("ui.elements.logs")
-- local EffectsUI          = require("ui.elements.effects")
-- local HandUI             = require("ui.elements.hand")
-- local DeckUI             = require("ui.elements.deck")
-- local RAMUI              = require("ui.elements.ram")
-- local ThreatUI           = require("ui.elements.threat")
-- local DestructorUI       = require("ui.elements.destructor")
-- local EndTurnUI          = require("ui.elements.end_turn")
 
local Click              = require("ui.click")

local Renderer           = {}

local function tweenPos(tw)
  local p = tw.t / tw.duration
  return tw.from.x + (tw.to.x - tw.from.x) * p,
         tw.from.y + (tw.to.y - tw.from.y) * p
end

-- Renderer.transitionInProgress = false

-- function Renderer.processTransitionQueue()
--   if Renderer.transitionInProgress then return end

--   local queue = love.gameState.uiTransitions
--   if #queue == 0 then return end

--   local transition = table.remove(queue, 1)

--   if transition.type == "draw" then
--     TransitionHandlers.handleDraw {
--       transition = transition,
--       sections = sections,
--       applyTransition = GameState.applyTransition,
--       setBusy = function(flag) Renderer.transitionInProgress = flag end
--     }
--   elseif transition.type == "discard" then
--     TransitionHandlers.handleDiscard {
--       transition = transition,
--       sections = sections,
--       applyTransition = GameState.applyTransition,
--       setBusy = function(flag) Renderer.transitionInProgress = flag end
--     }
--   elseif transition.type == "play" then
--     TransitionHandlers.handlePlay {
--       transition = transition,
--       sections = sections,
--       applyTransition = GameState.applyTransition,
--       setBusy = function(flag) Renderer.transitionInProgress = flag end
--     }
--   elseif transition.type == "destructorPlay" then
--     TransitionHandlers.handleDestructorPlay {
--       transition = transition,
--       sections = sections,
--       applyTransition = GameState.applyTransition,
--       setBusy = function(flag) Renderer.transitionInProgress = flag end
--     }
--   else
--     error("Unknown transition type: " .. transition.type)
--   end
-- end

-- Debug draw rects
-- local function drawFrame(r, color)
--   lg.setColor(color)
--   lg.rectangle("line", r.x, r.y, r.w, r.h)
-- end

Renderer.drawUI = function(model, view)
  Click.clear()

  local anchors = view.anchors
  assert(anchors, "[Renderer.drawUI]: No anchors set in view!")

  local sections = anchors.sections

  -- lg.setLineWidth(cfg.lineWidth)
  -- local c = cfg.colors
  -- Debug rects
  -- drawFrame(sections.systems, c.white)
  -- drawFrame(sections.effects, c.blue)
  -- drawFrame(sections.play, c.green)
  -- drawFrame(sections.deck, c.yellow)
  -- drawFrame(sections.right, c.red)

  SystemsUI.drawSystemsPanel(sections.systems, model.systems, model.currentSystemIndex)
  -- EffectsUI.drawEffects(sections.effects, model.effects, view)
  -- LogsUI.drawLogs(sections.logs, model.logs, view)
  -- HandUI.drawHand(sections.play, model.hand, view)
  -- DeckUI.drawDeck(sections.deck, model.deck, view)
  -- RAMUI.drawRAM(sections.ram, model.ram, view)
  -- ThreatUI.drawThreat(sections.threat, model.threat, view)
  -- DestructorUI.drawDestructor(sections.destructor, model.destructor, view)
  -- EndTurnUI.drawEndTurnButton(sections.endTurn, model.endTurn, view)

  -- Renderer.processTransitionQueue()
end

return Renderer
