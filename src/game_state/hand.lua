local copy = require("util.copy")
local Deck = require("game_state.deck")

local Hand = {}

function Hand.init()
  return {}
end

function Hand.drawCard(hand, card, handSize)
  local newHand = copy(hand)
  if #newHand < handSize then
    newHand[#newHand+1] = card
  end
  return newHand
end

function Hand.drawMultiple(hand, cards, handSize)
  local newHand = copy(hand)
  for _, card in ipairs(cards) do
    if #newHand < handSize then
      newHand[#newHand+1] = card
    end
  end
  return newHand
end

-- NEW: one-step helper for drawing from a deck
function Hand.drawFromDeck(hand, deck, amount, handSize)
  local drawnCards, newDeck = Deck.drawMultiple(deck, amount)
  local newHand = Hand.drawMultiple(hand, drawnCards, handSize)
  return newHand, newDeck, drawnCards
end

function Hand.removeCardAt(hand, index)
  local newHand = {}
  for i, card in ipairs(hand) do
    if i ~= index then
      newHand[#newHand+1] = card
    end
  end
  return newHand
end

function Hand.removeById(hand, instanceId)
  local newHand = {}
  for _, card in ipairs(hand) do
    if card.instanceId ~= instanceId then
      newHand[#newHand+1] = card
    end
  end
  return newHand
end

--- Return a list of instanceIds from the given hand, in order.
-- @param hand (table) array of card objects (each with .instanceId)
-- @param excluding (string or table or nil) single id or set of ids to exclude
function Hand.getCurrentInstanceIds(hand, excluding)
  local out = {}

  -- Normalize the excluding param into a lookup table
  local excludeSet = nil
  if excluding ~= nil then
    if type(excluding) == "table" then
      excludeSet = {}
      for _, id in ipairs(excluding) do
        excludeSet[id] = true
      end
    else
      -- single id
      excludeSet = { [excluding] = true }
    end
  end

  for _, card in ipairs(hand) do
    if not excludeSet or not excludeSet[card.instanceId] then
      out[#out + 1] = card.instanceId
    end
  end

  return out
end

return Hand
