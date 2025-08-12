local cfg = require("ui.cfg")
local Decorators = require("ui.decorators")
local lg  = love.graphics

local Card = {
  shakeTimers = {}
}

local SHAKE_DURATION = 0.3

function Card.triggerShake(cardId)
  Card.shakeTimers[cardId] = SHAKE_DURATION
end

function Card.update(dt)
  for cardId, timer in pairs(Card.shakeTimers) do
    timer = timer - dt
    if timer <= 0 then
      Card.shakeTimers[cardId] = nil
    else
      Card.shakeTimers[cardId] = timer
    end
  end
end

Decorators.register(Card.update)

function Card.drawFace(card, x, y, w, h, pad, hasNullify)
  pad = pad or 6
  hasNullify = hasNullify or false
  local lineH = cfg.handPanel.fontSize
  local textY = y + pad

    -- Apply shake offset if the card is shaking
  local shakeOffset = 0
  if Card.shakeTimers[card.name] then
    local shakeProgress = Card.shakeTimers[card.name] / SHAKE_DURATION
    shakeOffset = math.sin(love.timer.getTime() * 20) * 5 * shakeProgress
  end

  x = x + shakeOffset

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
    lg.setColor(cfg.colors.yellow)
  end
  lg.rectangle("line", x, y, w, h)
end

return Card
