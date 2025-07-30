local cfg          = require("ui.cfg")
local Card         = require("ui.elements.card")
local lg           = love.graphics

local DestructorUI = {}

function DestructorUI.drawDestructor(panelRect)
  local C     = cfg.destructorPanel
  local pad   = C.pad
  local cardW = C.cardW
  local cardH = C.cardH

  -- Panel border
  lg.setColor(1, 1, 1)
  lg.rectangle("line", panelRect.x, panelRect.y, panelRect.w, panelRect.h)

  -- Deck base card
  local centerX = panelRect.x + panelRect.w / 2
  local centerY = panelRect.y + panelRect.h / 2
  local baseX = centerX - cardW / 2
  local baseY = centerY - cardH / 2

  lg.setColor(0.8, 0.2, 0.2)
  lg.rectangle("fill", baseX, baseY, cardW, cardH)

  -- Top of queue
  if #love.gameState.destructorQueue > 0 and love.gameState.destructorQueue[1].state == "idle" then
    local card = love.gameState.destructorQueue[1]
    local offsetX = C.displayCardOffsetX
    local offsetY = C.displayCardOffsetY
    local previewX = baseX + offsetX
    local previewY = baseY + offsetY

    Card.drawFace(card, previewX, previewY, cardW, cardH, pad)
  end
end

return DestructorUI

-- function DestructorUI.drawDestructor(panelRect)
--   local C   = cfg.destructorPanel
--   local pad = C.pad

--   local cardW  = C.cardW
--   local cardH  = C.cardH
--   -- center deck in panel
--   local deckX = panelRect.x + (panelRect.w - cardW) / 2
--   local deckY = panelRect.y + (panelRect.h - cardH) / 2


--   -- background
--   -- lg.setColor(0,0,0,0.5)
--   -- lg.rectangle("fill", panelRect.x, panelRect.y, panelRect.w, panelRect.h)

--   -- border
--   lg.setColor(1,1,1)
--   lg.rectangle("line", panelRect.x, panelRect.y, panelRect.w, panelRect.h)

--   -- draw destructor deck as red rectangle
--   lg.setColor(0.8, 0.2, 0.2) -- Red color for the destructor deck
--   lg.rectangle("fill", deckX, deckY, cardW, cardH)

--   -- draw the first card in the destructor queue if it exists
--   if #love.gameState.destructorQueue > 0 then
--     -- display first card with offsetX and offsetY
--     local offsetX = C.displayCardOffsetX
--     local offsetY = C.displayCardOffsetY
--     local cardX = deckX + offsetX
--     local cardY = deckY + offsetY

--     local firstCard = love.gameState.destructorQueue[1]
--     lg.setColor(0.8,0.8,0.8) -- light gray for the card background
--     lg.rectangle("fill", cardX, cardY, cardW, cardH)

--     lg.setColor(0,0,0) -- black text
--     lg.setFont(lg.newFont(C.fontSize))
--     lg.printf(firstCard.name,
--               cardX + pad,
--               cardY + pad,
--               cardW - pad*2,
--               "center")
--     lg.printf("Destructor Effect: " .. (firstCard.destructorEffect.type or "None") .. " " .. (firstCard.destructorEffect.amount or ""),
--               cardX + pad,
--               cardY + pad + C.fontSize,
--               cardW - pad*2,
--               "center")
--   end
-- end

-- return DestructorUI
