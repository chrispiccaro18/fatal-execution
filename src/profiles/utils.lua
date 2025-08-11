local ProfileUtils = {}

local function isArray(t)
  local n = 0
  for k,_ in pairs(t) do
    if type(k) ~= "number" then return false end
    if k > n then n = k end
  end
  for i=1,n do
    if t[i] == nil then return false end
  end
  return true
end

local function sortedKeys(t)
  local sk, nk = {}, {}
  for k,_ in pairs(t) do
    if type(k) == "string" then sk[#sk+1] = k else nk[#nk+1] = k end
  end
  table.sort(sk)
  table.sort(nk)
  return sk, nk
end

function ProfileUtils.serialize(tbl, indent)
  indent = indent or 0
  local buffer = {}
  local prefix = string.rep("  ", indent)
  table.insert(buffer, "{\n")

  if isArray(tbl) then
    -- Array portion in order
    for i=1,#tbl do
      local v = tbl[i]
      local value
      if type(v) == "table" then
        value = ProfileUtils.serialize(v, indent + 1)
      elseif type(v) == "string" then
        value = string.format("%q", v)
      elseif type(v) == "number" or type(v) == "boolean" then
        value = tostring(v)
      else
        value = '"<unsupported>"'
      end
      table.insert(buffer, string.format("%s  [%d] = %s,\n", prefix, i, value))
    end
  end

  -- Non-array / map portion (stable order)
  local sk, nk = sortedKeys(tbl)
  local function writeKey(k)
    if type(k) == "string" then return string.format("[%q]", k) end
    return "[" .. tostring(k) .. "]"
  end

  for _,k in ipairs(sk) do
    if not (type(k)=="number" and isArray(tbl)) then
      local v = tbl[k]
      local value
      if type(v) == "table" then
        value = ProfileUtils.serialize(v, indent + 1)
      elseif type(v) == "string" then
        value = string.format("%q", v)
      elseif type(v) == "number" or type(v) == "boolean" then
        value = tostring(v)
      else
        value = '"<unsupported>"'
      end
      table.insert(buffer, string.format("%s  %s = %s,\n", prefix, writeKey(k), value))
    end
  end
  for _,k in ipairs(nk) do
    if not (type(k)=="number" and isArray(tbl)) then
      local v = tbl[k]
      local value
      if type(v) == "table" then
        value = ProfileUtils.serialize(v, indent + 1)
      elseif type(v) == "string" then
        value = string.format("%q", v)
      elseif type(v) == "number" or type(v) == "boolean" then
        value = tostring(v)
      else
        value = '"<unsupported>"'
      end
      table.insert(buffer, string.format("%s  %s = %s,\n", prefix, writeKey(k), value))
    end
  end

  table.insert(buffer, prefix .. "}")
  return table.concat(buffer)
end

return ProfileUtils
