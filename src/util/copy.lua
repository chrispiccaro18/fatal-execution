-- Shallow copy of a table (no metatables, no deep recursion)
return function(t)
  local r = {}
  for k,v in pairs(t or {}) do
    r[k] = v
  end
  return r
end