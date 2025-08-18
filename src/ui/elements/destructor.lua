local Const            = require("const")
local DestructorLayout = require("ui.layout.destructor")
local cfg              = require("ui.cfg")
local Card             = require("ui.elements.card")
local lg               = love.graphics

local CARD_STATES      = Const.CARD_STATES
local cfgLocal         = cfg.destructorPanel
local colors           = cfg.colors

local DestructorUI     = {}

function DestructorUI.drawDestructor(panel, destructorDeck, destructorNullify)
  local pad   = cfgLocal.pad
  local font  = cfgLocal.font
  local cardR = DestructorLayout.computeRect(panel)

  -- Panel border
  lg.setColor(colors.white)
  lg.rectangle("line", panel.x, panel.y, panel.w, panel.h)

  local deckSize = #destructorDeck

  if deckSize == 0 then
    -- Case 1: No cards, draw a dotted outline at the base position
    lg.setColor(colors.white)
    lg.setLineStyle("rough")
    lg.rectangle("line", cardR.x, cardR.y, cardR.w, cardR.h)
    lg.setLineStyle("smooth")
  elseif deckSize == 1 then
    -- Case 2: One card, draw it at the base position
    local card = destructorDeck[1]
    local hasNullify = destructorNullify > 0
    Card.drawFace(card, cardR.x, cardR.y, cardR.w, cardR.h, pad, hasNullify)
  else
    -- Case 3: Multiple cards
    -- Draw the deck base as a red rectangle
    lg.setColor(colors.red)
    lg.rectangle("fill", cardR.x, cardR.y, cardR.w, cardR.h)

    -- Get the specific rect for the top card preview
    local topCard = destructorDeck[1]
    local displayCardOffsetX = cfgLocal.displayCardOffsetX
    local displayCardOffsetY = cfgLocal.displayCardOffsetY
    local previewX = cardR.x + displayCardOffsetX
    local previewY = cardR.y + displayCardOffsetY

    local hasNullify = destructorNullify > 0
    Card.drawFace(topCard, previewX, previewY, cardR.w, cardR.h, pad, hasNullify)
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
