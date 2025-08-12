local cfg      = require("ui.cfg")
local lg       = love.graphics
local Log      = require("game_state.log")

local cfgLocal = cfg.logsPanel
local colors   = cfg.colors
local fonts    = cfg.fonts

local LogsUI   = {}

function LogsUI.drawLogs(panel, allLogs)
  local pad = cfgLocal.pad
  local lnH = cfgLocal.lnH

  -- background
  lg.setColor(colors.black)
  lg.rectangle("fill", panel.x, panel.y, panel.w, panel.h)

  -- border
  lg.setColor(colors.white)
  lg.rectangle("line", panel.x, panel.y, panel.w, panel.h)

  -- text
  local x = panel.x + pad
  local y = panel.y + pad
  lg.setFont(fonts.default)
  lg.printf("RECENT LOGS:", x, y, panel.w - pad * 2, "left")
  y = y + lnH

  local visibleLogs = Log.visible(allLogs)
  for i = math.max(1, #visibleLogs - 10), #visibleLogs do
    local log = visibleLogs[i]
    local msg = log.message
    lg.printf(msg, x, y, panel.w - pad * 2, "left")
    y = y + lnH
  end
end

return LogsUI
