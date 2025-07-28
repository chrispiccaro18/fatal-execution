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
      systemProgress = sys.progress + amount
      if systemProgress > sys.required then
        systemProgress = sys.required
      end
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
