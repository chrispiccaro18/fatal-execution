local cfg = require("ui.cfg")
local Click = require("ui.click")
local lg   = love.graphics

local HandUI = {}

function HandUI.drawHand(panelRect)
  local C   = cfg.handPanel
  local pad = C.pad
  local maxSpacingX = C.maxSpacingX

  local handX  = panelRect.x + pad
  local handY  = panelRect.y + pad
  local handW  = panelRect.w - pad * 2
  local handH  = panelRect.h - pad * 2
  -- local handR  = {x = handX, y = handY, w = handW, h = handH}

  -- draw each card in the hand
  -- calculate spacing based on number of cards
  local numCards = #love.gameState.hand
  local spacingX = math.min(maxSpacingX, (handW - C.cardW * numCards) / (numCards - 1))
  for i, card in ipairs(love.gameState.hand) do
    local xOffset = (i - 1) * (C.cardW + spacingX)

    local cardR = {
      x = handX + xOffset,
      y = handY,
      w = C.cardW,
      h = C.cardH
    }
    lg.setColor(0.8,0.8,0.8) -- light gray for the card background
    lg.rectangle("fill", cardR.x, cardR.y, cardR.w, cardR.h)

    lg.setColor(0,0,0) -- black text
    -- interior border
    lg.rectangle("line", cardR.x, cardR.y, cardR.w, cardR.h)
    lg.setFont(lg.newFont(C.fontSize))
    lg.printf(card.name,
              cardR.x + pad,
              cardR.y + pad,
              cardR.w - pad*2,
              "center")
    lg.printf("Cost: " .. card.cost,
              cardR.x + pad,
              cardR.y + pad + C.fontSize,
              cardR.w - pad*2,
              "center")
    lg.printf("Play Effect: " .. (card.playEffect.type or "None") .. " " .. (card.playEffect.amount or ""),
              cardR.x + pad,
              cardR.y + pad + C.fontSize * 2,
              cardR.w - pad*2,
              "center")
    lg.printf("Destructor Effect: " .. (card.destructorEffect.type or "None") .. " " .. (card.destructorEffect.amount or ""),
              cardR.x + pad,
              cardR.y + pad + C.fontSize * 3,
              cardR.w - pad*2,
              "center")

    if card.selectable then
      Click.register("card", cardR, { handIndex = i })
    end
  end
end

return HandUI
