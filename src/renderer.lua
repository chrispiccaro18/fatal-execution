local lg                 = love.graphics
local cfg                = require("ui.cfg")
local GameState          = require("game_state.index")
local TransitionHandlers = require("ui.transitions.handler")
local Display            = require("ui.display")
local SystemsUI          = require("ui.elements.systems")
local LogsUI             = require("ui.elements.logs")
local EffectsUI          = require("ui.elements.effects")
local HandUI             = require("ui.elements.hand")
local DeckUI             = require("ui.elements.deck")
local RAMUI              = require("ui.elements.ram")
local ThreatUI           = require("ui.elements.threat")
local DestructorUI       = require("ui.elements.destructor")
local EndTurnUI          = require("ui.elements.end_turn")
local Click              = require("ui.click")

local Renderer           = {}

local sections           = {} -- will hold the rects we compute

local function rect(x, y, w, h) return { x = x, y = y, w = w, h = h } end

local function sliceH(r, where, ratio)
  local w = r.w * ratio -- width of the slice
  local x = r.x         -- default: left‐aligned

  if where == "center" then
    x = r.x + (r.w - w) / 2
  elseif where == "right" then
    x = r.x + (r.w - w)
  elseif where ~= "left" then
    error("sliceH: where must be 'left', 'center', or 'right'")
  end

  return { x = x, y = r.y, w = w, h = r.h }
end

local function sliceV(r, where, ratio)
  local h = r.h * ratio -- height of the slice
  local y = r.y         -- default: top‐aligned

  if where == "center" then
    y = r.y + (r.h - h) / 2
  elseif where == "bottom" then
    y = r.y + (r.h - h)
  elseif where ~= "top" then
    error("sliceV: where must be 'top', 'center', or 'bottom'")
  end

  return { x = r.x, y = y, w = r.w, h = h }
end

local function relayout(w, h)
  local g       = cfg.gutter

  -- main columns
  local leftW   = math.floor(w * cfg.leftColW - g)
  local rightW  = w - leftW - g

  -- LEFT STACK
  local leftX   = 0
  local cursorY = 0

  local function nextRow(pct)
    local hRow = math.floor(h * pct - g)
    local r    = rect(leftX, cursorY, leftW, hRow)
    cursorY    = cursorY + hRow + g
    return r
  end

  sections.first   = nextRow(cfg.systemsH)
  sections.second  = nextRow(cfg.effectsH)
  sections.third   = nextRow(cfg.playH)
  sections.fourth  = nextRow(cfg.deckH)

  sections.systems = sections.first
  sections.effects = sliceH(sections.second, "left", 0.5)
  sections.logs    = sliceH(sections.second, "right", 0.5)
  sections.play    = sections.third
  sections.deck    = sliceH(sections.fourth, "left", 0.33)
  sections.ram     = sliceH(sections.fourth, "center", 0.33)

  -- RIGHT COLUMN
  sections.right   = rect(leftW + g, 0, rightW, h)

  sections.threat = sliceV(sections.right, "top", 0.2)
  sections.destructor = sliceV(sections.right, "center", 0.5)
  sections.endTurn = sliceV(sections.right, "bottom", 0.2)
end

Renderer.transitionInProgress = false

function Renderer.processTransitionQueue()
  if Renderer.transitionInProgress then return end

  local queue = love.gameState.uiTransitions
  if #queue == 0 then return end

  local transition = table.remove(queue, 1)

  if transition.type == "draw" then
    TransitionHandlers.handleDraw {
      transition = transition,
      sections = sections,
      applyTransition = GameState.applyTransition,
      setBusy = function(flag) Renderer.transitionInProgress = flag end
    }
  elseif transition.type == "discard" then
    TransitionHandlers.handleDiscard {
      transition = transition,
      sections = sections,
      applyTransition = GameState.applyTransition,
      setBusy = function(flag) Renderer.transitionInProgress = flag end
    }
  elseif transition.type == "play" then
    TransitionHandlers.handlePlay {
      transition = transition,
      sections = sections,
      applyTransition = GameState.applyTransition,
      setBusy = function(flag) Renderer.transitionInProgress = flag end
    }
  elseif transition.type == "destructorPlay" then
    TransitionHandlers.handleDestructorPlay {
      transition = transition,
      sections = sections,
      applyTransition = GameState.applyTransition,
      setBusy = function(flag) Renderer.transitionInProgress = flag end
    }
  else
    error("Unknown transition type: " .. transition.type)
  end
end

-- Debug draw rects
-- local function drawFrame(r, color)
--   lg.setColor(color)
--   lg.rectangle("line", r.x, r.y, r.w, r.h)
-- end

Renderer.drawUI = function()
  Click.clear()
  relayout(Display.VIRTUAL_W, Display.VIRTUAL_H)

  lg.setLineWidth(cfg.lineWidth)
  local c = cfg.colors
  -- Debug rects
  -- drawFrame(sections.systems, c.white)
  -- drawFrame(sections.effects, c.blue)
  -- drawFrame(sections.play, c.green)
  -- drawFrame(sections.deck, c.yellow)
  -- drawFrame(sections.right, c.red)

  SystemsUI.drawSystemsPanel(sections.systems)
  EffectsUI.drawEffects(sections.effects)
  LogsUI.drawLogs(sections.logs)
  HandUI.drawHand(sections.play)
  DeckUI.drawDeck(sections.deck)
  RAMUI.drawRAM(sections.ram)
  ThreatUI.drawThreat(sections.threat)
  DestructorUI.drawDestructor(sections.destructor)
  EndTurnUI.drawEndTurnButton(sections.endTurn)

  Renderer.processTransitionQueue()
end

return Renderer
