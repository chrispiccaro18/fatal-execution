local Const = require("const")
local cfg   = require("ui.cfg")
local UI    = require("state.ui")
local Click = require("ui.click")
local Card  = require("ui.elements.card") -- This require is necessary

local HandUI = {}

local function drawCard(view, card, handIndex)
  local r = UI.getCardInHandRect(view, handIndex)
  local angle = r.angle or 0

  love.graphics.push()
  love.graphics.translate(r.x + r.w / 2, r.y + r.h / 2)
  love.graphics.rotate(angle * math.pi / 180)
  love.graphics.translate(-r.w / 2, -r.h / 2)
  Card.drawFace(card, 0, 0, r.w, r.h, cfg.handPanel.pad)
  love.graphics.pop()

  if card.selectable then
    Click.register(
      Const.HIT_IDS.CARD,
      { x = r.x, y = r.y, w = r.w, h = r.h },
      { handIndex = handIndex, instanceId = card.instanceId }
    )
  end
end

local function getDrawOrder(view, hand)
  local order = {}
  local hoveredIndex = view.hover.currentHandIndex
  local animating = {}

  -- Collect animating indices
  for i, _ in pairs(view.hover.animating or {}) do
    animating[i] = true
  end

  -- 1. Statics: not animating, not hovered
  for i = 1, #hand do
    if not animating[i] and i ~= hoveredIndex then
      table.insert(order, i)
    end
  end

  -- 2. Animating
  for i, _ in pairs(view.hover.animating or {}) do
    table.insert(order, i)
  end

  -- 3. Hovered
  if hoveredIndex then
    table.insert(order, hoveredIndex)
  end

  return order
end

function HandUI.drawHand(view, hand)
  if not hand then return end

  local drawOrder = getDrawOrder(view, hand)
  for _, i in ipairs(drawOrder) do
    local card = hand[i]
    if card then
      drawCard(view, card, i)
    end
  end
end

return HandUI
