local Model      = require("model")

local Reducers   = require("state.reducers")
local TaskRunner = require("state.task_runner")
local UI         = require("state.ui")

local Layout     = require("ui.layout")
local Display    = require("ui.display")

local immut      = require("util.immut")

local Store      = { model = nil, view = nil }

function Store.bootstrap(modelOrNil)
  Store.model        = modelOrNil or Model.new()
  Store.view         = UI.init()
  Store.view.anchors = Layout.compute(Display.getVirtualSize())
end

function Store.dispatch(action)
  local newModel, uiIntents, newTasks = Reducers.reduce(Store.model, action)
  if newTasks and #newTasks > 0 then
    local existing = newModel.tasks or {}
    local merged = immut.copyArray(existing)
    for _, newTask in ipairs(newTasks) do merged[#merged + 1] = newTask end
    newModel = immut.assign(newModel, "tasks", merged)
  end

  Store.model = newModel

  if uiIntents and #uiIntents > 0 then UI.schedule(Store.view, uiIntents) end
end

local lastW, lastH = nil, nil
function Store.update(dt)
  local W, H = Display.getVirtualSize()
  if W ~= lastW or H ~= lastH then
    local oldSlots = Store.view.anchors and Store.view.anchors.handSlots -- keep old

    Store.view.anchors = Layout.compute(W, H)
    lastW, lastH = W, H

    Store.view.anchors.handSlots = oldSlots or {}
  end

  local producedActions, uiIntents = TaskRunner.step(Store.model, Store.view, dt)
  for _, action in ipairs(producedActions) do Store.dispatch(action) end
  if uiIntents and #uiIntents > 0 then UI.schedule(Store.view, uiIntents) end

  UI.ensureHandLayout(Store.view, Store.model.hand, Store.view.anchors)

  UI.update(Store.view, dt)
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
