local cfg = require("ui.cfg")

local DeckLayout = {}

function DeckLayout.computeRect(panel)
  local pad   = cfg.deckPanel.pad
  local cardW = cfg.deckPanel.deckW
  local cardH = cfg.deckPanel.deckH
  local cardX = panel.x + pad
  local cardY = panel.y + pad
  return { x = cardX, y = cardY, w = cardW, h = cardH, angle = 0, z = 1 }
end

return DeckLayout