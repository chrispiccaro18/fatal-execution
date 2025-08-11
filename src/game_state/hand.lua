local copy = require("util.copy")
local Deck = require("game_state.deck")

-- state.hand, state.deck, drawn = Hand.drawFromDeck(state.hand, state.deck, amount, state.handSize)

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

function Hand.removeById(hand, cardId)
  local newHand = {}
  for _, card in ipairs(hand) do
    if card.id ~= cardId then
      newHand[#newHand+1] = card
    end
  end
  return newHand
end

return Hand
