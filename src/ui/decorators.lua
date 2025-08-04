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
    elseif event.name == "destructorShuffle" then
      require("ui.elements.destructor").triggerShuffle()
    elseif event.name == "drawToDestructor" then
      Decorators.handleDrawToDestructor(event.payload)
    elseif event.name == "drawToHand" then
      Decorators.handleDrawToHand(event.payload)
    end
  end
  Decorators.events = {}
end

function Decorators.handleDrawToDestructor(payload)
  local card = payload.card
  local startX, startY = payload.startX, payload.startY
  local endX, endY = payload.endX, payload.endY
  local onComplete = payload.onComplete

  card.animX = startX
  card.animY = startY

  require("ui.animate").add {
    duration = 0.4,
    onUpdate = function(t)
      local tt = 1 - (1 - t) ^ 2
      card.animX = startX + (endX - startX) * tt
      card.animY = startY + (endY - startY) * tt
    end,
    onComplete = function()
      card.animX = nil
      card.animY = nil
      if onComplete then onComplete() end
    end,
    onDraw = function()
      require("ui.elements.card").drawFace(
        card,
        card.animX,
        card.animY,
        require("ui.cfg").handPanel.cardW,
        require("ui.cfg").handPanel.cardH
      )
    end
  }
end

function Decorators.handleDrawToHand(payload)
  local card = payload.card
  local startX, startY = payload.startX, payload.startY
  local endX, endY = payload.endX, payload.endY
  local onComplete = payload.onComplete
  local delay = payload.delay or 0

  card.animX = startX
  card.animY = startY

  require("ui.animate").add {
    duration = 0.4,
    delay = delay,
    onUpdate = function(t)
      local tt = 1 - (1 - t) ^ 2
      card.animX = startX + (endX - startX) * tt
      card.animY = startY + (endY - startY) * tt
    end,
    onComplete = function()
      card.animX = nil
      card.animY = nil
      if onComplete then onComplete() end
    end,
    onDraw = function()
      require("ui.elements.card").drawFace(
        card,
        card.animX,
        card.animY,
        require("ui.cfg").handPanel.cardW,
        require("ui.cfg").handPanel.cardH
      )
    end
  }
end

return Decorators
