local Const            = require("const")
local immut            = require("util.immut")
local copy             = require("util.copy")
local deepcopy         = require("util.deepcopy")

local Log              = require("game_state.log")
local Hand             = require("game_state.hand")
local Deck             = require("game_state.deck")
local DestructorDeck   = require("game_state.destructor_deck")
local Effects          = require("game_state.derived.effects")
local AnimatingCards   = require("game_state.temp.animating_cards")

local TURN_PHASES      = Const.TURN_PHASES
local ACTIONS          = Const.DISPATCH_ACTIONS
local TASKS            = Const.TASKS
local LOG_OPTS         = Const.LOG
local EFFECTS_TRIGGERS = Const.EFFECTS_TRIGGERS
local UI_INTENTS       = Const.UI.INTENTS
local CARD_STATES      = Const.CARD_STATES
local PLAY_EFFECT_TYPES = Const.PLAY_EFFECT_TYPES

local Reducers         = {}

local function findTask(model, taskId)
  if not model.tasks then return nil end
  for _, task in ipairs(model.tasks) do
    if task.id == taskId then return task end
  end
  return nil
end

local function createReflowMap(hand, handIndex)
  local reflowMap = {}
  if handIndex then
    local newHandIndex = 1
    for i = 1, #hand do
      if i ~= handIndex then
        reflowMap[newHandIndex] = hand[i].instanceId
        newHandIndex = newHandIndex + 1
      end
    end
  else
    for i = 1, #hand do
      reflowMap[i] = hand[i].instanceId
    end
  end
  return reflowMap
end

