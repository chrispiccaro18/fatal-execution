local cfg = require("ui.cfg")
local Decorators = require("ui.decorators")
local lg  = love.graphics

local RAMUI = {
  pulseTimer = 0,
  pulseMax   = 0.25, -- total duration of pulse
  pulseScale = 1.15  -- how large the pulse gets
}

function RAMUI.triggerPulse()
  RAMUI.pulseTimer = RAMUI.pulseMax
end

function RAMUI.update(dt)
  if RAMUI.pulseTimer > 0 then
    RAMUI.pulseTimer = RAMUI.pulseTimer - dt
  end
end

Decorators.register(RAMUI.update)

function RAMUI.drawRAM(panelRect)
  local C   = cfg.ramPanel
  local pad = C.pad

  local w = panelRect.w
  local h = panelRect.h
  local x = panelRect.x
  local y = panelRect.y

  -- Compute pulse scale
  local pulseScale = 1
  if RAMUI.pulseTimer > 0 then
    local t = RAMUI.pulseTimer / RAMUI.pulseMax
    pulseScale = 1 + (RAMUI.pulseScale - 1) * (1 - (1 - t)^2)  -- ease-out quad
  end

  local cx = x + w / 2
  local cy = y + h / 2

  lg.push()
  lg.translate(cx, cy)
  -- lg.scale(pulseScale, pulseScale)
  lg.translate(-cx, -cy)

  -- Draw background and border
  lg.setColor(0.1, 0.1, 0.1)
  lg.rectangle("fill", x, y, w, h)
  lg.setColor(1, 1, 1)
  lg.rectangle("line", x, y, w, h)

  -- Draw current RAM
  lg.setFont(lg.newFont(C.fontSize * pulseScale))
  lg.setColor(0.8, 1, 0.8)
  lg.printf("RAM: " .. tostring(love.gameState.ram), x, y + pad, w, "center")

  lg.pop()
end

return RAMUI

-- local cfg = require("ui.cfg")
-- local lg   = love.graphics

-- local RAMUI = {}

-- function RAMUI.drawRAM(rect)
--   local pad  = cfg.ramPanel.pad
--   local fontSize = cfg.ramPanel.fontSize
--   local ram = love.gameState.ram

--   -- background
--   lg.setColor(0, 0, 0, 0.50)
--   lg.rectangle("fill", rect.x, rect.y, rect.w, rect.h)

--   -- border
--   lg.setColor(1, 1, 1)
--   lg.rectangle("line", rect.x, rect.y, rect.w, rect.h)

--   -- text
--   local x  = rect.x + pad
--   local y  = rect.y + pad
--   lg.setFont(lg.newFont(fontSize))
--   lg.printf("CURRENT RAM: " .. ram, x, y, rect.w - pad*2, "left")
-- end

-- return RAMUI
