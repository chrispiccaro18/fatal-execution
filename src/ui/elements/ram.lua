local cfg = require("ui.cfg")
local lg   = love.graphics

local RAMUI = {}

function RAMUI.drawRAM(rect)
  local pad  = cfg.ramPanel.pad
  local fontSize = cfg.ramPanel.fontSize
  local ram = love.gameState.ram

  -- background
  lg.setColor(0, 0, 0, 0.50)
  lg.rectangle("fill", rect.x, rect.y, rect.w, rect.h)

  -- border
  lg.setColor(1, 1, 1)
  lg.rectangle("line", rect.x, rect.y, rect.w, rect.h)

  -- text
  local x  = rect.x + pad
  local y  = rect.y + pad
  lg.setFont(lg.newFont(fontSize))
  lg.printf("CURRENT RAM: " .. ram, x, y, rect.w - pad*2, "left")
end

return RAMUI
