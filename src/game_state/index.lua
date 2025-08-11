-- local Const = require("const")
-- local defaultGameState = require("data.default_game_state")
-- local Deck = require("game_state.deck")
-- local Hand = require("game_state.hand")
-- local Systems = require("game_state.systems")
-- local DestructorQueue = require("game_state.destructor_queue")
-- local Threat = require("game_state.threat")
-- local Log = require("game_state.log")
-- local ActiveProfile = require("profiles.active")
-- local Profiles = require("profiles")
-- local RunLogger = require("profiles.run_logger")

-- local Effects = require("game_state.derived.effects")

-- local EventSystem = require("events.index")
-- local Decorators = require("ui.decorators")

-- local GameState = {}

-- function GameState.init(seed)
--   return defaultGameState.init(seed)
-- end

-- -- UI Transitions
-- function GameState.enqueueTransition(state, type, payload)
--   local newState = GameState.shallowCopy(state)
--   table.insert(newState.uiTransitions, {
--     type = type,
--     payload = payload
--   })
--   return newState
-- end

-- function GameState.applyTransition(state, transition)
--   local newState = GameState.shallowCopy(state)

--   if transition.type == "draw" then
--     local cardsToDraw = transition.payload.cardsToDraw
--     local newDeck = transition.payload.newDeck
--     local requestedNumberOfCardsToDraw = transition.payload.requestedNumberOfCardsToDraw

--     if cardsToDraw then
--       for _, drawnCard in ipairs(cardsToDraw) do
--         table.insert(newState.hand, drawnCard)
--         newState = Log.addEntry(newState, "Drew card: " .. drawnCard.name)
--       end
--       newState.deck = newDeck
--     end

--     if not cardsToDraw or #cardsToDraw == 0 then
--       newState = Log.addEntry(newState, "Deck is empty, could not draw any cards.")
--     elseif #cardsToDraw < requestedNumberOfCardsToDraw then
--       newState = Log.addEntry(newState, "Deck is empty, could not draw all cards.")
--     end
--   elseif transition.type == "discard" then
--     local card = transition.payload.card
--     local index = transition.payload.handIndex
--     card.state = "idle"

--     local newHand = Hand.removeCardAt(state.hand, index)
--     local newDestructorQueue = DestructorQueue.enqueue(state.destructorQueue, card)

--     newState.hand = newHand
--     newState.destructorQueue = newDestructorQueue
--     newState.ram = state.ram + transition.payload.amount

--     if card.onDiscard then
--       local discardEffect = card.onDiscard
--       if discardEffect.type == "ram_multiplier" then
--         newState.ram = newState.ram * discardEffect.amount
--       end
--     end

--     Decorators.emit("ramPulse")
--   elseif transition.type == "play" then
--     local card = transition.payload.card
--     local index = transition.payload.handIndex
--     card.state = "idle"

--     local newHand = Hand.removeCardAt(state.hand, index)
--     local newDeck = Deck.placeOnBottom(state.deck, card)
--     newState.hand = newHand
--     newState.deck = newDeck

--     if card.playEffect and card.playEffect.type == "progress" then
--       newState.systems = Systems.incrementProgress(
--         state.systems,
--         state.currentSystemIndex,
--         card.playEffect.amount
--       )
--       newState = GameState.updateCurrentSystemIndex(newState)
--     end

--     if card.playEffect and card.playEffect.type == "threat" then
--       newState.threat = Threat.increment(state.threat, card.playEffect.amount)
--       Decorators.emit("threatPulse")
--     end

--     if card.playEffect and card.playEffect.type == "shuffle_disruptor" then
--       newState.destructorQueue = DestructorQueue.shuffleDisruptor(
--         newState.destructorQueue
--       )
--       Decorators.emit("destructorShuffle")
--     end

--     if card.playEffect and card.playEffect.type == "draw" then
--       local cardsToDraw = transition.payload.cardsToDraw
--       local newDeckAfterDraws = transition.payload.newDeckAfterDraws

--       if cardsToDraw then
--         for _, drawnCard in ipairs(cardsToDraw) do
--           table.insert(newState.hand, drawnCard)
--           newState = Log.addEntry(newState, "Drew card: " .. drawnCard.name)
--         end
--         newState.deck = newDeckAfterDraws
--       end

--       if not cardsToDraw or #cardsToDraw == 0 then
--         newState = Log.addEntry(newState, "Deck is empty, could not draw any cards.")
--       elseif #cardsToDraw < card.playEffect.amount then
--         newState = Log.addEntry(newState, "Deck is empty, could not draw all requested cards.")
--       end
--     end

--     if card.playEffect and card.playEffect.type == "nullify_destructor" then
--       newState.destructorNullify = newState.destructorNullify + card.playEffect.amount
--       newState = Log.addEntry(newState, "Destructor nullified +1. Total: " .. newState.destructorNullify)
--     end

