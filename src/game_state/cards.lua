-- Runtime helpers for creating instances from the registry.
-- Adds transient UI fields. Provides hydrate/strip helpers.
Const = require("const")
local copy = require("util.copy")
local Registry = require("data.cards")

local Cards = {}
local IDLE = Const.CARD_STATES.IDLE

-- Create a runtime card instance from a registry id.
-- By default this returns a FULLY REALIZED card (safe to serialize).
-- If you want the model to store only {id=...}, set `onlyId=true`.
function Cards.instantiate(id, onlyId, allocator)
  local def = assert(Registry[id], "Unknown card id: " .. tostring(id))
  local instanceId = allocator and allocator() or error("Cards.instantiate: allocator required for instanceId")


  if onlyId then
    -- Minimal instance: model stores just the id; you will look up def at use-time.
    return { id = def.id, instanceId = instanceId }
  end

  -- Realized instance: freeze values into the model (old runs won't change if defs are updated later)
  local c      = copy(def)
  c.instanceId = instanceId

  -- Transient/UI fields (these are safe to serialize, but you can strip them on save if you prefer)
  c.state      = IDLE
  c.pos        = nil -- UI coords if needed
  c.animX      = nil
  c.animY      = nil
  c.selectable = false

  return c
end

-- Hydrate a saved minimal card {id=...} into a usable runtime object by copying current registry values.
-- Use only if you choose the "id-only" model saves.
function Cards.hydrateMin(cardMin)
  local def = assert(Registry[cardMin.id], "Unknown card id: " .. tostring(cardMin.id))
  local c = copy(def)
  c.instanceId = cardMin.instanceId or "MISSING_INSTANCE"
  c.state, c.selectable, c.pos, c.animX, c.animY = IDLE, false, nil, nil, nil
  return c
end

-- Strip transient UI fields before saving, if you keep realized cards in the model.
function Cards.stripTransient(card)
  local c = copy(card)
  c.state, c.selectable, c.pos, c.animX, c.animY = nil, nil, nil, nil, nil
  return c
end

-- Convenience: bulk helpers
function Cards.instantiateMany(ids, onlyId)
  local out = {}
  for i, id in ipairs(ids) do out[i] = Cards.instantiate(id, onlyId) end
  return out
end

function Cards.hydrateManyMin(list)
  local out = {}
  for i, cardMin in ipairs(list) do out[i] = Cards.hydrateMin(cardMin) end
  return out
end

return Cards
