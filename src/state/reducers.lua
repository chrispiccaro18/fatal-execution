local Const     = require("const")
local copy = require("util.copy")

local Log = require("game_state.log")
local Hand = require("game_state.hand")

local TURN_PHASES = Const.TURN_PHASES
local ACTIONS = Const.DISPATCH_ACTIONS

local Reducers = {}

function Reducers.reduce(model, action)
  local newModel = copy(model)
  local uiIntents = {}
  local newTasks = {}

  if action.type == ACTIONS.BEGIN_TURN then
    newModel.turn.turnCount = newModel.turn.turnCount + 1
    newModel = Log.add(newModel, "--- Turn " .. newModel.turn.turnCount .. " begins ---")
    newModel.turn.phase = TURN_PHASES.IN_PROGRESS

    local cardsNeeded = newModel.handSize - #newModel.hand

    if cardsNeeded > 0 then
      local newHand, newDeck = Hand.drawFromDeck(
        newModel.hand,
        newModel.deck,
        cardsNeeded,
        newModel.handSize
      )
      newModel.hand = newHand
      newModel.deck = newDeck
    end
    -- append a resumable task; no immediate UI required
    -- table.insert(newTasks, { type="begin_turn", pc=1, args={} })
    return newModel, uiIntents, newTasks

  -- elseif action.type == "PLAY_CARD" then
  --   -- enqueue play-card task; the task will move the card, apply effects, schedule anims
  --   table.insert(tasks, { type="play_card", pc=1, args={ handIndex = action.idx } })
  --   return model, ui, tasks

  -- elseif action.type == "END_TURN" then
  --   table.insert(tasks, { type="end_turn", pc=1, args={} })
  --   return model, ui, tasks
  end

  return model, uiIntents, newTasks
end

return Reducers
