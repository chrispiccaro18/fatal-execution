local Const   = require("const")
local RNG     = require("state.rng")
local Presets = require("data.decks")
local CardLib = require("game_state.cards")

local Deck    = {}

-- ===== helpers =====

local function expandEntriesToIds(entries)
  local ids = {}
  for _, e in ipairs(entries or {}) do
    local count = tonumber(e.count) or 1
    for i = 1, count do
      ids[#ids + 1] = e.id
    end
  end
  return ids
end

local function shuffleIds(ids, rngStream)
  if not rngStream then return ids end
  for i = #ids, 2, -1 do
    local j = RNG.nextInt(rngStream, 1, i)
    ids[i], ids[j] = ids[j], ids[i]
  end
  return ids
end

-- NEW: one place to apply the alwaysFirst rule + optional shuffle
local function finalizeOrder(ids, rngStream, shuffleWanted)
  local first, rest = {}, {}
  for _, id in ipairs(ids) do
    -- You need a CardLib lookup. If you don’t have one, add CardLib.getById(id) that reads data/cards.lua
    local def = CardLib.getById and CardLib.getById(id) or nil
    if def and def.alwaysFirst then
      first[#first + 1] = id
    else
      rest[#rest + 1] = id
    end
  end
  if shuffleWanted ~= false then
    shuffleIds(rest, rngStream) -- only shuffle the non-locked part
  end
  -- If you want the alwaysFirst group internal order shuffled too, do it here:
  -- shuffleIds(first, rngStream)
  -- AlwaysFirst stay on top:
  local ordered = {}
  for i = 1, #first do ordered[#ordered + 1] = first[i] end
  for i = 1, #rest do ordered[#ordered + 1] = rest[i] end
  return ordered
end

local function toCards(ids, onlyId)
  local cards = {}
  for i, id in ipairs(ids) do
    cards[i] = CardLib.instantiate(id, onlyId)
  end
  return cards
end

-- ===== builders =====

local function buildFromPreset(spec)
  local preset = assert(Presets[spec.id], "Unknown deck preset: " .. tostring(spec.id))
  local ids = expandEntriesToIds(preset.cards)
  -- preset defaults to shuffle=true unless explicitly false
  local shuffleWanted = (spec.shuffle ~= false)
  return ids, shuffleWanted
end

local function buildFromCustomList(spec)
  local ids = expandEntriesToIds(spec.entries)
  -- list defaults to shuffle=false unless explicitly true
  local shuffleWanted = (spec.shuffle == true)
  return ids, shuffleWanted
end

local function buildFromCustomPool(spec, rngStream)
  local ids = expandEntriesToIds(spec.base)

  local pool = {}
  for _, p in ipairs(spec.pool or {}) do
    pool[#pool + 1] = { id = p.id, weight = tonumber(p.weight) or 1 }
  end

  local function pickWeightedId()
    local sum = 0
    for _, p in ipairs(pool) do sum = sum + p.weight end
    if sum == 0 then return nil end
    local r = RNG.nextInt(rngStream, 1, sum)
    local acc = 0
    for _, p in ipairs(pool) do
      acc = acc + p.weight
      if r <= acc then return p.id end
    end
  end

  local function removeFromPool(id)
    for i = 1, #pool do
      if pool[i].id == id then
        table.remove(pool, i); return
      end
    end
  end

  local poolCount = tonumber(spec.poolCount) or 0
  local allowDup  = (spec.allowDuplicates ~= false)
  for _ = 1, poolCount do
    if #pool == 0 then break end
    local id = pickWeightedId()
    if not id then break end
    ids[#ids + 1] = id
    if not allowDup then removeFromPool(id) end
  end

  -- pool defaults to shuffle=true unless explicitly false
  local shuffleWanted = (spec.shuffle ~= false)
  return ids, shuffleWanted
end

-- ===== public API =====

--- Build a realized deck from a deckSpec (preset | custom_list | custom_pool)
-- @param deckSpec table  See data/run_config.lua shapes
-- @param rngStream table RNG stream (deterministic); pass model.rng.deckBuild
-- @param onlyId   bool   If true, create {id=...} only; else full realized cards
function Deck.init(deckSpec, rngStream, onlyId)
  assert(type(deckSpec) == "table" and deckSpec.kind, "Deck.init: invalid deckSpec")

  local kind = deckSpec.kind
  local ids, shuffleWanted

  if kind == Const.DECK_SPEC.PRESET then
    ids, shuffleWanted = buildFromPreset(deckSpec)
  elseif kind == Const.DECK_SPEC.CUSTOM_LIST then
    ids, shuffleWanted = buildFromCustomList(deckSpec)
  elseif kind == Const.DECK_SPEC.CUSTOM_POOL then
    ids, shuffleWanted = buildFromCustomPool(deckSpec, rngStream)
  else
    error("Deck.init: unsupported deckSpec kind: " .. tostring(kind))
  end

  -- Single place to enforce alwaysFirst + shuffling policy
  local ordered = finalizeOrder(ids, rngStream, shuffleWanted)
  return toCards(ordered, onlyId)
end

-- ===== immutable draw ops =====

function Deck.draw(deck)
  if #deck == 0 then return nil, deck end
  local card = deck[1]
  local newDeck = {}
  for i = 2, #deck do newDeck[#newDeck + 1] = deck[i] end
  return card, newDeck
end

function Deck.drawMultiple(deck, amount)
  local drawn, newDeck = {}, {}
  for i = 1, #deck do
    if #drawn < amount then
      drawn[#drawn + 1] = deck[i]
    else
      newDeck[#newDeck + 1] = deck[i]
    end
  end
  return drawn, newDeck
end

function Deck.placeOnBottom(deck, card)
  local newDeck = {}
  for i = 1, #deck do newDeck[#newDeck + 1] = deck[i] end
  newDeck[#newDeck + 1] = card
  return newDeck
end

return Deck
