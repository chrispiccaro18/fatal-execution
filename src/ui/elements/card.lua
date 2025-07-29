local cfg = require("ui.cfg")
local lg  = love.graphics

local Card = {}

function Card.drawFace(card, x, y, w, h, pad)
  pad = pad or 6
  local lineH = cfg.handPanel.fontSize
  local textY = y + pad

  lg.setColor(0.8, 0.8, 0.8)
  lg.rectangle("fill", x, y, w, h)

  lg.setColor(0, 0, 0)
  lg.setFont(lg.newFont(lineH))

  -- Name
  lg.printf(card.name, x + pad, textY, w - pad * 2, "center")
  textY = textY + lineH

  -- Cost (optional)
  if card.cost then
    lg.printf("Cost: " .. card.cost, x + pad, textY, w - pad * 2, "center")
    textY = textY + lineH
  end

  -- Play effect (optional)
  if card.playEffect then
    local e = card.playEffect
    lg.printf("Play: " .. e.type .. " " .. e.amount, x + pad, textY, w - pad * 2, "center")
    textY = textY + lineH
  end

  -- Destructor effect (optional)
  if card.destructorEffect then
    local d = card.destructorEffect
    lg.printf("Destructor: " .. d.type .. " " .. d.amount, x + pad, textY, w - pad * 2, "center")
  end

  lg.setColor(1, 1, 1)
  lg.rectangle("line", x, y, w, h)
end

return Card
