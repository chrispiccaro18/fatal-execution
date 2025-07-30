local Decorators = require("ui.decorators")
local Systems = {}

function Systems.init()
  return {
    { name = "Power",     required = 3, progress = 0, envEffect = "Hand size increased by 1" },
    { name = "Reactor",   required = 5, progress = 0, envEffect = "Gain 1 RAM at start of turn" },
    { name = "Thrusters", required = 7, progress = 0, envEffect = "All effects doubled" }
  }
end

function Systems.incrementProgress(systemList, currentSystemIndex, amount)
  local newList = {}
  for i, sys in ipairs(systemList) do
    local systemProgress = sys.progress
    if i == currentSystemIndex then
      local delta = amount
      systemProgress = sys.progress + amount
      if systemProgress > sys.required then
        systemProgress = sys.required
        delta = sys.required - sys.progress
      elseif systemProgress < 0 then
        systemProgress = 0
        delta = -sys.progress
      end
      -- Emit a decorator event for progress animation
      Decorators.emit("systemProgress", {
        systemIndex = i,
        delta = delta
      })
    end
    newList[i] = {
      name = sys.name,
      required = sys.required,
      progress = systemProgress,
      envEffect = sys.envEffect
    }
  end
  return newList
end

return Systems
