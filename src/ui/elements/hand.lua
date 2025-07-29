local cfg = require("ui.cfg")
local Card = require("ui.elements.card")
local Click = require("ui.click")

local HandUI = {}

function HandUI.drawHand(panelRect)
  local C           = cfg.handPanel
  local pad         = C.pad
  local maxSpacingX = C.maxSpacingX

  local handX       = panelRect.x + pad
  local handY       = panelRect.y + pad
  local handW       = panelRect.w - pad * 2
  local handH       = panelRect.h - pad * 2

  local hand        = love.gameState.hand
  local spacingX    = math.min(maxSpacingX, (handW - C.cardW * #hand) / math.max(1, #hand - 1))

  for i, card in ipairs(hand) do
    if card.state == "idle" then
      local x = handX + (i - 1) * (C.cardW + spacingX)
      local y = handY

      Card.drawFace(card, x, y, C.cardW, C.cardH, pad)

      if card.selectable then
        Click.register("card", { x = x, y = y, w = C.cardW, h = C.cardH }, { handIndex = i })
      end
    end
  end
end

return HandUI
