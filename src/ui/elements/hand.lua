local Const    = require("const")
local cfg      = require("ui.cfg")
local UI       = require("state.ui")
local Card     = require("ui.elements.card")
local Click    = require("ui.click")

local cfgLocal = cfg.handPanel

local HandUI   = {}

function HandUI.drawHand(view, panel, hand)
  for i, card in ipairs(hand) do
    local r, angle = UI.rectForCard(view, card.instanceId, i)

    love.graphics.push()
    love.graphics.translate(r.x + r.w / 2, r.y + r.h / 2)
    love.graphics.rotate(angle * math.pi / 180)
    love.graphics.translate(-r.w / 2, -r.h / 2)
    Card.drawFace(card, 0, 0, r.w, r.h, cfg.handPanel.pad)
    love.graphics.pop()

    -- simple AABB hit; fine for now even if rotated
    if card.selectable then -- or HandUI.isSelectable(card.instanceId) if you’re gating via UI state
      Click.register(Const.HIT_IDS.CARD, { x = r.x, y = r.y, w = r.w, h = r.h }, { handIndex = i })
    end
  end
end

-- function HandUI.drawHand(view, panel, hand)
--   local pad         = cfgLocal.pad
--   local maxSpacingX = cfgLocal.maxSpacingX
--   local cardW       = cfgLocal.cardW
--   local cardH       = cfgLocal.cardH

--   local handX       = panel.x + pad
--   local handY       = panel.y + pad
--   local handW       = panel.w - pad * 2
--   local handH       = panel.h - pad * 2

--   local spacingX    = math.min(maxSpacingX, (handW - cardW * #hand) / math.max(1, #hand - 1))

--   for i, card in ipairs(hand) do
--     if card.state == Const.CARD_STATES.IDLE then
--       local x = handX + (i - 1) * (cardW + spacingX)
--       local y = handY

--       Card.drawFace(card, x, y, cardW, cardH, pad)

--       if card.selectable then
--         Click.register(Const.HIT_IDS.CARD, { x = x, y = y, w = cardW, h = cardH }, { handIndex = i })
--       end
--     end
--   end
-- end

return HandUI
