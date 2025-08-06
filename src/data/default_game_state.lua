local Deck = require("game_state.deck")
local Hand = require("game_state.hand")
local Systems = require("game_state.systems")
local DestructorQueue = require("game_state.destructor_queue")
local Threat = require("game_state.threat")

local defaultGameState = {
    deck = Deck.init(),
    hand = Hand.init(),
    handSize = 4,
    systems = Systems.init(),
    destructorQueue = DestructorQueue.init(),
    destructorNullify = 0,
    ram = 0,
    turn = {
      phase = "start",
      turnCount = 0
    },
    threat = Threat.init(),
    log = {},
    currentSystemIndex = 1,
    uiTransitions = {},
  }

  return defaultGameState