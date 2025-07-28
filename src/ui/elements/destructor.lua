local cfg = require("ui.cfg")
local lg   = love.graphics

local DestructorUI = {}

function DestructorUI.drawDestructor(panelRect)
  local C   = cfg.destructorPanel
  local pad = C.pad

  local cardW  = C.cardW
  local cardH  = C.cardH
  -- center deck in panel
  local deckX = panelRect.x + (panelRect.w - cardW) / 2
  local deckY = panelRect.y + (panelRect.h - cardH) / 2

  
  -- background
  -- lg.setColor(0,0,0,0.5)
  -- lg.rectangle("fill", panelRect.x, panelRect.y, panelRect.w, panelRect.h)
  
  -- border
  lg.setColor(1,1,1)
  lg.rectangle("line", panelRect.x, panelRect.y, panelRect.w, panelRect.h)

  -- draw destructor deck as red rectangle
  lg.setColor(0.8, 0.2, 0.2) -- Red color for the destructor deck
  lg.rectangle("fill", deckX, deckY, cardW, cardH)
  
  -- draw the first card in the destructor queue if it exists
  if #love.gameState.destructorQueue > 0 then
    -- display first card with offsetX and offsetY
    local offsetX = C.displayCardOffsetX
    local offsetY = C.displayCardOffsetY
    local cardX = deckX + offsetX
    local cardY = deckY + offsetY

    local firstCard = love.gameState.destructorQueue[1]
    lg.setColor(0.8,0.8,0.8) -- light gray for the card background
    lg.rectangle("fill", cardX, cardY, cardW, cardH)

    lg.setColor(0,0,0) -- black text
    lg.setFont(lg.newFont(C.fontSize))
    lg.printf(firstCard.name,
              cardX + pad,
              cardY + pad,
              cardW - pad*2,
              "center")
    lg.printf("Destructor Effect: " .. (firstCard.destructorEffect.type or "None") .. " " .. (firstCard.destructorEffect.amount or ""),
              cardX + pad,
              cardY + pad + C.fontSize,
              cardW - pad*2,
              "center")
  end
end

return DestructorUI

--   -- Draw the destructor deck
--   local destructorX = handX + (#love.gameState.hand * (cardWidth + cardSpacing)) +
--       20                                -- Position to the right of the hand
--   local destructorY = handY
--   love.graphics.setColor(0.8, 0.2, 0.2) -- Red color for the destructor deck
--   love.graphics.rectangle("fill", destructorX, destructorY, cardWidth, cardHeight)

--   -- Display the first card in the destructor deck
--   if #love.gameState.destructorQueue > 0 then
--     local firstCard = love.gameState.destructorQueue[1]
--     -- love.graphics.setColor(0.8, 0.8, 0.8) -- Light gray for the card background
--     love.graphics.rectangle("fill", destructorX, destructorY, cardWidth, cardHeight)

--     love.graphics.setColor(0, 0, 0) -- Black text
--     love.graphics.printf(firstCard.name, destructorX + 5, destructorY + 10, cardWidth - 10, "center")
--     love.graphics.printf("Effect: " .. firstCard.destructorEffect.type .. " " .. firstCard.destructorEffect.amount,
--                          destructorX + 5, destructorY + 50, cardWidth - 10, "center")
--   end