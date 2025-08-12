local cfg = require("ui.cfg")
local lg   = love.graphics

local DeckUI = {}

function DeckUI.drawDeck(panelRect)
  local C   = cfg.deckPanel
  local pad = C.pad

  local cardW  = C.deckW
  local cardH  = C.deckH
  local cardX  = panelRect.x + pad
  local cardY  = panelRect.y + pad
  local cardR  = {x = cardX, y = cardY, w = cardW, h = cardH}

  -- background
  lg.setColor(0,0,0,0.5)
  lg.rectangle("fill", panelRect.x, panelRect.y, panelRect.w, panelRect.h)
  -- border
  lg.setColor(1,1,1)
  lg.rectangle("line", panelRect.x, panelRect.y, panelRect.w, panelRect.h)

  -- deck sprite and count
  lg.setColor(0.2,0.2,0.8)
  lg.rectangle("fill", cardR.x, cardR.y, cardR.w, cardR.h)

  lg.setColor(1,1,1)
  lg.setFont(lg.newFont(C.fontSize))
  lg.printf(#love.gameState.deck,
            cardR.x, cardR.y + cardH/2 - C.fontSize/2,
            cardR.w, "center")

  -- label
  local labelX = cardR.x + cardW + pad
  local labelY = panelRect.y + pad
  lg.setFont(lg.newFont(C.labelFontSize))
  lg.printf("CURRENT DECK: "..#love.gameState.deck,
            labelX, labelY, panelRect.w - pad*2, "left")
end

return DeckUI
