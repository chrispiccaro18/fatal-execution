local Store      = { model = nil, view = nil }

local Model      = require("model")

local Reducers   = require("state.reducers")
local TaskRunner = require("state.task_runner")
local UI         = require("state.ui") -- ephemeral intents/animations

function Store.bootstrap(modelOrNil)
  Store.model = modelOrNil or Model.new(os.time(), {
    deckPresetId    = "starter_v1",
    systemsPresetId = "base_ship_v1",
    threatPresetId  = "solo_standard_v1",
    difficulty      = "normal",
  })
  Store.view  = UI.init()
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

function Store.update(dt)
  local producedActions, uiIntents = TaskRunner.step(Store.model, Store.view, dt)
  for _, a in ipairs(producedActions) do Store.dispatch(a) end
  if uiIntents and #uiIntents > 0 then UI.schedule(Store.view, uiIntents) end
  UI.update(Store.view, dt) -- drives animations; sets view.inputLocked as needed
end

return Store
