-- ui/elements/hand.lua
local Const  = require("const")
local cfg    = require("ui.cfg")
local Tween  = require("ui.animations.tween")
local Card   = require("ui.elements.card")
local Click  = require("ui.click")

local HandUI = {}

-- Draw a list of cards, presumably the hand.
-- The cards are expected to have their state managed externally.
function HandUI.drawHand(view, panel, hand)
  for i, card in ipairs(hand) do
    -- Get the card's position from the tweening system or the final layout anchors.
    local r, angle = Tween.rectForCard(view, card.instanceId, i)

    love.graphics.push()
    love.graphics.translate(r.x + r.w / 2, r.y + r.h / 2)
    love.graphics.rotate((angle or 0) * math.pi / 180)
    love.graphics.translate(-r.w / 2, -r.h / 2)
    Card.drawFace(card, 0, 0, r.w, r.h, cfg.handPanel.pad)
    love.graphics.pop()

    -- Register for clicks only if the card's state says it's selectable.
    if card.selectable then
      Click.register(
        Const.HIT_IDS.CARD,
        { x = r.x, y = r.y, w = r.w, h = r.h },
        { handIndex = i, instanceId = card.instanceId }
      )
    end
  end
end

return HandUI