--     if GameState.checkWinCondition(newState) then
--       newState.turn.phase = "won"
--       newState = Log.addEntry(newState, "== ALL SYSTEMS RESTORED ==")
--       EventSystem.emit("gameOver", "won")
--     end
--   elseif transition.type == "destructorPlay" then
--     local updatedQueue = transition.payload.updatedQueue
--     newState.destructorQueue = updatedQueue

--     local card = transition.payload.card
--     local amount = card.destructorEffect.amount

--     if transition.payload.hasNullify then
--       -- emit nullify decorator
--       Decorators.emit("cardShake", { cardId = card.name })
--       newState.destructorNullify = newState.destructorNullify - 1
--       newState = Log.addEntry(newState, "Destructor nullified, no effect applied.")

--     elseif card.destructorEffect.type == "threat" then
--       newState.threat = Threat.increment(state.threat, amount)
--       newState = Log.addEntry(newState, "Destructor triggered: +" .. amount .. " threat.")
--       Decorators.emit("threatPulse")
--     elseif card.destructorEffect.type == "progress" then
--       newState.systems = Systems.incrementProgress(
--         state.systems,
--         state.currentSystemIndex,
--         amount
--       )
--       newState = Log.addEntry(newState, "Destructor triggered: " .. amount .. " progress.")
--       newState = GameState.updateCurrentSystemIndex(newState)
--     elseif card.destructorEffect.type == "draw_to_destructor" then
--       local cardToDraw = transition.payload.cardToDestructor
--       if not cardToDraw then
--         newState = Log.addEntry(newState, "Deck is empty, cannot draw a card to Destructor")
--       else
--         local newDeck = transition.payload.newDeckAfterDrawToDestructor
--         newState = Log.addEntry(newState, "Destructor triggered: " .. cardToDraw.name .. " added to Destructor.")
--         newState.deck = newDeck
--         newState.destructorQueue = DestructorQueue.enqueue(updatedQueue, cardToDraw)
--       end
--     elseif card.destructorEffect.type == "threat_multiplier" then
--       newState.threat = Threat.set(state.threat, amount * state.threat.value)
--       newState = Log.addEntry(newState, "Destructor triggered: " .. amount .. "x threat multiplier applied.")
--       Decorators.emit("threatPulse")
--     end

--     newState.deck = Deck.placeOnBottom(newState.deck, card)

--     newState = Effects.resolveActiveEffects(newState, Const.EFFECTS_TRIGGERS.END_OF_TURN)

--     newState = GameState.checkLossCondition(newState)

--     local phase = love.gameState.turn.phase
--     if not (phase == "won" or phase == "lost") then
--       newState = GameState.beginTurn(newState)
--     end
--   end

--   return newState
-- end

-- function GameState.updateCurrentSystemIndex(state)
--   local newState = GameState.shallowCopy(state)
--   local currentSystem = newState.systems[newState.currentSystemIndex]

--   if currentSystem.progress >= 0 and currentSystem.progress < currentSystem.required then
--     return newState
--   end

--   if currentSystem.progress >= currentSystem.required then
--     -- Check if this system hasn’t been activated yet
--     if not currentSystem.activated then
--       -- currentSystem.activated = true
--       newState.systems[newState.currentSystemIndex].activated = true
--       newState = Effects.resolveActiveEffects(newState, Const.EFFECTS_TRIGGERS.IMMEDIATE)
--     end

--     -- Advance to next system if there is one
--     if newState.currentSystemIndex < #newState.systems then
--       newState.currentSystemIndex = newState.currentSystemIndex + 1
--       newState = Log.addEntry(newState,
--                                   "System " .. currentSystem.name .. " completed. Moving to " ..
--                                   newState.systems[newState.currentSystemIndex].name .. ".")
--     end

--     return newState
--   end

--   -- Clamp negative progress to 0
--   if currentSystem.progress < 0 then
--     newState.systems[newState.currentSystemIndex].progress = 0
--   end

--   return newState
-- end

-- function GameState.beginTurn(state)
--   -- love.gameState = state
--   local newState = GameState.shallowCopy(state)
--   newState.turn.phase = "start"
--   -- SAVE HERE
--   Profiles.setCurrentRun(ActiveProfile.get(), newState)
--   RunLogger.updateCurrent(newState)

--   newState.ram = 0
--   newState = Effects.resolveActiveEffects(newState, Const.EFFECTS_TRIGGERS.START_OF_TURN)
--   newState.turn.turnCount = newState.turn.turnCount + 1
--   newState = Log.addEntry(newState, "-- Turn " .. newState.turn.turnCount .. " begins --")

--   -- calculate how many cards to draw based on hand size
--   local requestedNumberOfCardsToDraw = newState.handSize - #newState.hand
--   if requestedNumberOfCardsToDraw < 0 then
--     requestedNumberOfCardsToDraw = 0
--   end

