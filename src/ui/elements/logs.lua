local cfg = require("ui.cfg")
local lg   = love.graphics

local LogsUI = {}

function LogsUI.drawLogs(rect)
  local pad  = cfg.logsPanel.pad
  local lnH  = cfg.logsPanel.lnH
  local fontSize = cfg.logsPanel.fontSize
  local logs = love.gameState.log
  local env  = love.gameState.envEffect

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
  lg.printf("ENV EFFECT: "..env, x, y, rect.w - pad*2, "left")
  y = y + lnH
  lg.printf("RECENT LOGS:", x, y, rect.w - pad*2, "left")
  y = y + lnH

  for i = math.max(1, #logs-10), #logs do
    lg.print(logs[i], x, y)
    y = y + lnH
    if y > rect.y + rect.h - lnH then break end -- stop if we run out of space
  end
end

return LogsUI
