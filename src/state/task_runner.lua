local Const      = require("const")
local UI         = require("state.ui")
local Deck       = require("game_state.deck")
local Log        = require("game_state.log")

local TASKS      = Const.TASKS
local ACTIONS    = Const.DISPATCH_ACTIONS
local LOG_OPTS   = Const.LOG

local ANIM       = Const.UI.ANIM

local TaskRunner = {}

function TaskRunner.step(model, view, dt)
  local produced = {}
  local ui = {}

  local tasks = model.tasks
  if not tasks or #tasks == 0 then return produced, ui end

  for _, task in ipairs(tasks) do
    if not task.inProgress then
      if task.kind == TASKS.DEAL_CARDS then
        if task.remaining > 0 then
          produced[#produced + 1] = { type = ACTIONS.DRAW_CARD, taskId = task.id }
        elseif task.remaining <= 0 then
          table.remove(model.tasks, 1)
        end
      -- elseif task.kind == TASKS.DISCARD_CARD then
      --   if task.remaining > 0 then
      --     produced[#produced + 1] = { type = ACTIONS.DISCARD_CARD, taskId = task.id, cardInstanceId = task.cardInstanceId }
      --   elseif task.remaining <= 0 then
      --     table.remove(model.tasks, 1)
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
        table.remove(model.tasks, 1)
      end
    end
  end

  return produced, ui
end

return TaskRunner
