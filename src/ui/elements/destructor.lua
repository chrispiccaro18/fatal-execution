local Const = require("const")
local DestructorLayout = require("ui.layout.destructor")
local cfg              = require("ui.cfg")
local Card             = require("ui.elements.card")
local lg               = love.graphics

local cfgLocal = cfg.destructorPanel
local colors   = cfg.colors

local DestructorUI     = {}

function DestructorUI.drawDestructor(panel, destructorDeck, destructorNullify)
  local pad   = cfgLocal.pad
  local cardR = DestructorLayout.computeRect(panel)

  local font = cfgLocal.font

  local displayCardOffsetX = cfgLocal.displayCardOffsetX
  local displayCardOffsetY = cfgLocal.displayCardOffsetY

  -- Panel border
  lg.setColor(colors.white)
  lg.rectangle("line", panel.x, panel.y, panel.w, panel.h)

  -- Deck base card
  local centerX = panel.x + panel.w / 2
  local centerY = panel.y + panel.h / 2
  local baseX = centerX - cardR.w / 2
  local baseY = centerY - cardR.h / 2

  local deckSize = #destructorDeck

  if deckSize == 0 then
    -- Case 1: No cards in the queue, draw a rectangle with dotted lines
    lg.setColor(colors.white)
    lg.setLineStyle("rough") -- Dashed line style
    lg.rectangle("line", baseX, baseY, cardR.w, cardR.h)
    lg.setLineStyle("smooth") -- Reset line style
  elseif deckSize == 1 then
    -- Case 2: Only one card in the queue, draw that card
    local card = destructorDeck[1]
    local hasNullify = destructorNullify > 0
    Card.drawFace(card, baseX, baseY, cardR.w, cardR.h, pad, hasNullify)
  else
    local topCard = destructorDeck[1]

    -- Top of queue
    if topCard.state == "idle" then

      local previewX = baseX + displayCardOffsetX
      local previewY = baseY + displayCardOffsetY

      local hasNullify = destructorNullify > 0

      Card.drawFace(topCard, previewX, previewY, cardR.w, cardR.h, pad, hasNullify)
    end
  end

  -- Draw the count of cards in the destructorQueue
  lg.setFont(font)
  lg.setColor(colors.white)
  lg.print("Destructor Deck Size: " .. deckSize, panel.x, panel.y + panel.h + 10)

  -- Display "Destructor Nullify: X" if applicable
  if destructorNullify > 0 then
    lg.print("Destructor Nullify: " .. destructorNullify, panel.x, panel.y + panel.h + 30)
  end
end

return DestructorUI
