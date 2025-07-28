local Hand = {}

function Hand.init()
  return {}
end

function Hand.drawCard(hand, card, handSize)
  local newHand = {}
  for i, c in ipairs(hand) do newHand[i] = c end
  if #newHand < handSize then
    table.insert(newHand, card)
  end
  return newHand
end

function Hand.removeCardAt(hand, index)
  local newHand = {}
  for i, card in ipairs(hand) do
    if i ~= index then
      table.insert(newHand, card)
    end
  end
  return newHand
end

return Hand