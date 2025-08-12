local cfg = require("ui.cfg")
local lg  = love.graphics
local Effects = require("game_state.derived.effects")

local cfgLocal = cfg.effectsPanel
local colors = cfg.colors
local fonts  = cfg.fonts

local EffectsUI = {}

function EffectsUI.drawEffects(panel, model)
  local pad = cfgLocal.pad
  local lnH = cfgLocal.lnH
  local effects = Effects.collectAllActive(model)

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
  lg.printf("ENV EFFECTS:", x, y, panel.w - pad * 2, "left")
  y = y + lnH

  for _, activeEffect in ipairs(effects) do
    local source = activeEffect.source or "Unknown"
    lg.printf(source .. ": " .. Effects.describe(activeEffect.effect), x, y, panel.w - pad * 2, "left")
    y = y + lnH
  end
end

return EffectsUI