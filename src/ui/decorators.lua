-- ui/decorators.lua
local Decorators = {
  registry = {},
  events = {}
}

-- Register a per-frame update function (e.g. pulse timers)
function Decorators.register(updateFn)
  table.insert(Decorators.registry, updateFn)
end

-- Called from `love.update(dt)`
function Decorators.updateAll(dt)
  for _, fn in ipairs(Decorators.registry) do
    fn(dt)
  end
end

-- Emit a one-shot effect (e.g. RAM pulse)
function Decorators.emit(name, payload)
  table.insert(Decorators.events, { name = name, payload = payload })
end

-- Consume events, call handlers, then clear
function Decorators.consumeAndDispatch()
  for _, event in ipairs(Decorators.events) do
    if event.name == "ramPulse" then
      require("ui.elements.ram").triggerPulse()
    elseif event.name == "logGlow" then
      require("ui.elements.logs").triggerGlow(event.payload)
    elseif event.name == "systemProgress" then
      require("ui.elements.systems").triggerProgress(event.payload)
    end
  end
  Decorators.events = {}
end

return Decorators
