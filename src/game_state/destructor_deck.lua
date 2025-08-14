local RNG      = require("state.rng")
local DestructorDeckPresets = require("data.destructor_decks")
local CardLib = require("game_state.cards")


local DestructorDeck = {}

-- Deterministic in-place Fisher–Yates (we return a cloned deck for immutability)
local function shuffledClone(deck, rngStream)
  local out = {}
  for i,v in ipairs(deck or {}) do out[i] = v end
  if not rngStream then return out end
  for i = #out, 2, -1 do
    local j = RNG.nextInt(rngStream, 1, i)
    out[i], out[j] = out[j], out[i]
  end
  return out
end

local function toCards(ids, onlyId, allocator)
  local cards = {}
  for i, id in ipairs(ids) do
    cards[i] = CardLib.instantiate(id, onlyId, allocator)
  end
  return cards
end

-- Build a realized destructor deck from a preset id
function DestructorDeck.initFromId(deckId, rngStream, allocCardId)
  local def = assert(DestructorDeckPresets[deckId], "Unknown destructor deck: "..tostring(deckId))
  local cards = {}
  for i,c in ipairs(def.cards or {}) do
    local k = {}; for kk,vv in pairs(c) do k[kk]=vv end  -- clone entries
    cards[i] = k
  end
  -- If you want an initial shuffle, do it here:
  local shuffled = shuffledClone(cards, rngStream)
  return toCards(shuffled, false, allocCardId)
end

-- Draw one from the top (immutable)
-- returns: cardOrNil, newDeck
function DestructorDeck.draw(deck)
  if not deck or #deck == 0 then return nil, {} end
  local top = deck[1]
  local newDeck = {}
  for i = 2, #deck do newDeck[#newDeck+1] = deck[i] end
  return top, newDeck
end

-- Draw N from the top (immutable)
function DestructorDeck.drawMultiple(deck, n)
  local drawn, newDeck = {}, {}
  for i = 1, #deck do
    if #drawn < n then drawn[#drawn+1] = deck[i]
    else newDeck[#newDeck+1] = deck[i] end
  end
  return drawn, newDeck
end

-- Add a card to the bottom (immutable)
function DestructorDeck.addBottom(deck, card)
  local out = {}
  for i,v in ipairs(deck or {}) do out[i] = v end
  out[#out+1] = card
  return out
end

-- Deterministic shuffle (immutable)
function DestructorDeck.shuffle(deck, rngStream)
  return shuffledClone(deck, rngStream)
end

-- (Optional) add to top
function DestructorDeck.addTop(deck, card)
  local out = { card }
  for i,v in ipairs(deck or {}) do out[#out+1] = v end
  return out
end

-- (Optional) tiny helper
function DestructorDeck.size(deck) return #deck end

return DestructorDeck
