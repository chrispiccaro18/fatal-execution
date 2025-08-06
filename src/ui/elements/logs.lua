local cfg           = require("ui.cfg")
local Decorators    = require("ui.decorators")
local lg            = love.graphics

local LogsUI        = {
  glowTimers = {}
}

local GLOW_DURATION = 1

function LogsUI.triggerGlow(payload)
  local msg = payload.message
  LogsUI.glowTimers[msg] = GLOW_DURATION
end

function LogsUI.update(dt)
  for msg, timer in pairs(LogsUI.glowTimers) do
    timer = timer - dt
    if timer <= 0 then
      LogsUI.glowTimers[msg] = nil
    else
      LogsUI.glowTimers[msg] = timer
    end
  end
end

Decorators.register(LogsUI.update)

function LogsUI.drawLogs(rect)
  local pad      = cfg.logsPanel.pad
  local lnH      = cfg.logsPanel.lnH
  local fontSize = cfg.logsPanel.fontSize
  local logs     = love.gameState.log

  -- background
  lg.setColor(0, 0, 0, 0.50)
  lg.rectangle("fill", rect.x, rect.y, rect.w, rect.h)

  -- border
  lg.setColor(1, 1, 1)
  lg.rectangle("line", rect.x, rect.y, rect.w, rect.h)

  -- text
  local x = rect.x + pad
  local y = rect.y + pad
  lg.setFont(lg.newFont(fontSize))
  lg.printf("RECENT LOGS:", x, y, rect.w - pad * 2, "left")
  y = y + lnH

  for i = math.max(1, #logs - 10), #logs do
    local msg = logs[i]
    local timer = LogsUI.glowTimers and LogsUI.glowTimers[msg]
    if timer then
      local pct = 1 - (timer / 0.6)
      local glow = math.sin(pct * math.pi) -- 0 → 1 → 0
      -- Blend from white (1,1,1) to yellow (1,1,0)
      lg.setColor(1, 1, 1 - glow, 1)
      -- local alpha = 0.8 + 0.2 * glow
      -- lg.setColor(1, 1, 1 - glow, alpha)
    else
      lg.setColor(1, 1, 1)
    end

    lg.print(msg, x, y)
    y = y + lnH
    if y > rect.y + rect.h - lnH then break end
  end
end

return LogsUI
