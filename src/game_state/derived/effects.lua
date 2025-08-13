local Const   = require("const")
local immut   = require("util.immut")

local Effects = {}

-- READ ONLY: Collect active env effects by trigger (systems that are activated + threats with matching trigger)
-- Returns a flat array of { source="Power", kind="system"|"threat", index=idx, effect=envEffect }
function Effects.collectActive(model, trigger)
  local out = {}

  -- Systems (activated only)
  for i, sys in ipairs(model.systems or {}) do
    if sys.activated and sys.envEffect and sys.envEffect.trigger == trigger then
      out[#out + 1] = {
        source = sys.name or sys.id,
        kind = Const.PLAY_EFFECT_KINDS.SYSTEM,
        index = i,
        effect = sys
            .envEffect
      }
    end
  end

  -- Threats (plural)
  for i, th in ipairs(model.threats or {}) do
    if th.envEffect and th.envEffect.trigger == trigger then
      out[#out + 1] = {
        source = th.name or th.id,
        kind = Const.PLAY_EFFECT_KINDS.THREAT,
        index = i,
        effect = th
            .envEffect
      }
    end
  end

  -- TODO: include temporary buffs/debuffs if you add them later (state.activeEffects)

  return out
end

-- Collect all active env effects (systems that are activated + threats regardless of trigger)
-- Returns a flat array of { source="Power", kind="system"|"threat", index=idx, effect=envEffect }
function Effects.collectAllActive(state)
  local out = {}

  -- Systems (activated only)
  for i, sys in ipairs(state.systems or {}) do
    if sys.activated and sys.envEffect then
      out[#out + 1] = {
        source = sys.name or sys.id,
        kind = Const.PLAY_EFFECT_KINDS.SYSTEM,
        index = i,
        effect = sys
            .envEffect
      }
    end
  end

  -- Threats (plural)
  for i, th in ipairs(state.threats or {}) do
    if th.envEffect then
      out[#out + 1] = {
        source = th.name or th.id,
        kind = Const.PLAY_EFFECT_KINDS.THREAT,
        index = i,
        effect = th
            .envEffect
      }
    end
  end

  -- TODO: include temporary buffs/debuffs if you add them later (state.activeEffects)

  return out
end

-- slices is a table like:
--   { handSize = number, ram = number, threats = array-of-threats }
-- Returns (newSlices, note)
-- note can be used for Log and UI { msg = string, tag = string, amount = number, index = number(threat index), source = string, kind = string }
function Effects.applySlices(slices, effect, ctx)
  local handSize = slices.handSize
  local ram      = slices.ram
  local threats  = slices.threats
  local note     = nil

  if effect.type == Const.EFFECTS.MODIFY_HAND_SIZE then
    local amt = effect.amount or 0
    handSize  = (handSize or 0) + amt
    note = { msg = ("Max hand size %+d → %d"):format(amt, handSize), tag = "hand_size" }

  elseif effect.type == Const.EFFECTS.GAIN_RAM then
    local delta = effect.amount or 0
    ram = (ram or 0) + delta
    note = { msg = ("Gain %d RAM"):format(delta), tag = "ram_gain", amount = delta }

  elseif effect.type == Const.EFFECTS.THREAT_TICK then
    local idx = (ctx and ctx.kind == Const.PLAY_EFFECT_KINDS.THREAT and ctx.index) or 1
    local t = threats and threats[idx]
    if t then
      local before = t.value or 0
      local amt    = effect.amount or 1
      local after  = before + amt
      if t.max and after > t.max then after = t.max end

      -- immutably replace that threat only
      local newThreats = immut.copyArray(threats or {})
      newThreats[idx] = {
        id = t.id, name = t.name,
        value = after, max = t.max,
        envEffect = t.envEffect
      }
      threats = newThreats

      note = {
        msg   = ("Threat '%s' +%d (%d/%d)"):format(t.name or t.id, amt, after, t.max or after),
        tag   = "threat_tick",
        index = idx,
        amount= amt,
      }
    else
      note = { msg = "Threat tick: invalid index", tag = "noop" }
    end

  -- elseif effect.type == Const.EFFECTS.MULTIPLY_EFFECTS then
  --   -- If you later implement a multiplier accumulator, store it in slices (optional)
  --   -- slices.effectMultiplier = (slices.effectMultiplier or 1) * (effect.multiplier or 1)
  --   note = { msg = ("Effects x%d"):format(effect.multiplier or 1), tag = "multiplier" }

  else
    note = { msg = "No-op effect: " .. tostring(effect.type), tag = "noop" }
  end

  -- Attach minimal context
  if note then
    if ctx and ctx.source then note.source = ctx.source end
    if ctx and ctx.kind   then note.kind   = ctx.kind   end
    if ctx and ctx.index  then note.index  = ctx.index  end
  end

  return {
    handSize = handSize,
    ram      = ram,
    threats  = threats,
    -- effectMultiplier = slices.effectMultiplier, -- if you add it
  }, note
end

-- Utility to pretty describe an effect (for tooltips/menus)
-- expects {
    --   type = string,
    --   trigger = string,
    --   amount = number
    -- }
function Effects.describe(effect)
  if effect.type == Const.EFFECTS.GAIN_RAM then
    return "Gain " .. (effect.amount or 0) .. " RAM at start of turn"
  elseif effect.type == Const.EFFECTS.THREAT_TICK then
    return "Threat +" .. (effect.amount or 1) .. " at end of turn"
  elseif effect.type == Const.EFFECTS.MODIFY_HAND_SIZE then
    return "Max hand size +" .. (effect.amount or 0)
  elseif effect.type == Const.EFFECTS.MULTIPLY_EFFECTS then
    return "All effects x" .. (effect.multiplier or 1)
  else
    return tostring(effect.type)
  end
end

return Effects
