local GameState = {}
local Deck = require("game_state.deck")
local Hand = require("game_state.hand")
local Systems = require("game_state.systems")
local DestructorQueue = require("game_state.destructor_queue")
local Threat = require("game_state.threat")

function GameState.init()
  return {
    deck = Deck.init(),
    hand = Hand.init(),
    handSize = 4,
    systems = Systems.init(),
    destructorQueue = DestructorQueue.init(),
    ram = 0,
    turn = {
      phase = "start",
      turnCount = 0
    },
    threat = Threat.init(),
    log = {},
    currentSystemIndex = 1,
    envEffect = "No special effect."
  }
end

function GameState.updateCurrentSystemIndex(state)
  local newState = GameState.shallowCopy(state)
  local currentSystem = newState.systems[newState.currentSystemIndex]

  if currentSystem.progress >= 0 and currentSystem.progress < currentSystem.required then
    return newState
  end

  if currentSystem.progress >= currentSystem.required then
    if newState.currentSystemIndex < #newState.systems then
      newState.currentSystemIndex = newState.currentSystemIndex + 1
      newState = GameState.addLog(newState, "System " .. currentSystem.name .. " completed. Moving to " .. newState.systems[newState.currentSystemIndex].name .. ".")

      local newEnvEffect = currentSystem.envEffect
      newState.envEffect = newEnvEffect
      if newEnvEffect == "Hand size increased by 1" then
        newState.handSize = newState.handSize + 1
      end
    end
    return newState
  end

  if currentSystem.progress < 0 then
    newState.systems[newState.currentSystemIndex].progress = 0
  --   if newState.currentSystemIndex == 1 then
  --     return newState
  --   end

  --   newState.currentSystemIndex = newState.currentSystemIndex - 1
  --   local prevSystem = newState.systems[newState.currentSystemIndex]
  --   prevSystem.progress = prevSystem.required + currentSystem.progress
  --   if prevSystem.progress < 0 then
  --     prevSystem.progress = 0 -- prevent double system reversions
  --   end
  --   newState.systems[newState.currentSystemIndex] = prevSystem
  --   newState = GameState.addLog(newState, "Reverted to previous system: " .. prevSystem.name)
  end

  return newState
end

function GameState.beginTurn(state)
  local newState = GameState.shallowCopy(state)

  newState.ram = 0
  if state.envEffect == "Gain 1 RAM at start of turn" then
    newState.ram = newState.ram + 1
  end
  newState.turn.turnCount = newState.turn.turnCount + 1
  newState = GameState.addLog(newState, "-- Turn " .. newState.turn.turnCount .. " begins --")

  while #newState.hand < newState.handSize and #newState.deck > 0 do
    newState = GameState.drawCard(newState)
  end

  return newState
end

function GameState.endTurn(state)
  local newState = GameState.shallowCopy(state)

  local destructorCard, updatedQueue = DestructorQueue.dequeue(state.destructorQueue)
  newState.destructorQueue = updatedQueue

  if not destructorCard then
    newState = GameState.addLog(newState, "Destructor queue is empty :)")
    return newState
  end

  local amount = destructorCard.destructorEffect.amount
  if destructorCard.destructorEffect and destructorCard.destructorEffect.type == "threat" then
    newState.threat = Threat.increment(state.threat, amount)
    newState = GameState.addLog(newState, "Destructor triggered: +" .. amount .. " threat.")
  elseif destructorCard.destructorEffect and destructorCard.destructorEffect.type == "progress" then
    newState.systems = Systems.incrementProgress(
      state.systems,
      state.currentSystemIndex,
      destructorCard.destructorEffect.amount
    )
    newState = GameState.addLog(newState, "Destructor triggered: " .. amount .. " progress.")
    newState = GameState.updateCurrentSystemIndex(newState)
  end
  newState.deck = Deck.placeOnBottom(newState.deck, destructorCard)

  newState = GameState.checkLossCondition(newState)
  return newState
end

function GameState.checkWinCondition(state)
  local system = state.systems[state.currentSystemIndex]
  if system.progress >= system.required then
    if state.currentSystemIndex == #state.systems then
      return true -- final system complete
    end
  end
  return false
end

function GameState.checkLossCondition(state)
  if state.threat.value >= state.threat.max then
    state = GameState.addLog(state, "!! SYSTEM FAILURE: Threat Level Exceeded !!")
    state.turn.phase = "lost"
  end
  return state
end

function GameState.drawCard(state)
  local newState = GameState.shallowCopy(state)
  local card, newDeck = Deck.draw(state.deck)
  local newHand = Hand.drawCard(state.hand, card, state.handSize)

  newState.deck = newDeck
  newState.hand = newHand

  newState = GameState.addLog(newState, "Drew card: " .. card.name)
  return newState
end

function GameState.discardCardForRam(state, index)
  local newState = GameState.shallowCopy(state)
  local card = state.hand[index]

  newState.ram = newState.ram + card.cost
  newState.hand = Hand.removeCardAt(state.hand, index)
  newState.destructorQueue = DestructorQueue.enqueue(state.destructorQueue, card)

  newState = GameState.addLog(newState, "Discarded " .. card.name .. " for " .. card.cost .. " RAM.")
  return newState
end

function GameState.playCard(state, index)
  local card = state.hand[index]
  if state.ram < card.cost then
    return state -- not enough RAM, do nothing
  end

  
  local newState = GameState.shallowCopy(state)

  newState = GameState.addLog(newState, "Played card: " .. card.name)
  newState.ram = newState.ram - card.cost
  newState.hand = Hand.removeCardAt(state.hand, index)

  if card.playEffect and card.playEffect.type == "progress" then
    newState.systems = Systems.incrementProgress(
      state.systems,
      state.currentSystemIndex,
      card.playEffect.amount
    )
    newState = GameState.updateCurrentSystemIndex(newState)
  end

  if card.playEffect and card.playEffect.type == "threat" then
    local amount = card.playEffect.amount
    newState.threat = Threat.increment(state.threat, amount)
  end

  newState.deck = Deck.placeOnBottom(newState.deck, card)

  -- Check win condition after playing
  if GameState.checkWinCondition(newState) then
    newState.turn.phase = "won"
    newState = GameState.addLog(newState, "== ALL SYSTEMS RESTORED ==")
  end

  return newState
end

function GameState.addLog(state, entry)
  local newState = GameState.shallowCopy(state)
  table.insert(newState.log, entry)
  return newState
end

function GameState.shallowCopy(tbl)
  local copy = {}
  for k, v in pairs(tbl) do
    copy[k] = v
  end
  return copy
end

return GameState
