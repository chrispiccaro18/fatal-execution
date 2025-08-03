local function newCard(props)
  return {
    name = props.name or "Unnamed Card",
    cost = props.cost or 0,
    playEffect = props.playEffect or { type = "none", amount = 0 },
    destructorEffect = props.destructorEffect or { type = "none", amount = 0 },

    -- UI-related transient fields
    state = "idle",        -- "idle", "animating", etc.
    pos = nil,             -- {x=, y=} screen coords if needed
    animX = nil,
    animY = nil,
    selectable = false     -- can it be clicked yet?
  }
end

local rawStarterCards = {
  {
    name = "Guru Meditation",
    cost = 1,
    playEffect = { type = "progress", amount = 1 },
    destructorEffect = { type = "threat", amount = 1 }
  },
  {
    name = "Oops",
    cost = 2,
    playEffect = { type = "progress", amount = 2 },
    destructorEffect = { type = "threat", amount = 2 }
  },
  {
    name = "Dangling Pointer",
    cost = 1,
    playEffect = { type = "threat", amount = -1 },
    destructorEffect = { type = "threat", amount = 1 }
  },
  {
    name = "Garbage Collection",
    cost = 2,
    playEffect = { type = "threat", amount = -2 },
    destructorEffect = { type = "progress", amount = -1 }
  },
  {
    name = "Canaries",
    cost = 1,
    playEffect = { type = "threat", amount = -1 },
    destructorEffect = { type = "threat", amount = 2 }
  },
  {
    name = "Heap Spray",
    cost = 3,
    playEffect = { type = "progress", amount = 3 },
    destructorEffect = { type = "threat", amount = 3 }
  },
  {
    name = "Superoptimization",
    cost = 2,
    playEffect = { type = "progress", amount = 2 },
    destructorEffect = { type = "progress", amount = -1 }
  },
  {
    name = "Tree Shaking",
    cost = 1,
    playEffect = { type = "threat", amount = -1 },
    destructorEffect = { type = "progress", amount = -1 }
  },
  -- {
  --   name = "Memory Leak",
  --   cost = 2,
  --   playEffect = { type = "threat", amount = -2 },
  --   destructorEffect = { type = "progress", amount = -2 }
  -- },
    {
    -- id = 4,
    -- tier = 0,
    name = "System Shuffle",
    cost = 1,
    playEffect = { type = "shuffle_disruptor" },
    destructorEffect = { type = "draw_to_destructor", amount = 1 },
  },
  {
    name = "Segmentation Fault",
    cost = 3,
    playEffect = { type = "progress", amount = 3 },
    destructorEffect = { type = "threat", amount = 4 }
  },
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