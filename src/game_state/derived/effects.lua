local Const   = require("const")
local copy    = require("util.copy")

local Effects = {}

-- Collect active env effects by trigger (systems that are activated + threats with matching trigger)
-- Returns a flat array of { source="Power", kind="system"|"threat", index=idx, effect=envEffect }
function Effects.collectActive(state, trigger)
  local out = {}

  -- Systems (activated only)
  for i, sys in ipairs(state.systems or {}) do
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
  for i, th in ipairs(state.threats or {}) do
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

-- Apply ONE effect and return a new state + a tiny, UI-agnostic "note" for logging/UIs.
-- The note is a structured description your TaskRunner can turn into Log/UI intents.
function Effects.apply(state, effect, ctx)
  -- ctx can include fields like {source="Power", kind="system"|"threat", index=1}
  local s = copy(state)
  local note = nil

  if effect.type == Const.EFFECTS.MODIFY_HAND_SIZE then
    local before = s.handSize
    s.handSize = (s.handSize or 0) + (effect.amount or 0)
    note = { msg = ("Max hand size %+d → %d"):format(effect.amount or 0, s.handSize), tag = "hand_size" }
  elseif effect.type == Const.EFFECTS.GAIN_RAM then
    local delta = effect.amount or 0
    s.ram = (s.ram or 0) + delta
    note = { msg = ("Gain %d RAM"):format(delta), tag = "ram_gain", amount = delta }
  elseif effect.type == Const.EFFECTS.THREAT_TICK then
    -- You choose which threat index to tick in the caller.
    -- If ctx.kind=="threat" and ctx.index set, tick that threat, else default to 1.
    local idx = (ctx and ctx.kind == Const.PLAY_EFFECT_KINDS.THREAT and ctx.index) or 1
    local th = s.threats and s.threats[idx]
    if th then
      local before = th.value or 0
      local amt = effect.amount or 1
      local after = before + amt
      if after > th.max then after = th.max end
      -- write back as a shallow update
      local threats = {}
      for i, t in ipairs(s.threats) do
        if i ~= idx then
          threats[i] = t
        else
          threats[i] = { id = t.id, name = t.name, value = after, max = t.max, envEffect = t.envEffect }
        end
      end
      s.threats = threats
      note = {
        msg = ("Threat '%s' +%d (%d/%d)"):format(th.name or th.id, amt, after, th.max),
        tag = "threat_tick",
        index =
            idx,
        amount = amt
      }
    end
  elseif effect.type == Const.EFFECTS.MULTIPLY_EFFECTS then
    -- Example hook: store a multiplier on state for the *next* resolution step.
    -- Caller should decide how/when to consume this.
    s.effectMultiplier = (s.effectMultiplier or 1) * (effect.multiplier or 1)
    note = { msg = ("Effects x%d"):format(effect.multiplier or 1), tag = "multiplier" }
  else
    -- Unknown/no-op effect types are allowed; return state unchanged.
    note = { msg = "No-op effect: " .. tostring(effect.type), tag = "noop" }
  end

  -- Attach minimal context to note so the UI/logger knows source/trigger.
  if note then
    if ctx and ctx.source then note.source = ctx.source end
    if ctx and ctx.kind then note.kind = ctx.kind end
    if ctx and ctx.index then note.index = ctx.index end
  end

  return s, note
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
