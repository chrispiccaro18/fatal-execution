local cfg        = require("ui.cfg")
local HandLayout = require("ui.layout.hand")
local DeckLayout = require("ui.layout.deck")
local DestructorLayout = require("ui.layout.destructor")

local Layout     = {}

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

local function relayout(w, h, sections)
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

  sections.first      = nextRow(cfg.systemsH)
  sections.second     = nextRow(cfg.effectsH)
  sections.third     = nextRow(cfg.deckH)
  sections.fourth      = nextRow(cfg.playH)

  sections.systems    = sections.first
  sections.effects    = sliceH(sections.second, "left", 0.5)
  sections.logs       = sliceH(sections.second, "right", 0.5)
  sections.deck       = sliceH(sections.third, "left", 0.33)
  sections.ram        = sliceH(sections.third, "center", 0.33)
  sections.play       = sections.fourth

  -- RIGHT COLUMN
  sections.right      = rect(leftW + g, 0, rightW, h)

  sections.threats    = sliceV(sections.right, "top", 0.2)
  sections.destructor = sliceV(sections.right, "center", 0.5)
  sections.endTurn    = sliceV(sections.right, "bottom", 0.2)
end

function Layout.compute(W, H)
  local sections = {}
  relayout(W, H, sections)

  local handPanel = sections.play
  local deckPanel = sections.deck
  local destructorPanel = sections.destructor

  return {
    sections = sections,
    getHandLayout = function(n, hoveredIndex)
      if hoveredIndex then
        return HandLayout.getHoveredLayout(handPanel, n, hoveredIndex)
      else
        return HandLayout.computeSlots(handPanel, n)
      end
    end,
    getHandSlots = function(n) return HandLayout.computeSlots(handPanel, n) end,
    getDeckRect = function() return DeckLayout.computeRect(deckPanel) end,
    getDestructorRect = function() return DestructorLayout.computeRect(destructorPanel) end,
    getHoverOffsets = function(handSlots, hoveredIndex, panel)
      return HandLayout.computeHoverOffsets(handSlots, hoveredIndex, panel or handPanel)
    end
  }
end

return Layout
