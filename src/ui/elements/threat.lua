local cfg      = require("ui.cfg")
local Decorators = require("ui.decorators")
local lg       = love.graphics

local ThreatUI = {
  pulseTimer = 0,
  pulseMax   = 0.25, -- total duration of pulse
  pulseScale = 1.15  -- how large the pulse gets
}

function ThreatUI.triggerPulse()
  ThreatUI.pulseTimer = ThreatUI.pulseMax
end

function ThreatUI.update(dt)
  if ThreatUI.pulseTimer > 0 then
    ThreatUI.pulseTimer = ThreatUI.pulseTimer - dt
  end
end

Decorators.register(ThreatUI.update)

function ThreatUI.drawThreat(rect)
  local pad      = cfg.threatPanel.pad
  local fontSize = cfg.threatPanel.fontSize
  local threat   = love.gameState.threat

  -- Compute pulse scale
  local pulseScale = 1
  if ThreatUI.pulseTimer > 0 then
    local t = ThreatUI.pulseTimer / ThreatUI.pulseMax
    pulseScale = 1 + (ThreatUI.pulseScale - 1) * (1 - (1 - t)^2)  -- ease-out quad
  end

  -- background
  -- lg.setColor(0, 0, 0, 0.50)
  -- lg.rectangle("fill", rect.x, rect.y, rect.w, rect.h)

  -- border
  lg.setColor(1, 1, 1)
  lg.rectangle("line", rect.x, rect.y, rect.w, rect.h)

  -- text
  lg.setColor(1, 0, 0)
  local x = rect.x + pad
  local y = rect.y + pad
  lg.setFont(lg.newFont(fontSize * pulseScale))
  lg.printf("CURRENT THREAT: " .. threat.value .. " / " .. threat.max,
            x, y, rect.w - pad * 2, "left")
end

return ThreatUI
