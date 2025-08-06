local Const = require("const")
local Decorators = require("ui.decorators")

local Systems = {}

function Systems.init()
  return {
    {
      name = "Power",
      required = 3,
      progress = 0,
      activated = false,
      envEffect = { type = Const.EFFECTS.MODIFY_HAND_SIZE, trigger = Const.EFFECTS_TRIGGERS.IMMEDIATE, amount = 1 }
    },
    {
      name = "Reactor",
      required = 5,
      progress = 0,
      activated = false,
      envEffect = { type = Const.EFFECTS.GAIN_RAM, trigger = Const.EFFECTS_TRIGGERS.START_OF_TURN, amount = 1 }
    },
    {
      name = "Thrusters",
      required = 7,
      progress = 0,
      activated = false,
      envEffect = { type = Const.EFFECTS.MULTIPLY_EFFECTS, multiplier = 2 }
    }
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
      activated = sys.activated,
      envEffect = sys.envEffect
    }
  end
  return newList
end

return Systems
