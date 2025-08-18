local copy      = require("util.copy")
local Immutable = require("util.immut")
local floor     = math.floor

local AnimatingCards = {}

-- Insert into a new array immutably
local function arrayInsert(a, pos, v)
  local out = Immutable.copyArray(a)
  table.insert(out, pos, v)
  return out
end

-- Compare two ids by (handIndex via state.pos, zBoost via state.zBoost, then id)
local function less(state, idA, idB)
  if idA == nil then return false end
  if idB == nil then return true end
  local ah = state.pos[idA] or 0
  local bh = state.pos[idB] or 0
  if ah ~= bh then return ah < bh end

  local az = state.zBoost[idA] or 0
  local bz = state.zBoost[idB] or 0
  if az ~= bz then return az < bz end

  return tostring(idA) < tostring(idB)
end

-- Local minimal bubble to fix ordering around a single index (mutates the given arrays)
local function resortAround(state, order, indexOf, idx)
  local n = #order
  if not idx or idx < 1 or idx > n then return order, indexOf end

  -- bubble right
  while idx < n and not less(state, order[idx], order[idx+1]) do
    order[idx], order[idx+1] = order[idx+1], order[idx]
    indexOf[order[idx]]      = idx
    indexOf[order[idx+1]]    = idx + 1
    idx = idx + 1
  end
  -- bubble left
  while idx > 1 and not less(state, order[idx-1], order[idx]) do
    order[idx], order[idx-1] = order[idx-1], order[idx]
    indexOf[order[idx]]      = idx
    indexOf[order[idx-1]]    = idx - 1
    idx = idx - 1
  end
  return order, indexOf
end

-- Binary search insert position for a NEW id, using given handIndex/zBoost
local function binaryInsertPosForNew(state, targetId, targetHandIndex, targetZ)
  local lo, hi = 1, #state.order
  while lo <= hi do
    local mid   = floor((lo + hi) / 2) -- Lua 5.1 safe
    local midId = state.order[mid]
    local mh    = state.pos[midId] or 0
    local th    = targetHandIndex or 0
    if th ~= mh then
      if th < mh then hi = mid - 1 else lo = mid + 1 end
    else
      local mz = state.zBoost[midId] or 0
      local tz = targetZ or 0
      if tz ~= mz then
        if tz < mz then hi = mid - 1 else lo = mid + 1 end
      else
        local mk, tk = tostring(midId), tostring(targetId)
        if tk < mk then hi = mid - 1 else lo = mid + 1 end
      end
    end
  end
  return lo
end

-- ---------- API ----------

function AnimatingCards.empty()
  return { byId = {}, order = {}, indexOf = {}, pos = {}, zBoost = {} }
end

-- Add (or replace) a card. handIndex is REQUIRED and stored in state.pos.
-- Optional zBoost can be provided at add-time.
function AnimatingCards.add(state, card, handIndex)
  assert(card and card.instanceId, "card.instanceId required")
  assert(handIndex ~= nil, "handIndex required")

  local id      = card.instanceId
  local existed = state.byId[id] ~= nil

  local byId   = copy(state.byId)
  local order  = Immutable.copyArray(state.order)
  local index  = copy(state.indexOf)
  local pos    = copy(state.pos)
  local zBoost = copy(state.zBoost)

  byId[id]   = copy(card)
  pos[id]    = handIndex

  if existed then
    -- Item already in order; nudge to correct spot.
    local idx = index[id]
    resortAround({ order = order, pos = pos, zBoost = zBoost }, order, index, idx)
  else
    local ins = (#order == 0)
      and 1
      or binaryInsertPosForNew({ order = order, pos = pos, zBoost = zBoost }, id, handIndex, zBoost[id])
    order = arrayInsert(order, ins, id)
    for i = ins, #order do index[order[i]] = i end
  end

  return { byId = byId, order = order, indexOf = index, pos = pos, zBoost = zBoost }
end

-- Remove by instanceId.
function AnimatingCards.remove(state, id)
  local idx = state.indexOf[id]
  if not idx then return state end

  local byId   = copy(state.byId)
  local order  = Immutable.copyArray(state.order)
  local index  = copy(state.indexOf)
  local pos    = copy(state.pos)
  local zBoost = copy(state.zBoost)

  local last = #order
  if idx ~= last then
    order[idx] = order[last]
    index[order[idx]] = idx
  end
  order[last]  = nil
  index[id]    = nil
  byId[id]     = nil
  pos[id]      = nil
  zBoost[id]   = nil

  return { byId = byId, order = order, indexOf = index, pos = pos, zBoost = zBoost }
end

-- Update a card’s logical handIndex (stored in state.pos).
function AnimatingCards.setHandIndex(state, id, newHandIndex)
  if state.pos[id] == nil or state.pos[id] == newHandIndex then return state end

  local byId   = copy(state.byId)
  local order  = Immutable.copyArray(state.order)
  local index  = copy(state.indexOf)
  local pos    = copy(state.pos)
  local zBoost = copy(state.zBoost)

  pos[id] = newHandIndex
  resortAround({ order = order, pos = pos, zBoost = zBoost }, order, index, index[id])

  return { byId = byId, order = order, indexOf = index, pos = pos, zBoost = zBoost }
end

-- Temporary visual lift (does not change handIndex).
function AnimatingCards.setZBoost(state, id, z)
  local current = state.zBoost[id] or 0
  local nextZ   = z or 0
  if current == nextZ or not state.indexOf[id] then return state end

  local byId   = copy(state.byId)
  local order  = Immutable.copyArray(state.order)
  local index  = copy(state.indexOf)
  local pos    = copy(state.pos)
  local zBoost = copy(state.zBoost)

  zBoost[id] = nextZ
  resortAround({ order = order, pos = pos, zBoost = zBoost }, order, index, index[id])

  return { byId = byId, order = order, indexOf = index, pos = pos, zBoost = zBoost }
end

-- Full stable re-sort (useful after many updates).
function AnimatingCards.resortAll(state)
  local byId   = copy(state.byId)
  local order  = Immutable.copyArray(state.order)
  local pos    = copy(state.pos)
  local zBoost = copy(state.zBoost)

  table.sort(order, function(a, b)
    return less({ order = order, pos = pos, zBoost = zBoost }, a, b)
  end)

  local index = {}
  for i, id in ipairs(order) do index[id] = i end
  return { byId = byId, order = order, indexOf = index, pos = pos, zBoost = zBoost }
end

-- Lookups
function AnimatingCards.get(state, id)            return state.byId[id] end
function AnimatingCards.getHandIndex(state, id)   return state.pos[id] end
function AnimatingCards.getZBoost(state, id)      return state.zBoost[id] or 0 end

-- Iterate in draw order (bottom -> top)
function AnimatingCards.iter(state)
  local i, order = 0, state.order
  return function()
    i = i + 1
    local id = order[i]
    if id then return id, state.byId[id] end
  end
end

-- Lift a card above all others (set zBoost = max+1)
function AnimatingCards.lift(state, id)
  if not state.byId[id] then return state end

  local max = 0
  for _, z in pairs(state.zBoost) do
    if z > max then max = z end
  end

  return AnimatingCards.setZBoost(state, id, max + 1)
end

-- Reset a card’s zBoost to 0
function AnimatingCards.lower(state, id)
  return AnimatingCards.setZBoost(state, id, 0)
end


return AnimatingCards
