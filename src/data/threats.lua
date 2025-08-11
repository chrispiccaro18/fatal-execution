local Const = require("const")

local Threats = {
  [Const.THREATS.IMPACT_IMMINENT.ID] = {
    id = Const.THREATS.IMPACT_IMMINENT.ID,
    name = Const.THREATS.IMPACT_IMMINENT.NAME,
    value = 2,
    max = 10,
    envEffect = {
      type = Const.EFFECTS.THREAT_TICK,
      trigger = Const.EFFECTS_TRIGGERS.END_OF_TURN,
      amount = 1
    }
  },
}

return Threats
