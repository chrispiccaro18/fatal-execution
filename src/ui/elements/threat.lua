local cfg = require("ui.cfg")
local lg   = love.graphics

local ThreatUI = {}

function ThreatUI.drawThreat(rect)
  local pad  = cfg.threatPanel.pad
  local fontSize = cfg.threatPanel.fontSize
  local threat = love.gameState.threat

  -- background
  -- lg.setColor(0, 0, 0, 0.50)
  -- lg.rectangle("fill", rect.x, rect.y, rect.w, rect.h)

  -- border
  lg.setColor(1, 1, 1)
  lg.rectangle("line", rect.x, rect.y, rect.w, rect.h)

  -- text
  lg.setColor(1, 0, 0)
  local x  = rect.x + pad
  local y  = rect.y + pad
  lg.setFont(lg.newFont(fontSize))
  lg.printf("CURRENT THREAT: " .. threat.value .. " / " .. threat.max,
            x, y, rect.w - pad*2, "left")
end

return ThreatUI
