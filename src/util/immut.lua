local Immutable = {}

function Immutable.copyArray(a)
  local out = {}
  for i,v in ipairs(a or {}) do out[i] = v end
  return out
end

function Immutable.push(a, v)
  local out = Immutable.copyArray(a)
  out[#out+1] = v
  return out
end

function Immutable.assign(parent, key, child)
  local p = require("util.copy")(parent)
  p[key] = child
  return p
end

return Immutable
