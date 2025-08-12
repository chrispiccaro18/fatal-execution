local cfg      = require("ui.cfg")
local lg       = love.graphics

local colors   = cfg.colors

local Card = {}

function Card.drawFace(card, x, y, w, h, pad, hasNullify)
  pad = pad or 6
  hasNullify = hasNullify or false
  local lineH = cfg.handPanel.fontSize
  local textY = y + pad

  lg.setColor(colors.cardFaceGray)
  lg.rectangle("fill", x, y, w, h)

  lg.setColor(colors.black)
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
    local amount = ""
    if e.amount then
      amount = e.amount
    end
    lg.printf("Play: " .. e.type .. " " .. amount, x + pad, textY, w - pad * 2, "center")
    textY = textY + lineH
  end

  -- On Discard effect (optional)
  if card.onDiscard then
    local discardEffect = card.onDiscard
    local discardText = "On Discard: " .. discardEffect.type
    if discardEffect.amount then
      discardText = discardText .. " " .. discardEffect.amount
    end
    lg.printf(discardText, x + pad, textY, w - pad * 2, "center")
    textY = textY + lineH
  end

  -- Destructor effect (optional)
  if card.destructorEffect then
    local d = card.destructorEffect
    local amount = ""
    if d.amount then
      amount = d.amount
    end
    lg.printf("Destructor: " .. d.type .. " " .. amount, x + pad, textY + lineH, w - pad * 2, "center")
  end

  lg.setColor(1, 1, 1)
  if hasNullify then
    lg.setColor(colors.yellow)
  end
  lg.rectangle("line", x, y, w, h)
end

return Card