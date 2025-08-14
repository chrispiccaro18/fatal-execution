-- ui/elements/hand.lua
local Const  = require("const")
local cfg    = require("ui.cfg")
local Tween  = require("ui.animations.tween")
local Card   = require("ui.elements.card")
local Click  = require("ui.click")

local HandUI = { state = {} }  -- [instanceId] = { state="animating"|"idle", selectable=bool }

-- Merge-style setter
function HandUI.set(id, patch)
  local cur = HandUI.state[id] or {}
  local nxt = {}
  for k,v in pairs(cur) do nxt[k]=v end
  for k,v in pairs(patch) do nxt[k]=v end
  HandUI.state[id] = nxt
end

function HandUI.clear(id) HandUI.state[id] = nil end

function HandUI.isSelectable(id)
  local u = HandUI.state[id]
  return u and u.selectable == true
end

function HandUI.drawHand(view, panel, hand)
  for i, card in ipairs(hand) do
    -- IMPORTANT: use instanceId
    local r, angle = Tween.rectForCard(view, card.instanceId, i)

    love.graphics.push()
    love.graphics.translate(r.x + r.w/2, r.y + r.h/2)
    love.graphics.rotate((angle or 0) * math.pi/180)
    love.graphics.translate(-r.w/2, -r.h/2)
    Card.drawFace(card, 0, 0, r.w, r.h, cfg.handPanel.pad)
    love.graphics.pop()

    -- Hit-test: gate on HandUI state, not model field
    if HandUI.isSelectable(card.instanceId) then
      Click.register(
        Const.HIT_IDS.CARD,
        { x = r.x, y = r.y, w = r.w, h = r.h },
        { handIndex = i, instanceId = card.instanceId }
      )
    end
  end
end

return HandUI
