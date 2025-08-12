local Const     = require("const")
local cfg       = require("ui.cfg")
local lg        = love.graphics
local Click     = require("ui.click")

local cfgLocal  = cfg.endTurnPanel
local colors    = cfg.colors

local EndTurnUI = {}

function EndTurnUI.drawEndTurnButton(panel)
  local rect = {
    x = panel.x + (panel.w - cfgLocal.buttonW) / 2,
    y = panel.y + (panel.h - cfgLocal.buttonH) / 2,
    w = cfgLocal.buttonW,
    h = cfgLocal.buttonH,
  }

  local buttonColors = {
    bg = colors.darkGreen,
    border = colors.white,
    text = colors.white,
  }

  Click.addButton(Const.END_TURN_BUTTON.ID, rect, Const.END_TURN_BUTTON.LABEL, buttonColors, cfgLocal.fontSize)
end

return EndTurnUI
