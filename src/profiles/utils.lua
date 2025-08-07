local ProfileUtils = {}

function ProfileUtils.serialize(tbl, indent)
  indent = indent or 0
  local buffer = {}
  local prefix = string.rep("  ", indent)
  table.insert(buffer, "{\n")
  for k, v in pairs(tbl) do
    local key = type(k) == "string" and string.format("[%q]", k) or "[" .. tostring(k) .. "]"
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
    table.insert(buffer, string.format("%s  %s = %s,\n", prefix, key, value))
  end
  table.insert(buffer, prefix .. "}")
  return table.concat(buffer)
end

return ProfileUtils