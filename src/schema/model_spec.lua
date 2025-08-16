local T     = require("schema.types")
local Const = require("const")

-- Enums from Const (keep these strict)
local TURN_PHASES = Const.TURN_PHASES
local EFFECT_TRIGGERS = Const.EFFECTS_TRIGGERS
local LOG_SEVERITY = Const.LOG.SEVERITY

-- Minimal card instance shape (tighten as card lib stabilizes)
local CardInstance = T.shape({
  id   = T.str,
  instanceId = T.str, -- unique per run
  -- name / playEffect / destructorEffect ... can be added later when stable
}, { __allowUnknown = true })

-- System envEffect (based on data/systems.lua you shared)
local SystemEnvEffect = T.shape({
  type     = T.str, -- could be T.enum({...}) if you want stricter
  trigger  = T.enum(EFFECT_TRIGGERS),
  amount   = T.optional(T.num),
  multiplier = T.optional(T.num),
}, { __allowUnknown = false })

local SystemItem = T.shape({
  id        = T.str,
  name      = T.str,
  required  = T.num,
  progress  = T.num,
  activated = T.bool,
  envEffect = T.nullable(SystemEnvEffect),
}, { __allowUnknown = false })

-- Threats match your data/threats.lua shape
local ThreatEnvEffect = T.shape({
  type     = T.str,
  trigger  = T.enum(EFFECT_TRIGGERS),
  amount   = T.optional(T.num),
}, { __allowUnknown = false })

local ThreatItem = T.shape({
  id       = T.str,
  name     = T.str,
  value    = T.num,
  max      = T.num,
  envEffect = T.nullable(ThreatEnvEffect),
}, { __allowUnknown = false })

-- Log items (player-visible by default, with debug allowed)
local LogItem = T.shape({
  message  = T.str,
  category = T.optional(T.str),
  severity = T.optional(T.enum(LOG_SEVERITY)),
  visible  = T.optional(T.bool),
  ts       = T.optional(T.num),
  turn     = T.optional(T.num),
  data     = T.optional(T.tbl), -- arbitrary payload
}, { __allowUnknown = false })

-- RunConfig (normalized) per src/data/run_config.lua
local DeckSpecPreset = T.shape({
  kind    = T.enum({ Const.DECK_SPEC.PRESET }),
  id      = T.str,
  shuffle = T.optional(T.bool),
}, { __allowUnknown = false })

local DeckSpecListEntry = T.shape({
  id    = T.str,
  count = T.num,
}, { __allowUnknown = false })

local DeckSpecCustomList = T.shape({
  kind    = T.enum({ Const.DECK_SPEC.CUSTOM_LIST }),
  entries = T.arr(DeckSpecListEntry),
  shuffle = T.optional(T.bool),
}, { __allowUnknown = false })

local DeckSpecPoolBaseEntry  = DeckSpecListEntry
local DeckSpecPoolPoolEntry  = T.shape({
  id     = T.str,
  weight = T.num,
}, { __allowUnknown = false })

local DeckSpecCustomPool = T.shape({
  kind            = T.enum({ Const.DECK_SPEC.CUSTOM_POOL }),
  base            = T.arr(DeckSpecPoolBaseEntry),
  pool            = T.arr(DeckSpecPoolPoolEntry),
  poolCount       = T.num,
  allowDuplicates = T.bool,
  shuffle         = T.optional(T.bool),
}, { __allowUnknown = false })

local DeckSpec = T.shape({
  kind = T.enum({
    Const.DECK_SPEC.PRESET,
    Const.DECK_SPEC.CUSTOM_LIST,
    Const.DECK_SPEC.CUSTOM_POOL
  }),
}, { __allowUnknown = true }) -- accept the discriminated union; validated by concrete sub-shapes below

local RunConfig = T.shape({
  shipPresetId = T.str,
  deckSpec     = T.shape({
    kind = T.str,
  }, { __allowUnknown = true }),  -- we’ll check exact shape via a union helper below
  difficulty   = T.str,
  handSize     = T.num,
  mods         = T.arr(T.str),
}, { __allowUnknown = false })

-- RNG top-level shape; allow unknown internals of each stream
local RNGStream = T.tbl
local RNGShape  = T.shape({
  deckBuild  = RNGStream,
  draws      = RNGStream,
  destructor = RNGStream,
  general    = RNGStream,
}, { __allowUnknown = false })

local idsShape = T.shape({
  run        = T.str,
  nextCard   = T.num,
}, { __allowUnknown = false })

-- Turn state
local Turn = T.shape({
  phase     = T.enum(TURN_PHASES),
  turnCount = T.num,
}, { __allowUnknown = false })

-- Top-level Model spec
local ModelSpec = T.shape({
  seed        = T.num,
  gameVersion = T.str,

  runConfig   = RunConfig,

  rng         = RNGShape,

  ids         = idsShape,

  deck        = T.arr(CardInstance),
  hand        = T.arr(CardInstance),
  handSize    = T.num,

  systems     = T.arr(SystemItem),
  currentSystemIndex = T.num,

  threats     = T.arr(ThreatItem),

  destructorDeck    = T.arr(CardInstance),
  destructorNullify = T.num,

  ram         = T.num,
  log         = T.arr(LogItem),

  turn        = Turn,

  tasks       = T.arr(T.tbl), -- free-form task payloads

  animatingCards = T.tbl,      -- cards currently being animated
}, { __allowUnknown = false })

-- Helper to enforce deckSpec discriminated-union at runtime
local function validateDeckSpecUnion(deckSpec, validate)
  local k = deckSpec and deckSpec.kind
  if k == Const.DECK_SPEC.PRESET then
    return validate(deckSpec, DeckSpecPreset)
  elseif k == Const.DECK_SPEC.CUSTOM_LIST then
    return validate(deckSpec, DeckSpecCustomList)
  elseif k == Const.DECK_SPEC.CUSTOM_POOL then
    return validate(deckSpec, DeckSpecCustomPool)
  end
  return false, { { path="runConfig.deckSpec.kind", expected="valid deckSpec kind", got=tostring(k) } }
end

return {
  ModelSpec = ModelSpec,
  validateDeckSpecUnion = validateDeckSpecUnion,
}
