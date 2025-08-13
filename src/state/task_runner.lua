local Const      = require("const")
local UI         = require("state.ui")
local Deck       = require("game_state.deck")
local Log        = require("game_state.log")

local TASKS      = Const.TASKS
local ACTIONS    = Const.DISPATCH_ACTIONS
local LOG_OPTS   = Const.LOG

local TaskRunner = {}

local function step_begin_turn(model, view, task, produced, ui)
  if task.pc == 1 then
    model.ram = 0
    model.turn.turnCount = model.turn.turnCount + 1
    Log.add(model, "-- Turn " .. model.turn.turnCount .. " begins --")
    task.pc = 2
  elseif task.pc == 2 then
    local missing = model.handSize - #model.hand
    if missing < 0 then missing = 0 end
    local cards, newDeck = Deck.drawMultiple(model.deck, missing) -- use deterministic RNG later
    model.deck = newDeck
    for _, c in ipairs(cards) do table.insert(model.hand, c) end
    table.insert(ui, { kind = "animate_draw", count = #cards })
    view.inputLocked = true
    task.pc = 3
  elseif task.pc == 3 then
    if UI.isDone(view, "animate_draw") then
      view.inputLocked = false
      model.turn.phase = "in_progress"
      task._done = true
    end
  end
end

local handlers = {
  begin_turn = step_begin_turn,
  -- play_card = ...,
  -- end_turn  = ...,
}

function TaskRunner.step(model, view, dt)
  local produced = {}
  local ui = {}

  local tasks = model.tasks
  if not tasks or #tasks == 0 then return produced, ui end

  local task = tasks[1]

  if task.kind == TASKS.DEAL_CARDS then
    task.timer = (task.timer or 0) - dt

    if task.timer <= 0 then
      if (task.remaining or 0) > 0 then
        produced[#produced + 1] = { type = ACTIONS.DRAW_CARD }
        task.remaining = task.remaining - 1
        task.timer = task.interval or 0 -- reset countdown for the next card
      end

      if (task.remaining or 0) <= 0 then
        table.remove(model.tasks, 1) -- done
      end
    end
  else
    -- Unknown task
    -- log to debug
    produced[#produced + 1] = {
      type     = ACTIONS.LOG_DEBUG,
      category = LOG_OPTS.CATEGORY.TASK_DEBUG,
      entry    = ("Discarded unknown task kind: %s"):format(tostring(task.kind)),
    }
    -- → discard to avoid stalling the queue
    table.remove(model.tasks, 1)
  end
  return produced, ui
end

return TaskRunner
