local UI = {}

function UI.init()
  return { inputLocked = false, intents = {}, active = {} }
end

function UI.schedule(view, intents)
  for _, it in ipairs(intents) do table.insert(view.intents, it) end
end

function UI.update(view, dt)
  -- convert intents -> active animations; tick them; mark completion
  -- set view.inputLocked = true while certain anims are active
end

function UI.isDone(view, kind)
  -- return true when no active anims of 'kind'
  return true
end

return UI
