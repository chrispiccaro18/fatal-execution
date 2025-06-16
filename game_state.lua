local GameState = {
  turn = 1,
  ram = 0,

  -- Draw pile (cards go to bottom after use)
  deck = {},

  -- Cards in hand (max 4)
  hand = {},

  -- Cards in the shadow queue, resolving at end of turn
  shadowQueue = {},

  -- Log of player and shadow actions
  log = {},

  -- Which system the player is currently working to restore
  currentSystem = "power",

  -- System progress tracking
  systems = {
    power =    { progress = 0, required = 3, online = false },
    reactor =  { progress = 0, required = 5, online = false },
    thrusters = { progress = 0, required = 7, online = false },
  },

  -- Environment status and modifiers (can be expanded later)
  environment = {
    current = "low_power",
    effects = {},
  },

  -- UI interaction state
  ui = {
    selectedCardIndex = nil,
    hoveredCardIndex = nil,
  },

  -- Game phase: "player", "shadow", "gameover"
  phase = "player",
}

return GameState