function Reducers.reduce(model, action)
  local newModel = copy(model)
  local uiIntents = {}
  local newTasks = {}

  if action.type == ACTIONS.LOG_DEBUG then
    newModel = Log.add(
      newModel,
      action.entry,
      { visible = false, category = action.category, severity = LOG_OPTS.SEVERITY.DEBUG }
    )
  end

  if action.type == ACTIONS.BEGIN_TURN then
    local turn          = copy(newModel.turn)
    turn.turnCount      = turn.turnCount + 1
    turn.phase          = TURN_PHASES.IN_PROGRESS
    newModel.turn       = turn
    newModel            = Log.add(newModel, "--- Turn " .. turn.turnCount .. " begins ---")

    newModel.ram        = 0

    local activeEffects = Effects.collectActive(newModel, EFFECTS_TRIGGERS.BEGIN_TURN)
    if #activeEffects > 0 then
      local slices = {
        handSize = newModel.handSize,
        ram      = newModel.ram,
        threats  = newModel.threats
      }
      local notes = {}

      for _, ctx in ipairs(activeEffects) do
        local note = nil
        slices, note = Effects.applySlices(slices, ctx)
        if note then
          notes[#notes + 1] = {
            entry = note.msg,
            opts = {
              category = LOG_OPTS.CATEGORY.EFFECT,
              severity = LOG_OPTS.SEVERITY.INFO,
              visible  = true, -- show to player; switch to false if you want hidden debug
              data     = { source = note.source, kind = note.kind, index = note.index, tag = note.tag },
            }
          }
        end
      end

      if slices.handSize ~= newModel.handSize then
        newModel = immut.assign(newModel, "handSize", slices.handSize)
      end
      if slices.ram ~= newModel.ram then
        newModel = immut.assign(newModel, "ram", slices.ram)
      end
      if slices.threats ~= newModel.threats then
        newModel = immut.assign(newModel, "threats", slices.threats)
      end

      if #notes > 0 then
        newModel = Log.addMany(newModel, notes)
      end
    end

    local handSize = newModel.handSize
    local have     = #newModel.hand
    local need     = math.max(0, handSize - have)

    if need > 0 then
      local taskId = os.time()
      newTasks[#newTasks + 1] = {
        id         = taskId,
        kind       = TASKS.DEAL_CARDS,
        remaining  = need,
        inProgress = false,
      }
    end

    return newModel, uiIntents, newTasks
  end

  if action.type == ACTIONS.DRAW_CARD then
    local dealTask = findTask(newModel, action.taskId)
    assert(dealTask, "DRAW_CARD action requires a valid taskId")
    dealTask.inProgress = true

    local card, newDeck = Deck.draw(newModel.deck)
    if card then
      -- Card is now in transit from deck to hand.
      local newSlotCount = #newModel.hand + 1
      local newAnimatingCards = AnimatingCards.add(newModel.animatingCards or AnimatingCards.empty(), card, newSlotCount)
      newModel = immut.assign(newModel, "animatingCards", newAnimatingCards)
      newModel = immut.assign(newModel, "deck", newDeck)

      card.selectable = false
      card.state = CARD_STATES.ANIMATING

      for _, c in ipairs(newModel.hand) do
        c.selectable = false
        c.state = CARD_STATES.ANIMATING
      end

      uiIntents[#uiIntents + 1] = {
        kind = UI_INTENTS.ANIMATE_DRAW_DECK_TO_HAND,
        newCardInstanceId = card.instanceId,
        newSlotCount = newSlotCount,
        taskId = dealTask.id,
      }

      uiIntents[#uiIntents + 1] = {
        kind = UI_INTENTS.ANIMATE_HAND_REFLOW,
        newSlotCount = newSlotCount,
        oldSlotCount = #newModel.hand,
        holeIndex = newSlotCount,
        reflowMap = createReflowMap(model.hand),
      }
    else
      Log.add(newModel, "Deck empty: couldn't draw a card.", {
        category = LOG_OPTS.CATEGORY.CARD_DRAW,
        severity = LOG_OPTS.SEVERITY.WARN,
        visible  = true,
      })
      dealTask.remaining = 0
      dealTask.inProgress = false
    end
  end

  if action.type == ACTIONS.FINISH_CARD_DRAW then
    local drewCardId = action.cardInstanceId
    local drewCard = AnimatingCards.get(newModel.animatingCards, drewCardId)

    if drewCard then
      -- Card has arrived. Move from animating to hand.
      local newHand = immut.copyArray(newModel.hand)
      newHand[#newHand + 1] = drewCard
      newModel = immut.assign(newModel, "hand", newHand)
      newModel = immut.assign(newModel, "animatingCards", AnimatingCards.remove(newModel.animatingCards, drewCardId))

      local name = (type(drewCard) == "table" and drewCard.name) or "Unknown Card"
      newModel = Log.add(newModel, ("Drew %s."):format(name), {
        category = LOG_OPTS.CATEGORY.CARD_DRAW,
        severity = LOG_OPTS.SEVERITY.INFO,
        visible  = true,
      })

      for _, c in ipairs(newModel.hand) do
        c.selectable = true
        c.state = CARD_STATES.IDLE
      end
    end

    local dealTask = findTask(newModel, action.taskId)
    if dealTask then
      dealTask.remaining = dealTask.remaining - 1
      dealTask.inProgress = false
    end
  end

  if action.type == ACTIONS.DISCARD_CARD then
    local handIndex = action.idx
    local card = newModel.hand[handIndex]
    if not card then error("No card at index " .. tostring(handIndex)) end

    local startingRam = model.ram
    newModel.ram = newModel.ram + card.cost

    if card.onDiscard then
      local discardActionType = card.onDiscard.type
      local discardActionAmount = card.onDiscard.amount or 0

      if discardActionType == Const.ON_DISCARD_EFFECT_TYPES.RAM_MULTIPLIER then
        newModel.ram = newModel.ram * discardActionAmount
      end
    end

    local ramDelta = math.abs(newModel.ram - startingRam)
    -- TODO: emit ram pulse with ramDelta

    -- Card is now in transit from hand to discard.
    -- 1. Remove from hand
    local newHand = Hand.removeById(newModel.hand, card.instanceId)
    newModel = immut.assign(newModel, "hand", newHand)

    card.selectable = false
    card.state = CARD_STATES.ANIMATING

    -- 2. Add to animatingCards
    local newAnimatingCards = AnimatingCards.add(newModel.animatingCards or AnimatingCards.empty(), card, handIndex) -- handIndex is irrelevant here
    newModel = immut.assign(newModel, "animatingCards", newAnimatingCards)

    -- 3. Create UI intents for the two separate animations
    uiIntents[#uiIntents + 1] = {
      kind = UI_INTENTS.ANIMATE_DISCARD_HAND_TO_DESTRUCTOR,
      discardedCardInstanceId = card.instanceId,
      discardedCardHandIndex = handIndex,
    }

    uiIntents[#uiIntents + 1] = {
      kind = UI_INTENTS.ANIMATE_HAND_REFLOW,
      newSlotCount = #newHand,
      oldSlotCount = #model.hand,
      holeIndex = handIndex,
      reflowMap = createReflowMap(model.hand, handIndex),
    }
  end

  if action.type == ACTIONS.FINISH_CARD_DISCARD then
    local discardedCardId = action.discardedCardInstanceId
    local discardedCard = AnimatingCards.get(newModel.animatingCards, discardedCardId)

    if discardedCard then
      -- Card has arrived. Move from animating to destructor deck.
      local newDestructorDeck = DestructorDeck.addBottom(newModel.destructorDeck, discardedCard)
      newModel = immut.assign(newModel, "destructorDeck", newDestructorDeck)
      newModel = immut.assign(newModel, "animatingCards", AnimatingCards.remove(newModel.animatingCards, discardedCardId))

      discardedCard.state = CARD_STATES.IDLE
      local cardName = discardedCard.name or "Unknown Card"
      newModel = Log.add(newModel, ("Discarded %s."):format(cardName), {
        category = LOG_OPTS.CATEGORY.CARD_DISCARD,
        severity = LOG_OPTS.SEVERITY.INFO,
        visible  = true,
      })
    end
  end

  if action.type == ACTIONS.PLAY_CARD then
    local handIndex = action.idx
    local card = newModel.hand[handIndex]
    if not card then error("No card at index " .. tostring(handIndex)) end

    if card.noPlay then
      newModel = Log.add(newModel, "Cannot play " .. card.name .. ".", {
        category = LOG_OPTS.CATEGORY.CARD_PLAY,
        severity = LOG_OPTS.SEVERITY.WARN,
        visible  = true,
      })
      -- TODO: emit card shake

    -- check if enough ram available
    elseif newModel.ram >= card.cost then
      newModel.ram = newModel.ram - card.cost

      -- Card is now in transit from hand to center of screen.
      -- 1. Remove from hand
      local newHand = Hand.removeById(newModel.hand, card.instanceId)
      newModel = immut.assign(newModel, "hand", newHand)

      card.selectable = false
      card.state = CARD_STATES.ANIMATING

      -- 2. Add to animatingCards
      local newAnimatingCards = AnimatingCards.add(newModel.animatingCards or AnimatingCards.empty(), card, handIndex)
      newModel = immut.assign(newModel, "animatingCards", newAnimatingCards)

      -- 3. Create task
      local taskId = os.time()
      newTasks[#newTasks + 1] = {
        id = taskId,
        kind = TASKS.PLAY_CARD,
        cardInstanceId = card.instanceId,
        inProgress = false,
        complete = false,
      }

      -- 4. Create UI intents for the two separate animations
      uiIntents[#uiIntents + 1] = {
        kind = UI_INTENTS.PLAY_CARD_TO_CENTER,
        playedCardInstanceId = card.instanceId,
        playedCardHandIndex = handIndex,
        taskId = taskId,
      }

      uiIntents[#uiIntents + 1] = {
        kind = UI_INTENTS.ANIMATE_HAND_REFLOW,
        newSlotCount = #newHand,
        oldSlotCount = #model.hand,
        holeIndex = handIndex,
        reflowMap = createReflowMap(model.hand, handIndex),
      }
    else
      newModel = Log.add(newModel, "Not enough RAM to play " .. card.name .. ".", {
        category = LOG_OPTS.CATEGORY.CARD_PLAY,
        severity = LOG_OPTS.SEVERITY.WARN,
        visible  = true,
      })

      -- TODO: emit some sort of RAM pulse
    end
  end

  if action.type == ACTIONS.PLAYED_CARD_IN_CENTER then
    local playedCardInstanceId = action.playedCardInstanceId
    local taskId = action.taskId

    local playedCard = AnimatingCards.get(newModel.animatingCards, playedCardInstanceId)
    local playEffectType = playedCard.playEffect and playedCard.playEffect.type or nil
    local playEffectAmount = playedCard.playEffect and playedCard.playEffect.amount or nil
    local playEffectAmountString = playEffectAmount and tostring(playEffectAmount) or "N/A"

    if playEffectType == PLAY_EFFECT_TYPES.PROGRESS then
      print("Progressing by " .. playEffectAmountString .. " by card: " .. playedCard.name)
    elseif playEffectType == PLAY_EFFECT_TYPES.THREAT then
      print("Threatening by " .. playEffectAmountString .. " by card: " .. playedCard.name)
    elseif playEffectType == PLAY_EFFECT_TYPES.SHUFFLE_DISRUPTOR then
      print("Shuffling destructor deck by card: " .. playedCard.name .. " " .. playEffectAmountString)
      -- newModel.deck = Deck.shuffleDisruptor(newModel.deck)
      -- newModel = Log.add(newModel, "Destructor Deck shuffled.", {
      --   category = LOG_OPTS.CATEGORY.CARD_PLAY,
      --   severity = LOG_OPTS.SEVERITY.INFO,
      --   visible  = true,
      -- })
      -- TODO: emit some sort of destructor deck shuffle animation
    elseif playEffectType == PLAY_EFFECT_TYPES.DRAW then
      print("Drawing cards by card: " .. playedCard.name .. " " .. playEffectAmountString)
    elseif playEffectType == PLAY_EFFECT_TYPES.NULLIFY_DESTRUCTOR then
      print("Nullifying destructor effect by card: " .. playedCard.name .. " " .. playEffectAmountString)
    elseif playEffectType == PLAY_EFFECT_TYPES.NONE then
      print("No effect by card: " .. playedCard.name .. " " .. playEffectAmountString)
    end
  end

  if action.type == ACTIONS.PLAYED_CARD_IN_DECK then
    local playedCardInstanceId = action.playedCardInstanceId
    local taskId = action.taskId
    local playedCard = AnimatingCards.get(newModel.animatingCards, playedCardInstanceId)

    if playedCard then
      local newDeck = Deck.placeOnBottom(newModel.deck, playedCard)
      newModel = immut.assign(newModel, "deck", newDeck)
      newModel = immut.assign(newModel, "animatingCards", AnimatingCards.remove(newModel.animatingCards, playedCardInstanceId))
      playedCard.state = CARD_STATES.IDLE
    end

    local task = findTask(newModel, taskId)
    if task then
      task.complete = true
      task.inProgress = false
    end
  end

  if action.type == ACTIONS.TASK_IN_PROGRESS then
    local task = findTask(newModel, action.taskId)
    assert(task, "[reducers TASK_IN_PROGRESS]: Task not found: " .. tostring(action.taskId))
    task.inProgress = true
  end

  return newModel, uiIntents, newTasks
end

return Reducers
