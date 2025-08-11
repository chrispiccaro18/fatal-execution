local copy = require("util.copy")

local Log = {}

Log.SEVERITY = {
  INFO    = "info",
  WARN    = "warn",
  ERROR   = "error",
  DEBUG   = "debug",
}

-- -- In TaskRunner when a card is played
-- local Log = require("game_state.log")

-- model, logItem = Log.add(model, ("Played card: %s"):format(card.name), {
--   category = "card",
--   severity = Log.SEVERITY.INFO,
-- })

-- -- Then emit UI intent separately (no Decorators here)
-- UI.schedule(view, {
--   { kind = "logGlow", message = logItem.message },
-- })

-- Debug-only info (player won’t see it, but stays in save for playtesting):
-- model = select(1, Log.debug(model, "DQueue size after shuffle: "..tostring(#model.destructorDeck), {
--   category = "debug/destructor",
--   data = { deckSize = #model.destructorDeck }
-- }))

--- Add a log entry (player-visible by default).
-- @param state table   game model (must contain state.log)
-- @param entry string|table
--        string -> message only
--        table  -> { message, category, severity, visible, data, ts }
-- @param opts table?   optional overrides (same fields as table form)
-- @return newState, logItem
function Log.add(state, entry, opts)
  opts = opts or {}

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

  -- opts override entry fields (if provided)
  msg = opts.message  or msg
  cat = opts.category or cat or "general"
  sev = opts.severity or sev or Log.SEVERITY.INFO
  vis = (opts.visible ~= nil) and opts.visible or (vis ~= nil and vis or true)
  data = opts.data or data
  ts = opts.ts or ts or os.time()

  local item = {
    message   = msg,
    category  = cat,
    severity  = sev,
    visible   = vis,            -- player sees only visible==true
    ts        = ts,             -- unix timestamp
    turn      = state.turn and state.turn.turnCount or nil,
    data      = data,           -- arbitrary payload for debugging
  }

  local newLog = copy(state.log or {})
  newLog[#newLog+1] = item

  local newState = copy(state)
  newState.log = newLog
  return newState, item
end

--- Convenience: debug entry (hidden from player by default).
function Log.debug(state, message, opts)
  opts = opts or {}
  if opts.visible == nil then opts.visible = false end
  opts.severity = Log.SEVERITY.DEBUG
  return Log.add(state, message, opts)
end

--- Clear all log entries.
function Log.clear(state)
  local newState = copy(state)
  newState.log = {}
  return newState
end

--- Keep only last `maxCount` entries (trim from the front).
function Log.trim(state, maxCount)
  local log = state.log or {}
  if #log <= (maxCount or 0) then return state end
  local newLog = {}
  local start = #log - maxCount + 1
  for i = start, #log do newLog[#newLog+1] = log[i] end
  local newState = copy(state)
  newState.log = newLog
  return newState
end

--- Utility: return a new array with only visible (player-facing) items.
function Log.visible(log)
  local out = {}
  for _, it in ipairs(log or {}) do
    if it.visible then out[#out+1] = it end
  end
  return out
end

return Log
