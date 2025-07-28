local lg       = love.graphics
local cfg      = require ("ui.cfg")
local Display = require("ui.display")
local SystemsUI = require("ui.elements.systems")
local HandUI = require("ui.elements.hand")
local LogsUI = require("ui.elements.logs")
local DeckUI = require("ui.elements.deck")
local RAMUI = require("ui.elements.ram")
local ThreatUI = require("ui.elements.threat")
local DestructorUI = require("ui.elements.destructor")
local EndTurnUI = require("ui.elements.end_turn")
local Click = require("ui.click")

local Renderer = {}

local sections = {}  -- will hold the rects we compute

-- Quick helper – returns a rect table
local function rect(x, y, w, h) return { x = x, y = y, w = w, h = h } end

local function sliceH(r, where, ratio)
  local w = r.w * ratio                        -- width of the slice
  local x = r.x                                -- default: left‐aligned

  if     where == "center" then
    x = r.x + (r.w - w) / 2
  elseif where == "right" then
    x = r.x + (r.w - w)
  elseif where ~= "left" then
    error("sliceH: where must be 'left', 'center', or 'right'")
  end

  return { x = x, y = r.y, w = w, h = r.h }
end

local function sliceV(r, where, ratio)
  local h = r.h * ratio                        -- height of the slice
  local y = r.y                                -- default: top‐aligned

  if     where == "center" then
    y = r.y + (r.h - h) / 2
  elseif where == "bottom" then
    y = r.y + (r.h - h)
  elseif where ~= "top" then
    error("sliceV: where must be 'top', 'center', or 'bottom'")
  end

  return { x = r.x, y = y, w = r.w, h = h }
end

local function relayout(w, h)
  local g  = cfg.gutter

  -- main columns
  local leftW  = math.floor(w * cfg.leftColW  - g)
  local rightW = w - leftW - g

  -- ----- LEFT STACK --------------------------------------------------------
  local leftX  = 0
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
  sections.right = rect(leftW + g, 0, rightW, h) -- single tall red rect
end

local function drawFrame(r, color)
  lg.setColor(color)
  lg.rectangle("line", r.x, r.y, r.w, r.h)
end

Renderer.drawUI = function()
  Click.clear()
  relayout(Display.VIRTUAL_W, Display.VIRTUAL_H)

  lg.setLineWidth(cfg.lineWidth)
  local c = cfg.colors
  -- Debug rects
  drawFrame(sections.systems, c.white)
  drawFrame(sections.effects, c.blue)
  drawFrame(sections.play, c.green)
  drawFrame(sections.deck, c.yellow)
  drawFrame(sections.right, c.red)

  SystemsUI.drawSystemsPanel(sections.systems)
  HandUI.drawHand(sections.play)
  LogsUI.drawLogs(sliceH(sections.effects, "right", 0.5))
  DeckUI.drawDeck(sliceH(sections.deck, "left", 0.33))
  RAMUI.drawRAM(sliceH(sections.deck, "center", 0.33))
  ThreatUI.drawThreat(sliceV(sections.right, "top", 0.2))
  DestructorUI.drawDestructor(sliceV(sections.right, "center", 0.5))
  EndTurnUI.drawEndTurnButton(sliceV(sections.right, "bottom", 0.2))
end

return Renderer
