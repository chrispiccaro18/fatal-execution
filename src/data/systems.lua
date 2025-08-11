local Const = require("const")

local Systems = {
  power = {
    id = Const.SYSTEMS.POWER.ID,
    name = Const.SYSTEMS.POWER.NAME,
    required = 3,
    envEffect = {
      type = Const.EFFECTS.MODIFY_HAND_SIZE,
      trigger = Const.EFFECTS_TRIGGERS.IMMEDIATE,
      amount = 1
    }
  },
  reactor = {
    id = Const.SYSTEMS.REACTOR.ID,
    name = Const.SYSTEMS.REACTOR.NAME,
    required = 5,
    envEffect = {
      type = Const.EFFECTS.GAIN_RAM,
      trigger = Const.EFFECTS_TRIGGERS.START_OF_TURN,
      amount = 1
    }
  },
  thrusters = {
    id = Const.SYSTEMS.THRUSTERS.ID,
    name = Const.SYSTEMS.THRUSTERS.NAME,
    required = 7,
    envEffect = {
      type = Const.EFFECTS.MULTIPLY_EFFECTS,
      trigger = Const.EFFECTS_TRIGGERS.IMMEDIATE,
      multiplier = 2
    }
  }
}

return Systems
