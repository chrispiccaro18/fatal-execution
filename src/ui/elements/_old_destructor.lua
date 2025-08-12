local cfg              = require("ui.cfg")
local Card             = require("ui.elements.card")
local Decorators       = require("ui.decorators")
local lg               = love.graphics

local DestructorUI     = {
  shuffleTimers = {}
}

local SHUFFLE_DURATION = 0.8

function DestructorUI.triggerShuffle()
  DestructorUI.shuffleTimers["deck"] = SHUFFLE_DURATION
end

function DestructorUI.update(dt)
  for key, timer in pairs(DestructorUI.shuffleTimers) do
    timer = timer - dt
    if timer <= 0 then
      DestructorUI.shuffleTimers[key] = nil
    else
      DestructorUI.shuffleTimers[key] = timer
    end
  end
end

Decorators.register(DestructorUI.update)

function DestructorUI.drawDestructor(panelRect)
  local C     = cfg.destructorPanel
  local pad   = C.pad
  local cardW = C.cardW
  local cardH = C.cardH

  -- Panel border
  lg.setColor(1, 1, 1)
  lg.rectangle("line", panelRect.x, panelRect.y, panelRect.w, panelRect.h)

  -- Deck base card
  local centerX = panelRect.x + panelRect.w / 2
  local centerY = panelRect.y + panelRect.h / 2
  local baseX = centerX - cardW / 2
  local baseY = centerY - cardH / 2

  local queueSize = #love.gameState.destructorQueue

  if queueSize == 0 then
    -- Case 1: No cards in the queue, draw a rectangle with dotted lines
    lg.setColor(1, 1, 1)
    lg.setLineStyle("rough") -- Dashed line style
    lg.rectangle("line", baseX, baseY, cardW, cardH)
    lg.setLineStyle("smooth") -- Reset line style
  elseif queueSize == 1 then
    -- Case 2: Only one card in the queue, draw that card
    local card = love.gameState.destructorQueue[1]
    local hasNullify = love.gameState.destructorNullify > 0
    Card.drawFace(card, baseX, baseY, cardW, cardH, pad, hasNullify)
  else
    -- Case 3: More than one card in the queue, draw the current behavior
    -- Shuffle animation
    local offsetX, offsetY = 0, 0
    if DestructorUI.shuffleTimers["deck"] then
      local pct = 1 - (DestructorUI.shuffleTimers["deck"] / SHUFFLE_DURATION)
      local shake = math.sin(pct * math.pi * 4) * 5 -- Oscillates 4 times
      offsetX = shake
      offsetY = shake
    end

    lg.setColor(0.8, 0.2, 0.2)
    lg.rectangle("fill", baseX + offsetX, baseY + offsetY, cardW, cardH)

    -- Top of queue
    if not DestructorUI.shuffleTimers["deck"] and love.gameState.destructorQueue[1].state == "idle" then
      local card = love.gameState.destructorQueue[1]
      local cardOffsetX = C.displayCardOffsetX
      local cardOffsetY = C.displayCardOffsetY
      local previewX = baseX + cardOffsetX
      local previewY = baseY + cardOffsetY

      local hasNullify = love.gameState.destructorNullify > 0

      Card.drawFace(card, previewX, previewY, cardW, cardH, pad, hasNullify)
    end
  end

  -- Draw the count of cards in the destructorQueue
  lg.setFont(lg.newFont(cfg.destructorPanel.fontSize))
  lg.setColor(1, 1, 1)
  lg.print("Destructor Deck Size: " .. queueSize, panelRect.x, panelRect.y + panelRect.h + 10)

  -- Display "Destructor Nullify: X" if applicable
  if love.gameState.destructorNullify > 0 then
    lg.print("Destructor Nullify: " .. love.gameState.destructorNullify, panelRect.x, panelRect.y + panelRect.h + 30)
  end
end

-- function DestructorUI.drawDestructor(panelRect)
--   local C     = cfg.destructorPanel
--   local pad   = C.pad
--   local cardW = C.cardW
--   local cardH = C.cardH

--   -- Panel border
--   lg.setColor(1, 1, 1)
--   lg.rectangle("line", panelRect.x, panelRect.y, panelRect.w, panelRect.h)

--   -- Deck base card
--   local centerX = panelRect.x + panelRect.w / 2
--   local centerY = panelRect.y + panelRect.h / 2
--   local baseX = centerX - cardW / 2
--   local baseY = centerY - cardH / 2

--   -- Shuffle animation
--   local offsetX, offsetY = 0, 0
--   if DestructorUI.shuffleTimers["deck"] then
--     local pct = 1 - (DestructorUI.shuffleTimers["deck"] / SHUFFLE_DURATION)
--     local shake = math.sin(pct * math.pi * 4) * 5 -- Oscillates 4 times
--     offsetX = shake
--     offsetY = shake
--   end

--   lg.setColor(0.8, 0.2, 0.2)
--   lg.rectangle("fill", baseX + offsetX, baseY + offsetY, cardW, cardH)

--   -- Top of queue
--   if not DestructorUI.shuffleTimers["deck"] and #love.gameState.destructorQueue > 0 and love.gameState.destructorQueue[1].state == "idle" then
--     local card = love.gameState.destructorQueue[1]
--     local cardOffsetX = C.displayCardOffsetX
--     local cardOffsetY = C.displayCardOffsetY
--     local previewX = baseX + cardOffsetX
--     local previewY = baseY + cardOffsetY

--     local hasNullify = love.gameState.destructorNullify > 0

--     Card.drawFace(card, previewX, previewY, cardW, cardH, pad, hasNullify)
--   end
-- end

return DestructorUI
