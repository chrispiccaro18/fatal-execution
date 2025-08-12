local Const    = require("const")
local cfg      = require("ui.cfg")
local Card     = require("ui.elements.card")
local Click    = require("ui.click")

local cfgLocal = cfg.handPanel

local HandUI   = {}

function HandUI.drawHand(panel, hand)
  local pad         = cfgLocal.pad
  local maxSpacingX = cfgLocal.maxSpacingX
  local cardW       = cfgLocal.cardW
  local cardH       = cfgLocal.cardH

  local handX       = panel.x + pad
  local handY       = panel.y + pad
  local handW       = panel.w - pad * 2
  local handH       = panel.h - pad * 2

  local spacingX    = math.min(maxSpacingX, (handW - cardW * #hand) / math.max(1, #hand - 1))

  for i, card in ipairs(hand) do
    if card.state == Const.CARD_STATES.IDLE then
      local x = handX + (i - 1) * (cardW + spacingX)
      local y = handY

      Card.drawFace(card, x, y, cardW, cardH, pad)

      if card.selectable then
        Click.register("card", { x = x, y = y, w = cardW, h = cardH }, { handIndex = i })
      end
    end
  end
end

return HandUI
