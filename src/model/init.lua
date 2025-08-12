-- NOTE: When adding/removing fields in the game model (currentRun):
--  1) Update schema/model_spec.lua (ModelSpec) to match new/changed fields
--  2) If the field has a complex sub-shape, create a sub-spec and require it in model_spec.lua
--  3) If the field is derived/ephemeral, consider excluding it from persisted saves
--     (see potential persistedSlice() in profiles or save logic)
--  4) If the field must be migrated for old saves, add migration logic in profiles/init.lua loadSlot
--  5) Ensure any initial default is set in Model.new() here

local Const          = require("const")
local Deck           = require("game_state.deck")
local Hand           = require("game_state.hand")
local Ships          = require("data.ships")
local Systems        = require("game_state.systems")
local Threats        = require("game_state.threats")
local DestructorDeck = require("game_state.destructor_deck")
local Version        = require("version")
local RNG            = require("state.rng")
local MakeRunConfig  = require("data.run_config")

local Model          = {}

-- Internal helper for deriving different RNG sub-streams from the master seed
local function deriveStreams(seed)
  return {
    deckBuild  = RNG.makeStream(seed, Const.RNG_STREAMS.DECK_BUILD),
    draws      = RNG.makeStream(seed, Const.RNG_STREAMS.DRAWS),
    destructor = RNG.makeStream(seed, Const.RNG_STREAMS.DESTRUCTOR),
    general    = RNG.makeStream(seed, Const.RNG_STREAMS.GENERAL),
  }
end

--- Create a new authoritative game model
-- @param seed (number or nil) master seed for deterministic runs
-- @param runConfigOpts (table or nil) player-chosen presets/settings
function Model.new(seed, runConfigOpts)
  seed = seed or os.time()


  -- Explicit run configuration (player choices)
  local runConfig      = MakeRunConfig(runConfigOpts)

  local shipId         = runConfig.shipPresetId
  local ship           = assert(Ships[shipId], "Unknown ship preset: " .. tostring(shipId))

  -- Deterministic RNG sub-streams
  local rng            = deriveStreams(seed)

  -- Realized game content based on config + rng
  local deck           = Deck.init(runConfig.deckSpec, rng.deckBuild, false)
  local systems        = Systems.initFromIds(ship.systems)
  local threats        = Threats.initFromIds(ship.threats)
  local destructorDeck = DestructorDeck.initFromId(ship.destructor_deck)

  return {
    -- META
    seed               = seed,
    gameVersion        = Version.number or "unknown",

    -- CONFIG (explicit player choices)
    runConfig          = runConfig,

    -- DETERMINISTIC RNG STREAMS
    rng                = rng,

    -- REALIZED CONTENT
    deck               = deck,
    hand               = Hand.init(),
    handSize           = runConfig.handSize,

    systems            = systems,
    currentSystemIndex = 1,

    threats            = threats,

    destructorDeck     = destructorDeck,
    destructorNullify  = 0,

    ram                = 0,
    log                = {},

    turn               = {
      phase     = Const.TURN_PHASES.BEGIN_FIRST_TURN,
      turnCount = 0
    },

    -- TASKS: resumable gameplay steps (for save-anywhere)
    tasks              = {},
  }
end

return Model
