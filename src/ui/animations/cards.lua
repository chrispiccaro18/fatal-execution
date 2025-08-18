local cfg = require("ui.cfg")
local Tween = require("ui.animations.tween")
local Card = require("ui.elements.card")
local AnimatingCards = require("game_state.temp.animating_cards")

local AnimatingCardsUI = {}

function AnimatingCardsUI.draw(view, animatingCards)
  if not animatingCards or not animatingCards.order or #animatingCards.order == 0 then return end

  for _, card in AnimatingCards.iter(animatingCards) do
    -- Use the rectForCard function which can recursively find the tween
    -- and get its interpolated position.
    local r, angle = Tween.rectForCard(view, card.instanceId)

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