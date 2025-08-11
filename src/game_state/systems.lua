local SystemDefs = require("data.systems")

local Systems = {}

local function copy(t) local r={}; for k,v in pairs(t) do r[k]=v end; return r end

-- Realize from a list of {id=...} coming from the ship preset
function Systems.initFromIds(systemRefs)
  local realized = {}
  for i,ref in ipairs(systemRefs or {}) do
    local def = assert(SystemDefs[ref.id], "Unknown system id: "..tostring(ref.id))
    realized[i] = {
      id        = def.id,
      name      = def.name,
      required  = def.required,
      progress  = 0,
      activated = false,
      envEffect = def.envEffect and copy(def.envEffect) or nil,
    }
  end
  return realized
end

-- Same increment function you had, now pure and returning delta + completed
function Systems.incrementProgress(systemList, currentSystemIndex, amount)
  local newList, deltaUsed, completed = {}, 0, false
  for i, sys in ipairs(systemList) do
    if i ~= currentSystemIndex then
      newList[i] = sys
    else
      local tgt = {
        id=sys.id, name=sys.name, required=sys.required,
        progress=sys.progress, activated=sys.activated, envEffect=sys.envEffect
      }
      local before = tgt.progress
      local after  = before + amount
      if after > tgt.required then after = tgt.required end
      if after < 0             then after = 0 end
      tgt.progress = after
      deltaUsed = after - before
      completed = (after >= tgt.required)
      newList[i] = tgt
    end
  end
  return newList, deltaUsed, completed
end

return Systems
