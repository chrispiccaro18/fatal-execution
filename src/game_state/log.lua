local Const  = require("const")
local immut  = require("util.immut") -- your module above

local Log    = {}

Log.SEVERITY = Const.LOG.SEVERITY
Log.CATEGORY = Const.LOG.CATEGORY

-- internal: normalize an entry + opts into a log item
-- turnCount is passed in so slice-level helpers don't need the whole state
local function makeItem(entry, opts, turnCount)
  local msg, cat, sev, vis, data, ts

  if type(entry) == "string" then
    msg = entry
  elseif type(entry) == "table" then
    msg  = entry.message or "—"
    cat  = entry.category
    sev  = entry.severity
    vis  = entry.visible
    data = entry.data
    ts   = entry.ts
  else
    error("Log.add: entry must be string or table")
  end

  opts = opts or {}
  msg  = opts.message or msg
  cat  = opts.category or cat or Log.CATEGORY.GENERAL
  sev  = opts.severity or sev or Log.SEVERITY.INFO
  vis  = (opts.visible ~= nil) and opts.visible or (vis ~= nil and vis or true)
  data = opts.data or data
  ts   = opts.ts or ts or os.time()

  return {
    message  = msg,
    category = cat,
    severity = sev,
    visible  = vis,
    ts       = ts,
    turn     = turnCount, -- number or nil
    data     = data,
  }
end

-- =========================
-- Slice-level (preferred)
-- =========================

--- Add a single entry to a log slice (immutable).
-- @param log table?         current log array
-- @param entry string|table log entry
-- @param opts  table?       optional overrides
-- @param turnCount number?  current turn count for attribution
-- @return newLog, item
function Log.addToLog(log, entry, opts, turnCount)
  local item = makeItem(entry, opts, turnCount)
  local newLog = immut.push(log or {}, item)
  return newLog, item
end

--- Add many entries to a log slice in one pass (immutable).
-- entries: array of `string` or `{ entry=..., opts=... }`
-- @return newLog, items
function Log.addManyToLog(log, entries, turnCount)
  local items = {}
  local out = immut.copyArray(log or {})
  for _, spec in ipairs(entries or {}) do
    local entry, opts
    if type(spec) == "table" and spec.entry ~= nil then
      entry, opts = spec.entry, spec.opts
    else
      entry = spec
    end
    local item = makeItem(entry, opts, turnCount)
    items[#items + 1] = item
    out[#out + 1] = item
  end
  return out, items
end

--- Return a *new* array with only visible items (pure slice; no state change).
function Log.visible(log)
  local out = {}
  for _, it in ipairs(log or {}) do
    if it.visible then out[#out + 1] = it end
  end
  return out
end

--- Return a *new* array of visible items, trimmed to the last `maxCount`.
-- Pure helper for the UI (does not mutate state).
function Log.visibleTrimmed(log, maxCount)
  local vis = Log.visible(log)
  if type(maxCount) ~= "number" or maxCount < 0 or #vis <= maxCount then
    return vis
  end
  local out = {}
  local start = #vis - maxCount + 1
  for i = start, #vis do out[#out + 1] = vis[i] end
  return out
end

--- Trim a log slice (returns a new array). Does NOT change state.
function Log.trimLog(log, maxCount)
  local src = log or {}
  if type(maxCount) ~= "number" or maxCount < 0 or #src <= maxCount then
    return immut.copyArray(src)
  end
  local out = {}
  local start = #src - maxCount + 1
  for i = start, #src do out[#out + 1] = src[i] end
  return out
end

-- =========================
-- State-level conveniences
-- (wrap slice helpers)
-- =========================

--- Add a single entry to model.log immutably.
function Log.add(model, entry, opts)
  local turnCount = model.turn and model.turn.turnCount or nil
  local newLog, item = Log.addToLog(model.log, entry, opts, turnCount)
  local newModel = immut.assign(model, "log", newLog)
  return newModel, item
end

--- Add many entries to model.log immutably.
function Log.addMany(model, entries)
  local turnCount = model.turn and model.turn.turnCount or nil
  local newLog, items = Log.addManyToLog(model.log, entries, turnCount)
  local newModel = immut.assign(model, "log", newLog)
  return newModel, items
end

--- Clear all log entries (immutable).
function Log.clear(model)
  return immut.assign(model, "log", {})
end

--- Trim model.log to last `maxCount` entries (immutable).
function Log.trim(model, maxCount)
  return immut.assign(model, "log", Log.trimLog(model.log, maxCount))
end

return Log
