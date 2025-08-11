local Const = require("const")

local CardDefs = Const.CARDS
local PLAY_EFFECT_TYPES = Const.PLAY_EFFECT_TYPES
local DESTRUCTOR_EFFECT_TYPES = Const.DESTRUCTOR_EFFECT_TYPES
local DISCARD_EFFECT_TYPES = Const.ON_DISCARD_EFFECT_TYPES

local Cards = {
  [CardDefs.TREE_SHAKING.ID] = {
    id               = CardDefs.TREE_SHAKING.ID,
    name             = CardDefs.TREE_SHAKING.NAME,
    cost             = 1,
    playEffect       = { type = PLAY_EFFECT_TYPES.PROGRESS, amount = 1 },
    destructorEffect = { type = DESTRUCTOR_EFFECT_TYPES.PROGRESS, amount = -2 },
  },

  [CardDefs.DANGLING_POINTER.ID] = {
    id               = CardDefs.DANGLING_POINTER.ID,
    name             = CardDefs.DANGLING_POINTER.NAME,
    cost             = 1,
    playEffect       = { type = PLAY_EFFECT_TYPES.THREAT, amount = -1 },
    destructorEffect = { type = DESTRUCTOR_EFFECT_TYPES.THREAT, amount = 2 },
  },

  [CardDefs.GURU_MEDITATION.ID] = {
    id               = CardDefs.GURU_MEDITATION.ID,
    name             = CardDefs.GURU_MEDITATION.NAME,
    cost             = 1,
    playEffect       = { type = PLAY_EFFECT_TYPES.PROGRESS, amount = 1 },
    destructorEffect = { type = DESTRUCTOR_EFFECT_TYPES.THREAT, amount = 3 },
  },

  [CardDefs.MEMORY_LEAK.ID] = {
    id               = CardDefs.MEMORY_LEAK.ID,
    name             = CardDefs.MEMORY_LEAK.NAME,
    cost             = 1,
    playEffect       = { type = PLAY_EFFECT_TYPES.THREAT, amount = -2 },
    destructorEffect = { type = DESTRUCTOR_EFFECT_TYPES.PROGRESS, amount = -1 },
  },

  [CardDefs.OOPS.ID] = {
    id               = CardDefs.OOPS.ID,
    name             = CardDefs.OOPS.NAME,
    cost             = 2,
    playEffect       = { type = PLAY_EFFECT_TYPES.PROGRESS, amount = 2 },
    destructorEffect = { type = DESTRUCTOR_EFFECT_TYPES.PROGRESS, amount = -3 },
  },

  [CardDefs.GARBAGE_COLLECTION.ID] = {
    id               = CardDefs.GARBAGE_COLLECTION.ID,
    name             = CardDefs.GARBAGE_COLLECTION.NAME,
    cost             = 2,
    playEffect       = { type = PLAY_EFFECT_TYPES.THREAT, amount = -2 },
    destructorEffect = { type = DESTRUCTOR_EFFECT_TYPES.THREAT, amount = 3 },
  },

  [CardDefs.SYSTEM_SHUFFLE.ID] = {
    id               = CardDefs.SYSTEM_SHUFFLE.ID,
    name             = CardDefs.SYSTEM_SHUFFLE.NAME,
    cost             = 1,
    playEffect       = { type = PLAY_EFFECT_TYPES.SHUFFLE_DISRUPTOR },
    destructorEffect = { type = DESTRUCTOR_EFFECT_TYPES.DRAW_TO_DESTRUCTOR, amount = 1 },
  },

  [CardDefs.MEMORY_PROBE.ID] = {
    id               = CardDefs.MEMORY_PROBE.ID,
    name             = CardDefs.MEMORY_PROBE.NAME,
    cost             = 1,
    playEffect       = { type = PLAY_EFFECT_TYPES.DRAW, amount = 2 },
    destructorEffect = { type = DESTRUCTOR_EFFECT_TYPES.DRAW_TO_DESTRUCTOR, amount = 1 },
  },

  [CardDefs.ANOMALY_MASK.ID] = {
    id               = CardDefs.ANOMALY_MASK.ID,
    name             = CardDefs.ANOMALY_MASK.NAME,
    cost             = 2,
    playEffect       = { type = PLAY_EFFECT_TYPES.NULLIFY_DESTRUCTOR, amount = 1 },
    destructorEffect = { type = DESTRUCTOR_EFFECT_TYPES.THREAT, amount = 3 },
  },

  [CardDefs.PULSE_SPIKE.ID] = {
    id               = CardDefs.PULSE_SPIKE.ID,
    name             = CardDefs.PULSE_SPIKE.NAME,
    cost             = 0,
    noPlay           = true,
    onDiscard        = { type = DISCARD_EFFECT_TYPES.RAM_MULTIPLIER, amount = 2 },
    playEffect       = { type = PLAY_EFFECT_TYPES.NONE },
    destructorEffect = { type = DESTRUCTOR_EFFECT_TYPES.THREAT_MULTIPLIER, amount = 2 },
  },
  -- idea for a card that always draws on first turn
  -- {
  --   alwaysFirst = true,
  --   id = "command_protocol",
  --   name = "Command Protocol",
  --   cost = 0,
  --   playEffect = { type = "progress", amount = 2 },
  --   destructorEffect = { type = "none", amount = 0 }
  -- },
}

return Cards
