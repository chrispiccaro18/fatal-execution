local Const      = require("const")
local UI         = require("state.ui")
local Deck       = require("game_state.deck")
local Log        = require("game_state.log")

local TASKS      = Const.TASKS
local UI_INTENTS = Const.UI.INTENTS
local ACTIONS    = Const.DISPATCH_ACTIONS
local LOG_OPTS   = Const.LOG

local ANIM       = Const.UI.ANIM

local TaskRunner = {}

function TaskRunner.step(model, view, dt)
  local produced = {}
  local ui = {}

  local tasks = model.tasks
  if not tasks or #tasks == 0 then return produced, ui end

  local remainingTasks = {}

  for i = 1, #tasks do
    local task = tasks[i]
    local remove = false

    if task.inProgress then
      if task.kind == TASKS.DEAL_CARDS and task.remaining <= 0 then
        task.inProgress = false
      end
    else
      if task.kind == TASKS.DEAL_CARDS then
        if task.remaining > 0 then
          if view and view.lockedTasks and not view.lockedTasks[task.id] then
            ui[#ui + 1] = { kind = UI_INTENTS.LOCK_UI_FOR_TASK, taskId = task.id }
          end
          produced[#produced + 1] = { type = ACTIONS.DRAW_CARD, taskId = task.id }
        elseif task.remaining <= 0 then
          ui[#ui + 1] = { kind = UI_INTENTS.UNLOCK_UI_FOR_TASK, taskId = task.id }
          remove = true
        end
      elseif task.kind == TASKS.PLAY_CARD then
        if task.complete then
          ui[#ui + 1] = { kind = UI_INTENTS.UNLOCK_UI_FOR_TASK, taskId = task.id }
          remove = true
        else
          produced[#produced + 1] = { type = ACTIONS.TASK_IN_PROGRESS, taskId = task.id }
          if view and view.lockedTasks and not view.lockedTasks[task.id] then
            ui[#ui + 1] = { kind = UI_INTENTS.LOCK_UI_FOR_TASK, taskId = task.id }
          end
        end
      elseif task.kind == TASKS.DESTRUCTOR_PLAY then
        if task.complete then
          ui[#ui + 1] = { kind = UI_INTENTS.UNLOCK_UI_FOR_TASK, taskId = task.id }
          remove = true
        else
          produced[#produced + 1] = { type = ACTIONS.TASK_IN_PROGRESS, taskId = task.id }
          if view and view.lockedTasks and not view.lockedTasks[task.id] then
            ui[#ui + 1] = { kind = UI_INTENTS.LOCK_UI_FOR_TASK, taskId = task.id }
          end
        end

        -- elseif task.kind == TASKS.DISCARD_CARD then
        --   if task.remaining > 0 then
        --     produced[#produced + 1] = { type = ACTIONS.DISCARD_CARD, taskId = task.id, cardInstanceId = task.cardInstanceId }
        --   elseif task.remaining <= 0 then
        --     table.remove(model.tasks, i)
        --   end
      else
        -- Unknown task
        -- log to debug
        produced[#produced + 1] = {
          type     = ACTIONS.LOG_DEBUG,
          category = LOG_OPTS.CATEGORY.TASK_DEBUG,
          entry    = ("Discarded unknown task kind: %s"):format(tostring(task.kind)),
        }
        -- → discard to avoid stalling the queue
        remove = true
      end
    end

    if not remove then
      remainingTasks[#remainingTasks + 1] = task
    end
  end

  model.tasks = remainingTasks

  return produced, ui
end

return TaskRunner
