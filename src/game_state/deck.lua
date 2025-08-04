local starterCards = require("cards.starter_cards")

local Deck = {}

local function shuffle(t)
  local n = #t
  for i = n, 2, -1 do
    local j = math.random(1, i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end

function Deck.init()
  return shuffle(starterCards)
end

function Deck.draw(deck)
  local newDeck = {}
  for i = 2, #deck do
    table.insert(newDeck, deck[i])
  end
  return deck[1], newDeck
end

function Deck.drawMultiple(deck, amount)
  local drawnCards = {}
  local newDeck = {}
  for i = 1, #deck do
    if #drawnCards < amount then
      table.insert(drawnCards, deck[i])
    else
      table.insert(newDeck, deck[i])
    end
  end
  return drawnCards, newDeck
end

function Deck.placeOnBottom(deck, card)
  local newDeck = {}
  for i = 1, #deck do
    table.insert(newDeck, deck[i])
  end
  table.insert(newDeck, card)
  return newDeck
end

return Deck