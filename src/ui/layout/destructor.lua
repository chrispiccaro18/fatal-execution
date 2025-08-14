local cfg = require("ui.cfg")

local DestructorLayout = {}

function DestructorLayout.computeRect(panel)
  local pad   = cfg.destructorPanel.pad
  local cardW = cfg.destructorPanel.cardW
  local cardH = cfg.destructorPanel.cardH
  local cardX = panel.x + pad
  local cardY = panel.y + pad
  return { x = cardX, y = cardY, w = cardW, h = cardH, angle = 0, z = 1 }
end

return DestructorLayout