local UI = require("state.ui")
local Deck = require("game_state.deck")
local Log  = require("game_state.log")

local TaskRunner = {}

local function step_begin_turn(model, view, task, produced, ui)
  if task.pc == 1 then
    model.ram = 0
    model.turn.turnCount = model.turn.turnCount + 1
    Log.addEntry(model, "-- Turn " .. model.turn.turnCount .. " begins --")
    task.pc = 2

  elseif task.pc == 2 then
    local missing = model.handSize - #model.hand
    if missing < 0 then missing = 0 end
    local cards, newDeck = Deck.drawMultiple(model.deck, missing) -- use deterministic RNG later
    model.deck = newDeck
    for _, c in ipairs(cards) do table.insert(model.hand, c) end
    table.insert(ui, { kind="animate_draw", count=#cards })
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

  if not model.tasks then model.tasks = {} end
  local t = model.tasks[1]
  if not t then return produced, ui end

  local h = handlers[t.type]
  if h then h(model, view, t, produced, ui) else t._done = true end

  if t._done then table.remove(model.tasks, 1) end
  return produced, ui
end

return TaskRunner
