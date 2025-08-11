local Const = require("const")

return {
  [Const.DECKS.STARTER] = {
    cards = {
      { id = Const.CARDS.TREE_SHAKING.ID,       count = 1 },
      { id = Const.CARDS.DANGLING_POINTER.ID,   count = 1 },
      { id = Const.CARDS.GURU_MEDITATION.ID,    count = 1 },
      { id = Const.CARDS.MEMORY_LEAK.ID,        count = 1 },
      { id = Const.CARDS.OOPS.ID,               count = 1 },
      { id = Const.CARDS.GARBAGE_COLLECTION.ID, count = 1 },
      { id = Const.CARDS.SYSTEM_SHUFFLE.ID,     count = 1 },
      { id = Const.CARDS.MEMORY_PROBE.ID,       count = 1 },
      { id = Const.CARDS.ANOMALY_MASK.ID,       count = 1 },
      { id = Const.CARDS.PULSE_SPIKE.ID,        count = 1 },
    }
  },

  -- add more presets...
}
