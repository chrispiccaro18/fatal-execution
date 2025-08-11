local ThreatDefs = require("data.threats")

local Threats = {}

local function copy(t) local r={}; for k,v in pairs(t) do r[k]=v end; return r end

-- Realize from a list of {id=...} from the ship preset
function Threats.initFromIds(threatRefs)
  local realized = {}
  for i,ref in ipairs(threatRefs or {}) do
    local def = assert(ThreatDefs[ref.id], "Unknown threat id: "..tostring(ref.id))
    realized[i] = {
      id    = def.id,
      name  = def.name,
      value = def.value or 0,
      max   = def.max or 10,
      envEffect = def.envEffect and copy(def.envEffect) or nil,
    }
  end
  return realized
end

-- Helpers (use as needed)
function Threats.increment(threats, index, amount)
  local t = threats[index]; if not t then return threats end
  local new = {}
  for i,th in ipairs(threats) do
    if i ~= index then new[i] = th
    else
      local v = th.value + amount
      if v < 0 then v = 0 end
      if v > th.max then v = th.max end
      new[i] = { id=th.id, name=th.name, value=v, max=th.max, envEffect=th.envEffect }
    end
  end
  return new
end

function Threats.set(threats, index, amount)
  local t = threats[index]; if not t then return threats end
  local new = {}
  for i,th in ipairs(threats) do
    if i ~= index then new[i] = th
    else
      local v = amount
      if v < 0 then v = 0 end
      if v > th.max then v = th.max end
      new[i] = { id=th.id, name=th.name, value=v, max=th.max, envEffect=th.envEffect }
    end
  end
  return new
end

function Threats.anyExceeded(threats)
  for _,t in ipairs(threats) do
    if t.value >= t.max then return true end
  end
  return false
end

return Threats
