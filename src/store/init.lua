local Model      = require("model")

local Reducers   = require("state.reducers")
local TaskRunner = require("state.task_runner")
local UI         = require("state.ui")
local Layout     = require("ui.layout")
local Display    = require("ui.display")

local Store      = { model = nil, view = nil }

function Store.bootstrap(modelOrNil)
  Store.model = modelOrNil or Model.new()
  Store.view  = UI.init()
  Store.view.anchors = Layout.compute(Display.VIRTUAL_W, Display.VIRTUAL_H)
end

function Store.dispatch(action)
  local newModel, uiIntents, newTasks = Reducers.reduce(Store.model, action)
  Store.model = newModel
  if newTasks and #newTasks > 0 then
    for _, t in ipairs(newTasks) do table.insert(Store.model.tasks, t) end
  end
  if uiIntents and #uiIntents > 0 then
    UI.schedule(Store.view, uiIntents)
  end
end

local lastW, lastH = nil, nil
function Store.update(dt)
  local W, H = Display.VIRTUAL_W, Display.VIRTUAL_H
  if W ~= lastW or H ~= lastH then
    Store.view.anchors = Layout.compute(W, H)
    lastW, lastH = W, H
  end
  -- local producedActions, uiIntents = TaskRunner.step(Store.model, Store.view, dt)
  -- for _, a in ipairs(producedActions) do Store.dispatch(a) end
  -- if uiIntents and #uiIntents > 0 then UI.schedule(Store.view, uiIntents) end
  UI.update(Store.view, dt) -- drives animations; sets view.inputLocked as needed
end

-- Get the current turn phase or false
function Store.getPhase()
  if Store.model and Store.model.turn and Store.model.turn.phase then
    return Store.model.turn.phase
  else
    return false
  end
end

return Store
