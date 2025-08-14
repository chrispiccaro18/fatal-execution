local DeckLayout = require("ui.layout.deck")
local cfg        = require("ui.cfg")
local lg         = love.graphics

local cfgLocal   = cfg.deckPanel
local colors     = cfg.colors
local fonts      = cfg.fonts

local DeckUI     = {}

function DeckUI.drawDeck(panel, deck)
  local pad   = cfgLocal.pad
  local cardR = DeckLayout.computeRect(panel)

  -- background
  lg.setColor(colors.black)
  lg.rectangle("fill", panel.x, panel.y, panel.w, panel.h)
  -- border
  lg.setColor(colors.white)
  lg.rectangle("line", panel.x, panel.y, panel.w, panel.h)

  -- deck sprite and count
  lg.setColor(colors.blue)
  lg.rectangle("fill", cardR.x, cardR.y, cardR.w, cardR.h)

  lg.setColor(1, 1, 1)
  lg.setFont(fonts.big)
  lg.printf(#deck,
            cardR.x, cardR.y + cardR.h / 2 - fonts.big:getHeight() / 2,
            cardR.w, "center")

  -- label
  local labelX = cardR.x + cardR.w + pad
  local labelY = panel.y + pad
  lg.setFont(fonts.big)
  lg.printf("CURRENT DECK: " .. #deck,
            labelX, labelY, panel.w - pad * 2, "left")
end

return DeckUI
