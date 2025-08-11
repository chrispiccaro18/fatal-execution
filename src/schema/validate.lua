local function typeOf(v)
  local t = type(v)
  if v == nil then return "null" end
  return t
end

local function err(path, expected, got)
  return { path = path, expected = expected, got = got }
end

local function joinPath(path, key)
  if path == "" then return tostring(key) end
  if type(key) == "number" then
    return ("%s[%d]"):format(path, key)
  else
    return ("%s.%s"):format(path, tostring(key))
  end
end

local function validateAny(_, _, _) return true end

local function validateEnum(val, spec)
  if val == nil then return false end
  for _, v in ipairs(spec.values or {}) do
    if val == v then return true end
  end
  return false
end

local function validateArray(val, spec, path, visit)
  if type(val) ~= "table" then return false, { err(path, "array", typeOf(val)) } end
  local errors = {}
  for i = 1, #val do
    local ok, e = visit(val[i], spec.item, joinPath(path, i))
    if not ok then
      for _, ee in ipairs(e) do errors[#errors+1] = ee end
    end
  end
  return (#errors == 0), errors
end

local function validateShape(val, spec, path, visit)
  if type(val) ~= "table" then return false, { err(path, "object", typeOf(val)) } end
  local errors = {}

  -- required/known fields
  for k, fieldSpec in pairs(spec.fields) do
    local v = val[k]
    local ok, e = visit(v, fieldSpec, joinPath(path, k))
    if not ok then
      for _, ee in ipairs(e) do errors[#errors+1] = ee end
    end
  end

  -- unknowns?
  if not spec.__allowUnknown then
    for k, _ in pairs(val) do
      if spec.fields[k] == nil then
        errors[#errors+1] = err(joinPath(path, k), "no extra key", "extra key")
      end
    end
  end

  return (#errors == 0), errors
end

local function validateValue(val, spec, path)
  local st = spec.__type
  if st == "any"      then return true, {}
  elseif st == "string"  then return type(val) == "string", (type(val)=="string" and {}) or { err(path,"string",typeOf(val)) }
  elseif st == "number"  then return type(val) == "number", (type(val)=="number" and {}) or { err(path,"number",typeOf(val)) }
  elseif st == "boolean" then return type(val) == "boolean", (type(val)=="boolean" and {}) or { err(path,"boolean",typeOf(val)) }
  elseif st == "null"    then return val == nil, (val==nil and {}) or { err(path,"null",typeOf(val)) }
  elseif st == "table"   then return type(val) == "table", (type(val)=="table" and {}) or { err(path,"table",typeOf(val)) }
  elseif st == "enum"    then return validateEnum(val, spec), (validateEnum(val, spec) and {}) or { err(path,"enum",typeOf(val)) }
  elseif st == "array"   then return validateArray(val, spec, path, validateValue)
  elseif st == "shape"   then return validateShape(val, spec, path, validateValue)
  elseif st == "optional" then
    if val == nil then return true, {} end
    return validateValue(val, spec.spec, path)
  elseif st == "nullable" then
    if val == nil then return true, {} end
    return validateValue(val, spec.spec, path)
  elseif st == "readonly" then
    return validateValue(val, spec.spec, path)
  else
    return false, { err(path, "unknown-spec", st or "nil") }
  end
end

local function validate(value, spec)
  local ok, errors = validateValue(value, spec, "")
  return ok, errors
end

return { validate = validate }
