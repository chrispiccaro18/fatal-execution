local Const = require("const")
local Log = require("game_state.log")
local Decorators = require("ui.decorators")

local Effects = {}

function Effects.resolveActiveEffects(state, trigger)
  local effects = {}

  -- Collect system effects
  for _, sys in ipairs(state.systems) do
    if sys.activated and sys.envEffect and sys.envEffect.trigger == trigger then
      table.insert(effects, sys.envEffect)
    end
  end

  -- Collect threat effects
  if state.threat.envEffect and state.threat.envEffect.trigger == trigger then
    table.insert(effects, state.threat.envEffect)
  end

  -- Collect any card-based or temporary effects here

  -- Apply them
  for _, effect in ipairs(effects) do
    state = Effects.applyEffect(state, effect)
  end

  return state
end

function Effects.applyEffect(state, effect)
  if effect.type == Const.EFFECTS.MODIFY_HAND_SIZE then
    state.handSize = (state.handSize) + effect.amount
    state = Log.addEntry(state,
      "Max hand size increased by " .. effect.amount .. " to " .. state.player.maxHandSize)
  elseif effect.type == Const.EFFECTS.GAIN_RAM then
    state.ram = state.ram + effect.amount
    Decorators.emit("ramPulse")
  -- elseif effect.type == Const.EFFECTS.MULTIPLY_EFFECTS then
  --   state.effectMultiplier = effect.multiplier
  elseif effect.type == Const.EFFECTS.THREAT_TICK then
    state.threat.value = state.threat.value + (effect.amount or 1)
    state = Log.addEntry(state, "Threat ticks up by " .. (effect.amount or 1))
    Decorators.emit("threatPulse")
  end

  return state
end

function Effects.getActiveEffects(state)
  local active = {}

  for _, sys in ipairs(state.systems) do
    if sys.progress >= sys.required and sys.envEffect then
      table.insert(active, {
        source = sys.name,
        effect = sys.envEffect
      })
    end
  end

  if state.threat and state.threat.envEffect then
    table.insert(active, {
      source = state.threat.name,
      effect = state.threat.envEffect
    })
  end

  -- optional: include temporary effects
  -- for _, eff in ipairs(state.activeEffects or {}) do ... end

  return active
end

function Effects.describe(effect)
  if effect.type == Const.EFFECTS.GAIN_RAM then
    return "Gain " .. effect.amount .. " RAM at start of turn"
  elseif effect.type == Const.EFFECTS.THREAT_TICK then
    return "Threat level +" .. (effect.amount or 1) .. " at end of turn"
  elseif effect.type == Const.EFFECTS.MODIFY_HAND_SIZE then
    return "Max hand size +" .. effect.amount
  elseif effect.type == Const.EFFECTS.MULTIPLY_EFFECTS then
    return "All effects multiplied by " .. effect.multiplier
  end
end

return Effects
