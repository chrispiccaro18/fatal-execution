local Const = require("const")
local Card = require("ui.elements.card")
local UI = require("state.ui")
local lg = love.graphics
local cfg = require("ui.cfg")
local DestructorLayout = require("ui.layout.destructor")

local ShufflingDestructorUI = {}

function ShufflingDestructorUI.draw(view, panel, destructorDeck, destructorNullify)
  local elapsed = love.timer.getTime() - view.destructor.startTime
  local duration = Const.UI.ANIM.DESTRUCTOR_SHUFFLE_TIME

  local cfgLocal = cfg.destructorPanel
  local colors = cfg.colors

  local shakeAmount = cfgLocal.shuffleShakeAmount
  local shakeFrequency = cfgLocal.shuffleShakeFrequency
  local font  = cfgLocal.font

  if elapsed >= duration then
    view.destructor.isShuffling = false
  end

  local progress = elapsed / duration
  local shake = shakeAmount * math.sin(progress * math.pi) * math.sin(elapsed * shakeFrequency)
  local cardR = DestructorLayout.computeRect(panel)
  cardR.x = cardR.x + shake


  -- Panel border
  lg.setColor(colors.white)
  lg.rectangle("line", panel.x, panel.y, panel.w, panel.h)

  local deckSize = #destructorDeck

  -- Draw the deck base as a red rectangle
  lg.setColor(colors.red)
  lg.rectangle("fill", cardR.x, cardR.y, cardR.w, cardR.h)

  -- Draw the count of cards in the destructorQueue
  lg.setFont(font)
  lg.setColor(colors.white)
  lg.print("Destructor Deck Size: " .. deckSize, panel.x, panel.y + panel.h + 10)

  -- Display "Destructor Nullify: X" if applicable
  if destructorNullify > 0 then
    lg.print("Destructor Nullify: " .. destructorNullify, panel.x, panel.y + panel.h + 30)
  end
end

return ShufflingDestructorUI