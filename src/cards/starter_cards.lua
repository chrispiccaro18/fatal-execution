local function newCard(props)
  return {
    name = props.name or "Unnamed Card",
    cost = props.cost or 0,
    playEffect = props.playEffect or { type = "none", amount = 0 },
    destructorEffect = props.destructorEffect or { type = "none", amount = 0 },
    onDiscard = props.onDiscard or nil,
    noPlay = props.noPlay or false, -- if true, card cannot be played,

    -- UI-related transient fields
    state = "idle", -- "idle", "animating", etc.
    pos = nil,      -- {x=, y=} screen coords if needed
    animX = nil,
    animY = nil,
    selectable = false -- can it be clicked yet?
  }
end

local rawStarterCards = {
  {
    name = "Tree Shaking",
    cost = 1,
    playEffect = { type = "progress", amount = 1 },
    destructorEffect = { type = "progress", amount = -2 }
  },
  {
    name = "Dangling Pointer",
    cost = 1,
    playEffect = { type = "threat", amount = -1 },
    destructorEffect = { type = "threat", amount = 2 }
  },
  {
    name = "Guru Meditation",
    cost = 1,
    playEffect = { type = "progress", amount = 1 },
    destructorEffect = { type = "threat", amount = 3 }
  },
  {
    name = "Memory Leak",
    cost = 1,
    playEffect = { type = "threat", amount = -2 },
    destructorEffect = { type = "progress", amount = -1 }
  },
  {
    name = "Oops",
    cost = 2,
    playEffect = { type = "progress", amount = 2 },
    destructorEffect = { type = "progress", amount = -3 }
  },
  {
    name = "Garbage Collection",
    cost = 2,
    playEffect = { type = "threat", amount = -2 },
    destructorEffect = { type = "threat", amount = 3 }
  },
  {
    -- id = 4,
    -- tier = 0,
    name = "System Shuffle",
    cost = 1,
    playEffect = { type = "shuffle_disruptor" },
    destructorEffect = { type = "draw_to_destructor", amount = 1 },
  },
  {
    -- id = 5,
    -- tier = 0,
    name = "Memory Probe",
    cost = 1,
    playEffect = { type = "draw", amount = 2 },
    destructorEffect = { type = "draw_to_destructor", amount = 1 },
  },
  {
    -- id = 8,
    -- tier = 0,
    name = "Anomaly Mask",
    cost = 2,
    playEffect = { type = "nullify_destructor", amount = 1 },
    destructorEffect = { type = "threat", amount = 3 },
  },
  {
    -- id = 9,
    -- tier = 0,
    name = "Pulse Spike",
    cost = 0,
    noPlay = true,
    onDiscard = { type = "ram_multiplier", amount = 2 },
    playEffect = { type = "none" },
    destructorEffect = { type = "threat_multiplier", amount = 2 },
  },
  -- {
  --   name = "Segmentation Fault",
  --   cost = 3,
  --   playEffect = { type = "progress", amount = 3 },
  --   destructorEffect = { type = "threat", amount = 4 }
  -- },
  -- {
  --   name = "Canaries",
  --   cost = 1,
  --   playEffect = { type = "threat", amount = -1 },
  --   destructorEffect = { type = "threat", amount = 2 }
  -- },
  -- {
  --   name = "Heap Spray",
  --   cost = 3,
  --   playEffect = { type = "progress", amount = 3 },
  --   destructorEffect = { type = "threat", amount = 3 }
  -- },
  -- {
  --   name = "Superoptimization",
  --   cost = 2,
  --   playEffect = { type = "progress", amount = 2 },
  --   destructorEffect = { type = "progress", amount = -1 }
  -- },
}

local function createStarterCards()
  local cards = {}
  for _, cardProps in ipairs(rawStarterCards) do
    table.insert(cards, newCard(cardProps))
  end
  return cards
end

local starterCards = createStarterCards()

return starterCards
