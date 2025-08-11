local T = {}

local function base(name) return { __type = name } end

T.any       = base("any")
T.str       = base("string")
T.num       = base("number")
T.bool      = base("boolean")
T.tbl       = base("table")          -- permissive table (unknown keys allowed)
T.null      = base("null")           -- exactly nil
T.readonly  = function(spec) return { __type="readonly", spec=spec } end

T.optional  = function(spec) return { __type="optional", spec=spec } end
T.nullable  = function(spec) return { __type="nullable", spec=spec } end
T.enum = function(vals)
  local values = {}
  local n = 0
  if type(vals) == "table" then
    -- detect array-ish
    local isArray = (vals[1] ~= nil)
    if isArray then
      for i=1,#vals do n=n+1; values[n] = vals[i] end
    else
      for _,v in pairs(vals) do
        if v ~= nil then n=n+1; values[n] = v end
      end
    end
  end
  return { __type="enum", values=values }
end

T.arr = function(itemSpec)
  return { __type="array", item=itemSpec }
end

-- Exact object shape. Unknown keys rejected unless __allowUnknown=true
T.shape = function(fields, opts)
  return { __type="shape", fields=fields or {}, __allowUnknown = opts and opts.__allowUnknown or false }
end

return T
