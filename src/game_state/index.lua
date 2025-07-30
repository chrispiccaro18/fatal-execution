local GameState = {}
local Deck = require("game_state.deck")
local Hand = require("game_state.hand")
local Systems = require("game_state.systems")
local DestructorQueue = require("game_state.destructor_queue")
local Threat = require("game_state.threat")

local Decorators = require("ui.decorators")


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
    envEffect = "No special effect.",
    uiTransitions = {},
  }
end

-- UI Transitions
function GameState.enqueueTransition(state, type, payload)
  local newState = GameState.shallowCopy(state)
  table.insert(newState.uiTransitions, {
    type = type,
    payload = payload
  })
  return newState
end

function GameState.applyTransition(state, transition)
  local newState = GameState.shallowCopy(state)

  if transition.type == "draw" then
    local card = transition.payload.card
    card.selectable = true
    card.state = "idle"

    -- local newHand = Hand.drawCard(state.hand, card, state.handSize)
    -- newState.hand = newHand
    table.insert(newState.hand, card)

    newState = GameState.addLog(newState, "Drew card: " .. card.name)

  elseif transition.type == "discard" then
    local card = transition.payload.card
    local index = transition.payload.handIndex
    card.state = "idle"

    local newHand = Hand.removeCardAt(state.hand, index)
    local newDestructorQueue = DestructorQueue.enqueue(state.destructorQueue, card)

    newState.hand = newHand
    newState.destructorQueue = newDestructorQueue
    newState.ram = state.ram + transition.payload.amount
    Decorators.emit("ramPulse", { amount = transition.payload.amount })

  elseif transition.type == "play" then
    local card = transition.payload.card
    local index = transition.payload.handIndex
    card.state = "idle"

    local newHand = Hand.removeCardAt(state.hand, index)
    local newDeck = Deck.placeOnBottom(state.deck, card)
    newState.hand = newHand
    newState.deck = newDeck
    -- newState.ram = state.ram - card.cost
    -- newState = GameState.addLog(newState, "Played card: " .. card.name)

    if card.playEffect and card.playEffect.type == "progress" then
      newState.systems = Systems.incrementProgress(
        state.systems,
        state.currentSystemIndex,
        card.playEffect.amount
      )
      newState = GameState.updateCurrentSystemIndex(newState)
    end

    if card.playEffect and card.playEffect.type == "threat" then
      newState.threat = Threat.increment(state.threat, card.playEffect.amount)
    end

    if GameState.checkWinCondition(newState) then
      newState.turn.phase = "won"
      newState = GameState.addLog(newState, "== ALL SYSTEMS RESTORED ==")
    end
  elseif transition.type == "destructorPlay" then
    local updatedQueue = transition.payload.updatedQueue
    newState.destructorQueue = updatedQueue

    local card = transition.payload.card
    local amount = card.destructorEffect.amount

    if card.destructorEffect.type == "threat" then
      newState.threat = Threat.increment(state.threat, amount)
      newState = GameState.addLog(newState, "Destructor triggered: +" .. amount .. " threat.")
    elseif card.destructorEffect.type == "progress" then
      newState.systems = Systems.incrementProgress(
        state.systems,
        state.currentSystemIndex,
        amount
      )
      newState = GameState.addLog(newState, "Destructor triggered: " .. amount .. " progress.")
      newState = GameState.updateCurrentSystemIndex(newState)
    end

    newState.deck = Deck.placeOnBottom(newState.deck, card)

    newState = GameState.checkLossCondition(newState)
    newState = GameState.beginTurn(newState)
  end

  return newState
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
      newState = GameState.addLog(newState,
                                  "System " ..
                                  currentSystem.name ..
                                  " completed. Moving to " .. newState.systems[newState.currentSystemIndex].name .. ".")

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
  end

  return newState
end

function GameState.beginTurn(state)
  local newState = GameState.shallowCopy(state)
  newState.turn.phase = "start"


  newState.ram = 0
  if state.envEffect == "Gain 1 RAM at start of turn" then
    newState.ram = newState.ram + 1
    Decorators.emit("ramPulse", { amount = 1 })
  end
  newState.turn.turnCount = newState.turn.turnCount + 1
  newState = GameState.addLog(newState, "-- Turn " .. newState.turn.turnCount .. " begins --")

  -- calculate how many cards to draw based on hand size
  local numCardsToDraw = newState.handSize - #newState.hand
  if numCardsToDraw < 0 then
    numCardsToDraw = 0
  end

  for i = 1, numCardsToDraw do
    local virtualIndex = #newState.hand + i
    newState = GameState.drawCard(newState, virtualIndex)
  end

  newState.turn.phase = "in_progress"

  return newState
end

function GameState.endTurn(state)
  local newState = GameState.shallowCopy(state)

  newState.turn.phase = "end_turn"
  local destructorCard, updatedQueue = DestructorQueue.dequeue(state.destructorQueue)

  if not destructorCard then
    newState = GameState.addLog(newState, "Destructor queue is empty :)")
    newState = GameState.beginTurn(newState)
    return newState
  end

  newState = GameState.enqueueTransition(newState, "destructorPlay", {
    card = destructorCard,
    updatedQueue = updatedQueue
  })
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

function GameState.drawCard(state, intendedIndex)
  local newState = GameState.shallowCopy(state)
  local card, newDeck = Deck.draw(state.deck)

  if not card then
    newState = GameState.addLog(newState, "Deck is empty, cannot draw a card.")
    return newState
  end

  newState.deck = newDeck

  newState = GameState.enqueueTransition(newState, "draw", {
    card = card,
    index = intendedIndex
  })

  -- newState = GameState.addLog(newState, "Drew card: " .. card.name)
  return newState
end

function GameState.discardCardForRam(state, index)
  local newState = GameState.shallowCopy(state)
  local card = state.hand[index]

  GameState.enqueueTransition(state, "discard", {
    card = card,
    handIndex = index,
    amount = card.cost
  })

  newState = GameState.addLog(newState, "Discarded " .. card.name .. " for " .. card.cost .. " RAM.")
  return newState
end

function GameState.playCard(state, index)
  local newState = GameState.shallowCopy(state)
  local card = state.hand[index]

  if state.ram < card.cost then
    newState = GameState.addLog(newState, "Not enough RAM to play " .. card.name .. ".")
    return newState
  end

  newState = GameState.addLog(newState, "Played card: " .. card.name)
  newState.ram = newState.ram - card.cost

  newState = GameState.enqueueTransition(newState, "play", {
    card = card,
    handIndex = index
  })

  return newState
end

function GameState.addLog(state, entry)
  local newState = GameState.shallowCopy(state)
  table.insert(newState.log, entry)
  Decorators.emit("logGlow", { message = entry })
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
