local EventSystem = {}

EventSystem.listeners = {}

function EventSystem.subscribe(event, callback)
  if not EventSystem.listeners[event] then
    EventSystem.listeners[event] = {}
  end
  table.insert(EventSystem.listeners[event], callback)
end

function EventSystem.emit(event, ...)
  if EventSystem.listeners[event] then
    for _, callback in ipairs(EventSystem.listeners[event]) do
      callback(...)
    end
  end
end

return EventSystem
