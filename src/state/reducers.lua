local Const            = require("const")
local immut            = require("util.immut")
local copy             = require("util.copy")
local deepcopy         = require("util.deepcopy")

local Log              = require("game_state.log")
local Hand             = require("game_state.hand")
local Deck             = require("game_state.deck")
local Effects          = require("game_state.derived.effects")
local AnimatingCards   = require("game_state.temp.animating_cards")

local TURN_PHASES      = Const.TURN_PHASES
local ACTIONS          = Const.DISPATCH_ACTIONS
local TASKS            = Const.TASKS
local LOG_OPTS         = Const.LOG
local EFFECTS_TRIGGERS = Const.EFFECTS_TRIGGERS
local UI_INTENTS       = Const.UI.INTENTS
local CARD_STATES      = Const.CARD_STATES

local Reducers         = {}

local function findTask(model, taskId)
  if not model.tasks then return nil end
  for _, task in ipairs(model.tasks) do
    if task.id == taskId then return task end
  end
  return nil
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
      local newAnimatingCards = deepcopy(newModel.animatingCards) or AnimatingCards.empty()
      for i, c in ipairs(newModel.hand) do
        c.state = CARD_STATES.ANIMATING
        c.selectable = false
        newAnimatingCards = AnimatingCards.add(newAnimatingCards, c, i)
      end

      card.state = CARD_STATES.ANIMATING
      card.selectable = false
      newAnimatingCards = AnimatingCards.add(newAnimatingCards, card, #newModel.hand + 1)
      newAnimatingCards = AnimatingCards.lift(newAnimatingCards, card.instanceId)
      newModel = immut.assign(newModel, "animatingCards", newAnimatingCards)
      newModel.deck = newDeck

      uiIntents[#uiIntents + 1] = {
        kind = UI_INTENTS.ANIMATE_DRAW_AND_REFLOW,
        newCardInstanceId = card.instanceId,
        existingInstanceIds = Hand.getCurrentInstanceIds(newModel.hand),
        finalSlotCount = #newModel.hand + 1,
        taskId = dealTask.id,
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
    local otherHandCardIds = action.existingInstanceIds or {}
    local newAnimatingCards = deepcopy(newModel.animatingCards)

    if #otherHandCardIds > 0 then
      for _, cardInstanceId in ipairs(otherHandCardIds) do
        newAnimatingCards = AnimatingCards.remove(newAnimatingCards, cardInstanceId)
      end
    end

    if drewCardId then
      local newHand = immut.copyArray(newModel.hand)
      local drewCard = AnimatingCards.get(newAnimatingCards, drewCardId)
      newHand[#newHand + 1] = drewCard
      newModel = immut.assign(newModel, "hand", newHand)
      newAnimatingCards = AnimatingCards.remove(newAnimatingCards, drewCardId)

      local name = (type(drewCard) == "table" and drewCard.name) or "Unknown Card"
      newModel = Log.add(newModel, ("Drew %s."):format(name), {
        category = LOG_OPTS.CATEGORY.CARD_DRAW,
        severity = LOG_OPTS.SEVERITY.INFO,
        visible  = true,
      })

      for _, c in ipairs(newModel.hand) do
        c.state = CARD_STATES.IDLE
        c.selectable = true
      end

      newModel = immut.assign(newModel, "animatingCards", newAnimatingCards)

      local dealTask = findTask(newModel, action.taskId)
      if dealTask then
        dealTask.remaining = dealTask.remaining - 1
        dealTask.inProgress = false
      end
    end
  end

  if action.type == ACTIONS.END_TURN then
    local turn    = copy(newModel.turn)
    turn.phase    = TURN_PHASES.END_TURN
    newModel.turn = turn
    print("Ending turn:", turn.turnCount)
  end

  if action.type == ACTIONS.PLAY_CARD then
    local handIndex = action.idx
    if handIndex < 1 or handIndex > #newModel.hand then
      error("Invalid hand index: " .. tostring(handIndex))
    end
    local card = newModel.hand[handIndex]
    if not card then
      error("No card found at index: " .. tostring(handIndex))
    end
    print("Playing card:", card.name)
  end

  if action.type == ACTIONS.DISCARD_CARD then
    local handIndex = action.idx
    if handIndex < 1 or handIndex > #newModel.hand then
      error("Invalid hand index: " .. tostring(handIndex))
    end
    local card = newModel.hand[handIndex]
    if not card then
      error("No card found at index: " .. tostring(handIndex))
    end
    print("Discarding card:", card.name)
  end

  return newModel, uiIntents, newTasks
end

return Reducers
