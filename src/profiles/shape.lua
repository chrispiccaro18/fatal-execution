-- profiles/shape.lua
local M = {}

-- turns a concrete default table into a shape table of type tags
-- ex: { name="x", settings={volume=1} } -> { name="string", settings={ volume="number" } }
local function toShape(value)
  local t = type(value)
  if t ~= "table" then return t end
  local s = {}
  for k, v in pairs(value) do
    s[k] = toShape(v)
  end
  return s
end

-- generic shape validator (recursive)
local function isValidByShape(value, shape)
  local st = type(shape)
  if st == "string" then
    return type(value) == shape
  elseif st == "table" then
    if type(value) ~= "table" then return false end
    -- must not contain unknown keys
    for k in pairs(value) do
      if shape[k] == nil then return false end
    end
    -- must contain all expected keys w/ compatible types
    for k, subshape in pairs(shape) do
      if not isValidByShape(value[k], subshape) then return false end
    end
    return true
  else
    return false
  end
end

M.toShape = toShape
M.isValidByShape = isValidByShape
return M
