local cfg = require("ui.cfg")
local lg  = love.graphics

local cfgLocal = cfg.ramPanel
local colors   = cfg.colors
local fonts    = cfg.fonts

local RAMUI = {}

function RAMUI.drawRAM(panel, ram)
  local pad = cfgLocal.pad
  local w = panel.w
  local h = panel.h
  local x = panel.x
  local y = panel.y

  -- Draw background and border
  lg.setColor(colors.black)
  lg.rectangle("fill", x, y, w, h)
  lg.setColor(colors.white)
  lg.rectangle("line", x, y, w, h)

  -- Draw current RAM
  lg.setFont(fonts.xLarge)
  lg.setColor(colors.lightGreen)
  lg.printf("RAM: " .. tostring(ram), x, y + pad, w, "center")
end

return RAMUI
