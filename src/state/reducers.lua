local Const       = require("const")
local copy        = require("util.copy")

local Log         = require("game_state.log")
local Hand        = require("game_state.hand")

local TURN_PHASES = Const.TURN_PHASES
local ACTIONS     = Const.DISPATCH_ACTIONS
local TASKS       = Const.TASKS
local LOG_OPTS    = Const.LOG

local Reducers    = {}

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
    local turn     = copy(newModel.turn)
    turn.turnCount = turn.turnCount + 1
    turn.phase     = TURN_PHASES.IN_PROGRESS
    newModel.turn  = turn
    newModel       = Log.add(newModel, "--- Turn " .. turn.turnCount .. " begins ---")

    local handSize = newModel.handSize
    local have     = #newModel.hand
    local need     = math.max(0, handSize - have)

    -- Queue a small “deal” task that emits one DRAW_CARD per tick
    if need > 0 then
      newTasks[#newTasks + 1] = {
        kind      = TASKS.DEAL_CARDS,
        remaining = need,
        interval  = 1.0, -- sequential
        timer     = 0,
      }
    end

    return newModel, uiIntents, newTasks
  end

  if action.type == ACTIONS.DRAW_CARD then
    local handSize = newModel.handSize
    local newHand, newDeck, drawn = Hand.drawFromDeck(
      newModel.hand,
      newModel.deck,
      1,
      handSize
    )
    newModel.hand = newHand
    newModel.deck = newDeck

    if #drawn > 0 then
      local card = drawn[1]
      local name = (type(card) == "table" and card.name) or "Unknown Card"
      newModel = Log.add(newModel, ("Drew %s."):format(name), {
        category = LOG_OPTS.CATEGORY.CARD_DRAW,
        severity = LOG_OPTS.SEVERITY.INFO,
        visible  = true,
      })
    else
      newModel = Log.add(newModel, "Deck empty: couldn't draw a card.", {
        category = LOG_OPTS.CATEGORY.CARD_DRAW,
        severity = LOG_OPTS.SEVERITY.WARN,
        visible  = true,
      })
    end
  end

  return newModel, uiIntents, newTasks
end

return Reducers