--   local cardsToDraw, newDeck = Deck.drawMultiple(newState.deck, requestedNumberOfCardsToDraw)

--   for i = 1, #cardsToDraw do
--     local drawnCard = cardsToDraw[i]
--     drawnCard.selectable = false
--     drawnCard.state = "animating"
--   end

--   newState = GameState.enqueueTransition(newState, "draw", {
--     cardsToDraw = cardsToDraw,
--     newDeck = newDeck,
--     requestedNumberOfCardsToDraw = requestedNumberOfCardsToDraw
--   })

--   newState.turn.phase = "in_progress"

--   return newState
-- end

-- function GameState.endTurn(state)
--   local newState = GameState.shallowCopy(state)

--   newState.turn.phase = "end_turn"
--   local destructorCard, updatedQueue = DestructorQueue.dequeue(state.destructorQueue)

--   if not destructorCard then
--     newState = Log.addEntry(newState, "Destructor queue is empty :)")
--     if state.destructorNullify > 0 then
--       newState.destructorNullify = state.destructorNullify - 1
--       newState = Log.addEntry(newState, "Destructor nullified, but no card played.")
--     end
--     newState = GameState.beginTurn(newState)
--     return newState
--   end

--   local cardToDestructor = nil
--   local newDeckAfterDrawToDestructor = nil
--   if destructorCard.destructorEffect.type == "draw_to_destructor" then
--     -- check to see if deck has a card to draw
--     local cardToDraw, newDeck = Deck.draw(state.deck)
--     if cardToDraw then
--       cardToDestructor = cardToDraw
--       newDeckAfterDrawToDestructor = newDeck
--     end
--   end

--   newState = GameState.enqueueTransition(newState, "destructorPlay", {
--     card = destructorCard,
--     updatedQueue = updatedQueue,
--     cardToDestructor = cardToDestructor,
--     newDeckAfterDrawToDestructor = newDeckAfterDrawToDestructor,
--     hasNullify = state.destructorNullify > 0
--   })
--   return newState
-- end

-- function GameState.checkWinCondition(state)
--   local system = state.systems[state.currentSystemIndex]
--   if system.progress >= system.required then
--     if state.currentSystemIndex == #state.systems then
--       return true -- final system complete
--     end
--   end
--   return false
-- end

-- function GameState.checkLossCondition(state)
--   if state.threat.value >= state.threat.max then
--     state = Log.addEntry(state, "!! SYSTEM FAILURE: Threat Level Exceeded !!")
--     state.turn.phase = "lost"
--     EventSystem.emit("gameOver", "lost")
--   end
--   return state
-- end

-- function GameState.discardCardForRam(state, index)
--   local newState = GameState.shallowCopy(state)
--   local card = state.hand[index]

--   GameState.enqueueTransition(state, "discard", {
--     card = card,
--     handIndex = index,
--     amount = card.cost
--   })

--   if card.onDiscard then
--     local discardEffect = card.onDiscard
--     local discardText = "Discarded " .. card.name .. ": " .. discardEffect.type
--     if discardEffect.amount then
--       discardText = discardText .. " " .. discardEffect.amount
--     end
--     newState = Log.addEntry(newState, discardText)
--   else
--     newState = Log.addEntry(newState, "Discarded " .. card.name .. " for " .. card.cost .. " RAM.")
--   end

--   return newState
-- end

-- function GameState.playCard(state, index)
--   local newState = GameState.shallowCopy(state)
--   local card = state.hand[index]

--   if card.noPlay then
--     newState = Log.addEntry(newState, "Cannot play " .. card.name .. ". Can only discard.")
--     return newState
--   end

--   if state.ram < card.cost then
--     newState = Log.addEntry(newState, "Not enough RAM to play " .. card.name .. ".")
--     return newState
--   end

--   newState = Log.addEntry(newState, "Played card: " .. card.name)
--   newState.ram = newState.ram - card.cost
--   Decorators.emit("ramPulse")

--   local cardsToDraw = nil
--   local newDeckAfterDraws = nil
--   if card.playEffect.type == "draw" then
--     local amountToDraw = card.playEffect.amount
--     cardsToDraw, newDeckAfterDraws = Deck.drawMultiple(state.deck, amountToDraw)

--     for i = 1, #cardsToDraw do
--       local drawnCard = cardsToDraw[i]
--       drawnCard.selectable = false
--       drawnCard.state = "animating"
--     end
--   end

--   newState = GameState.enqueueTransition(newState, "play", {
--     card = card,
--     handIndex = index,
--     cardsToDraw = cardsToDraw,
--     newDeckAfterDraws = newDeckAfterDraws
--   })

--   return newState
-- end

-- function GameState.shallowCopy(tbl)
--   local copy = {}
--   for k, v in pairs(tbl) do
--     copy[k] = v
--   end
--   return copy
-- end

-- return GameState
