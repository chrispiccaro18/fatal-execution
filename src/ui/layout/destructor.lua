local cfg = require("ui.cfg")

local DestructorLayout = {}

function DestructorLayout.computeRect(panel)
  local cardW = cfg.destructorPanel.cardW
  local cardH = cfg.destructorPanel.cardH

  local centerX = panel.x + panel.w / 2
  local centerY = panel.y + panel.h / 2
  local baseX = centerX - cardW / 2
  local baseY = centerY - cardH / 2

  return { x = baseX, y = baseY, w = cardW, h = cardH }
end

return DestructorLayout