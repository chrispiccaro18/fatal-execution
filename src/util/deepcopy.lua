-- USAGE
-- local deepcopy = require("util.deepcopy")

-- -- Full deep copy for snapshotting model
-- local snapshot = deepcopy(Store.model)

-- -- Deep copy but drop functions/userdata (safer saves; default behavior)
-- local clean = deepcopy(Store.model, nil, { skipFns = true, skipUd = true })

-- -- With a depth cap
-- local shallowish = deepcopy(Store.model, nil, { maxDepth = 3 })
-- TIPS
-- Model saves: use defaults (skipFns=true, skipUd=true, copyMeta=false) to keep files clean.

-- Runtime cloning for edits: defaults are still fine; if you actually rely on metatables, set copyMeta=true only for those structures.

-- Performance: use deep copy for snapshots; for routine updates prefer shallow copy of containers (util.copy) and keep children immutable.

-- Deep copy for plain Lua tables used in the game model.
-- - Handles cycles (via `seen`).
-- - Copies both keys and values.
-- - Skips metatables by default (safe for serialization).
-- - Optionally skip functions/userdata to keep saves clean.
local function deepcopy(value, seen, opts)
  -- opts:
  --   skipFns   = true|false (default true)  -- do not copy function values/keys
  --   skipUd    = true|false (default true)  -- do not copy userdata values/keys
  --   copyMeta  = true|false (default false) -- copy metatables (not recommended for saves)
  --   maxDepth  = number or nil              -- optional safeguard

  opts = opts or {}
  seen = seen or {}

  local t = type(value)

  -- Primitives copy by value
  if t ~= "table" then
    if t == "function" and opts.skipFns ~= false then return nil end
    if t == "userdata" and opts.skipUd  ~= false then return nil end
    return value
  end

  -- Depth guard
  if opts.maxDepth and opts.maxDepth <= 0 then
    return {} -- cut off here
  end

  -- Cycle check
  if seen[value] then
    return seen[value]
  end

  local result = {}
  seen[value] = result

  -- Copy (key, value) pairs deeply
  for k, v in pairs(value) do
    local kt, vt = type(k), type(v)

    -- Optionally skip function/userdata keys/values for save safety
    if not (kt == "function" and opts.skipFns ~= false)
       and not (kt == "userdata" and opts.skipUd ~= false) then
      if not (vt == "function" and opts.skipFns ~= false)
         and not (vt == "userdata" and opts.skipUd ~= false) then

        local newKey = deepcopy(k, seen, opts and {
          skipFns  = opts.skipFns,
          skipUd   = opts.skipUd,
          copyMeta = false,      -- keys rarely need metatables
          maxDepth = opts.maxDepth and (opts.maxDepth - 1) or nil
        })

        local newVal = deepcopy(v, seen, opts and {
          skipFns  = opts.skipFns,
          skipUd   = opts.skipUd,
          copyMeta = false,
          maxDepth = opts.maxDepth and (opts.maxDepth - 1) or nil
        })

        if newKey ~= nil then
          result[newKey] = newVal
        end
      end
    end
  end

  -- Metatables: off by default to keep copies portable/serializable
  if opts.copyMeta then
    local mt = getmetatable(value)
    if mt then
      -- Shallow-copying the metatable is usually enough; deep-copying metas is rare.
      local mtCopy = {}
      for mk, mv in pairs(mt) do mtCopy[mk] = mv end
      setmetatable(result, mtCopy)
    end
  end

  return result
end

return deepcopy
