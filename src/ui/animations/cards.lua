local cfg            = require("ui.cfg")
local Tween          = require("ui.animations.tween")
local Card           = require("ui.elements.card")
local AnimatingCards = require("game_state.temp.animating_cards")

local AnimatingCardsUI = {}

-- This function's only job is to draw cards that are in transit
-- (i.e., in the model.animatingCards list).
function AnimatingCardsUI.draw(view, animatingCards)
  if not animatingCards or not animatingCards.order or #animatingCards.order == 0 then return end

  for id, card in AnimatingCards.iter(animatingCards) do
    local r, angle, isFallback = Tween.rectForCard(view, id)

    if isFallback then
      print("[AnimatingCardsUI.draw] Fallback rect for: ", card.name)
    end

    if r and card then
      love.graphics.push()
      love.graphics.translate(r.x + r.w / 2, r.y + r.h / 2)
      love.graphics.rotate((angle or 0) * math.pi / 180)
      love.graphics.translate(-r.w / 2, -r.h / 2)
      Card.drawFace(card, 0, 0, r.w, r.h, cfg.handPanel.pad)
      love.graphics.pop()
    end
  end
end

return AnimatingCardsUI