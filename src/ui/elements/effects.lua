local cfg       = require("ui.cfg")
-- local Decorators    = require("ui.decorators")
local Effects   = require("game_state.derived.effects")
local lg        = love.graphics

local EffectsUI = {}

function EffectsUI.drawEffects(rect)
  local pad      = cfg.effectsPanel.pad
  local lnH      = cfg.effectsPanel.lnH
  local fontSize = cfg.effectsPanel.fontSize
  local effects  = Effects.getActiveEffects(love.gameState)

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
  lg.printf("ENV EFFECTS:", x, y, rect.w - pad * 2, "left")
  y = y + lnH

  for _, activeEffect in ipairs(effects) do
    local source = activeEffect.source or "Unknown"
    local effect = activeEffect.effect or "Unknown"
    lg.printf(source .. ": " .. Effects.describe(effect), x, y, rect.w - pad * 2, "left")
    y = y + lnH
  end
end

return EffectsUI
