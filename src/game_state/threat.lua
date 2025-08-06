local Const = require("const")

local Threat = {}

function Threat.init()
  return {
    name = "Impact Imminent",
    value = 2,
    max = 10,
    envEffect = { type = Const.EFFECTS.THREAT_TICK, trigger = Const.EFFECTS_TRIGGERS.END_OF_TURN, amount = 1 }
  }
end

function Threat.increment(threat, amount)
  local newThreat = threat.value + amount
  if newThreat > threat.max then
    newThreat = threat.max
  end
  return { name = threat.name, value = newThreat, max = threat.max, envEffect = threat.envEffect }
end

function Threat.set(threat, amount)
  if amount < 0 then
    amount = 0
  elseif amount > threat.max then
    amount = threat.max
  end
  return { name = threat.name, value = amount, max = threat.max, envEffect = threat.envEffect }
end

return Threat
