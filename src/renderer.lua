local lg                 = love.graphics
local cfg                = require("ui.cfg")
local GameState          = require("game_state.index")
local Animation          = require("ui.animate")
local TransitionHandlers = require("ui.transitions.handler")
local Display            = require("ui.display")
local SystemsUI          = require("ui.elements.systems")
local HandUI             = require("ui.elements.hand")
local LogsUI             = require("ui.elements.logs")
local DeckUI             = require("ui.elements.deck")
local RAMUI              = require("ui.elements.ram")
local ThreatUI           = require("ui.elements.threat")
local DestructorUI       = require("ui.elements.destructor")
local EndTurnUI          = require("ui.elements.end_turn")
local Click              = require("ui.click")

local Renderer           = {}

local sections           = {} -- will hold the rects we compute

-- Quick helper – returns a rect table
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

  -- ----- LEFT STACK --------------------------------------------------------
  local leftX   = 0
  local cursorY = 0

  local function nextRow(pct)
    local hRow = math.floor(h * pct - g)
    local r    = rect(leftX, cursorY, leftW, hRow)
    cursorY    = cursorY + hRow + g
    return r
  end

  sections.systems = nextRow(cfg.systemsH)
  sections.effects = nextRow(cfg.effectsH)
  sections.play    = nextRow(cfg.playH)
  sections.deck    = nextRow(cfg.deckH)

  -- ----- RIGHT COLUMN ------------------------------------------------------
  sections.right   = rect(leftW + g, 0, rightW, h) -- single tall red rect
end

local function drawFrame(r, color)
  lg.setColor(color)
  lg.rectangle("line", r.x, r.y, r.w, r.h)
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
    -- local card = transition.payload.card
    -- local index = transition.payload.index

    -- Renderer.transitionInProgress = true

    -- local deckPanel = sections.deck
    -- local handPanel = sections.play
    -- local pad = cfg.deckPanel.pad

    -- local spacingX = math.min(cfg.handPanel.maxSpacingX,
    --                           (handPanel.w - pad * 2 - cfg.handPanel.cardW * index) / math.max(1, index - 1))
    -- local xOffset = (index - 1) * (cfg.handPanel.cardW + spacingX)

    -- local startX = deckPanel.x + pad
    -- local startY = deckPanel.y + pad
    -- local endX = handPanel.x + pad + xOffset
    -- local endY = handPanel.y + pad

    -- card.animX = startX
    -- card.animY = startY

    -- Animation.add {
    --   duration = 0.4,
    --   onUpdate = function(t)
    --     local tt = 1 - (1 - t) ^ 2
    --     card.animX = startX + (endX - startX) * tt
    --     card.animY = startY + (endY - startY) * tt
    --   end,
    --   onComplete = function()
    --     card.animX = nil
    --     card.animY = nil

    --     -- Apply the logical result
    --     love.gameState = GameState.applyTransition(love.gameState, transition)

    --     Renderer.transitionInProgress = false
    --   end,
    --   onDraw = function()
    --     love.graphics.setColor(0.8, 0.8, 0.8)
    --     love.graphics.rectangle("fill", card.animX, card.animY, cfg.handPanel.cardW, cfg.handPanel.cardH)
    --     love.graphics.setColor(1, 1, 0)
    --     love.graphics.rectangle("line", card.animX, card.animY, cfg.handPanel.cardW, cfg.handPanel.cardH)
    --   end
    -- }
  elseif transition.type == "discard" then
    TransitionHandlers.handleDiscard {
      transition = transition,
      sections = sections,
      applyTransition = GameState.applyTransition,
      setBusy = function(flag) Renderer.transitionInProgress = flag end
    }
    -- Renderer.transitionInProgress = true

    -- local card = transition.payload.card
    -- local handIndex = transition.payload.handIndex

    -- card.state = "discarding"
    -- card.selectable = false

    -- -- Get hand card position
    -- local handPanel = sections.play
    -- local pad = cfg.handPanel.pad

    -- local spacingX = math.min(cfg.handPanel.maxSpacingX,
    --                           (handPanel.w - pad * 2 - cfg.handPanel.cardW * #love.gameState.hand) /
    --                           math.max(1, #love.gameState.hand - 1))
    -- local xOffset = (handIndex - 1) * (cfg.handPanel.cardW + spacingX)
    -- local startX = handPanel.x + pad + xOffset
    -- local startY = handPanel.y + pad

    -- -- Get destructor panel center
    -- local destPanel = sections.right
    -- local endX = destPanel.x + destPanel.w / 2 - cfg.handPanel.cardW / 2
    -- local endY = destPanel.y + destPanel.h / 2 - cfg.handPanel.cardH / 2

    -- card.animX = startX
    -- card.animY = startY

    -- Animation.add {
    --   duration = 0.4,
    --   onUpdate = function(t)
    --     local tt = 1 - (1 - t) ^ 2
    --     card.animX = startX + (endX - startX) * tt
    --     card.animY = startY + (endY - startY) * tt
    --   end,
    --   onComplete = function()
    --     card.animX = nil
    --     card.animY = nil
    --     love.gameState = GameState.applyTransition(love.gameState, transition)
    --     Renderer.transitionInProgress = false
    --   end,
    --   onDraw = function()
    --     love.graphics.setColor(0.5, 0.5, 0.5)
    --     love.graphics.rectangle("fill", card.animX, card.animY, cfg.handPanel.cardW, cfg.handPanel.cardH)
    --     love.graphics.setColor(1, 0.5, 0.5)
    --     love.graphics.rectangle("line", card.animX, card.animY, cfg.handPanel.cardW, cfg.handPanel.cardH)
    --   end
    -- }
  else
    error("Unknown transition type: " .. transition.type)
  end
end

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
  HandUI.drawHand(sections.play)
  LogsUI.drawLogs(sliceH(sections.effects, "right", 0.5))
  DeckUI.drawDeck(sliceH(sections.deck, "left", 0.33))
  RAMUI.drawRAM(sliceH(sections.deck, "center", 0.33))
  ThreatUI.drawThreat(sliceV(sections.right, "top", 0.2))
  DestructorUI.drawDestructor(sliceV(sections.right, "center", 0.5))
  EndTurnUI.drawEndTurnButton(sliceV(sections.right, "bottom", 0.2))

  Renderer.processTransitionQueue()
end

return Renderer
