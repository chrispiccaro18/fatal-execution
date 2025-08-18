-- ui/elements/hand.lua
local Const  = require("const")
local cfg    = require("ui.cfg")
local Tween  = require("ui.animations.tween")
local Card   = require("ui.elements.card")
local Click  = require("ui.click")

local dump   = require("util.general").dump

local HandUI = {}

-- Draw a list of cards, presumably the hand.
-- The cards are expected to have their state managed externally.
function HandUI.drawHand(view, hand)
  local slots = view.anchors and view.anchors.handSlots.slots
  if not slots then return end

  for i, card in ipairs(hand) do
    if card.state == Const.CARD_STATES.IDLE then
      local slot = slots[i]
      if slot then
        local r = { x = slot.x, y = slot.y, w = slot.w, h = slot.h }
        local angle = slot.angle or 0

        love.graphics.push()
        love.graphics.translate(r.x + r.w / 2, r.y + r.h / 2)
        love.graphics.rotate(angle * math.pi / 180)
        love.graphics.translate(-r.w / 2, -r.h / 2)
        Card.drawFace(card, 0, 0, r.w, r.h, cfg.handPanel.pad)
        love.graphics.pop()

        if card.selectable then
          Click.register(
            Const.HIT_IDS.CARD,
            { x = r.x, y = r.y, w = r.w, h = r.h },
            { handIndex = i, instanceId = card.instanceId }
          )
        end
      end
    end
  end
end

return HandUI