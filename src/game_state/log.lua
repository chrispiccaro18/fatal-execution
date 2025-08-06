local Log = {}
local Decorators = require("ui.decorators")

function Log.addEntry(state, entry)
  table.insert(state.log, entry)
  Decorators.emit("logGlow", { message = entry })
  return state
end

return Log