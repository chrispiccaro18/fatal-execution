local cfg      = require("ui.cfg")
local lg       = love.graphics

local cfgLocal = cfg.threatsPanel
local colors   = cfg.colors

local ThreatsUI = {}

function ThreatsUI.drawThreats(panel, threats)
  local pad      = cfgLocal.pad
  local font     = cfgLocal.font

  -- background
  lg.setColor(colors.black)
  lg.rectangle("fill", panel.x, panel.y, panel.w, panel.h)

  -- border
  lg.setColor(colors.white)
  lg.rectangle("line", panel.x, panel.y, panel.w, panel.h)

  -- text
  lg.setColor(colors.red)
  local x = panel.x + pad
  local y = panel.y + pad
  lg.setFont(font)
  lg.printf("THREATS:", x, y, panel.w - pad * 2, "left")
  y = y + font:getHeight()
  
  -- for each threat
  for _, threat in ipairs(threats) do
    lg.printf(threat.name .. ": " .. threat.value .. " / " .. threat.max,
              x, y, panel.w - pad * 2, "left")
    y = y + font:getHeight()
  end
end

return ThreatsUI
