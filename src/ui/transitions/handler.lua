local Animation = require("ui.animate")
local Display = require("ui.display")
local Card = require("ui.elements.card")
local cfg = require("ui.cfg")

local TransitionHandlers = {}

function TransitionHandlers.handleDiscard(args)
  local transition = args.transition
  local card = transition.payload.card
  local handIndex = transition.payload.handIndex
  local sections = args.sections
  local applyTransition = args.applyTransition
  local setBusy = args.setBusy

  setBusy(true)

  card.state = "discarding"
  card.selectable = false

  local handPanel = sections.play
  local pad = cfg.handPanel.pad
  local spacingX = math.min(cfg.handPanel.maxSpacingX,
                            (handPanel.w - pad * 2 - cfg.handPanel.cardW * #love.gameState.hand) /
                            math.max(1, #love.gameState.hand - 1))

  local xOffset = (handIndex - 1) * (cfg.handPanel.cardW + spacingX)
  local startX = handPanel.x + pad + xOffset
  local startY = handPanel.y + pad

  local destPanel = sections.right
  local endX = destPanel.x + destPanel.w / 2 - cfg.handPanel.cardW / 2
  local endY = destPanel.y + destPanel.h / 2 - cfg.handPanel.cardH / 2

  card.animX = startX
  card.animY = startY

  Animation.add {
    duration = 0.4,
    onUpdate = function(t)
      local tt = 1 - (1 - t) ^ 2
      card.animX = startX + (endX - startX) * tt
      card.animY = startY + (endY - startY) * tt
    end,
    onComplete = function()
      card.animX = nil
      card.animY = nil
      -- require("ui.elements.ram").triggerPulse()
      love.gameState = applyTransition(love.gameState, transition)
      setBusy(false)
    end,
    onDraw = function()
      Card.drawFace(
        card,
        card.animX,
        card.animY,
        cfg.handPanel.cardW,
        cfg.handPanel.cardH
      )
    end
  }
end

function TransitionHandlers.handleDraw(args)
  local transition = args.transition
  local cardsToDraw = transition.payload.cardsToDraw
  local sections = args.sections
  local applyTransition = args.applyTransition
  local setBusy = args.setBusy

  setBusy(true)

  local cardW = cfg.handPanel.cardW
  local deckPanel = sections.deck
  local handPanel = sections.play
  local pad = cfg.handPanel.pad
  local startX = deckPanel.x + pad
  local startY = deckPanel.y + pad
  local endY = handPanel.y + pad
  local spacingX = math.min(cfg.handPanel.maxSpacingX,
                            (sections.play.w - pad * 2 - cardW * #love.gameState.hand) /
                            math.max(1, #love.gameState.hand - 1))

  for i = 1, #cardsToDraw do
    local card = cardsToDraw[i]
    local delay = (i - 1) * 0.2 -- staggered delay for each card
    card.state = "animating"
    card.selectable = false

    local cardsInHand = love.gameState.hand
    local xOffset = (#cardsInHand + i - 1) * (cardW + spacingX)
    local endX = handPanel.x + pad + xOffset
    require("ui.decorators").emit("drawToHand", {
      card = cardsToDraw[i],
      startX = startX,
      startY = startY,
      endX = endX,
      endY = endY,
      onComplete = function()
        cardsToDraw[i].selectable = true
        cardsToDraw[i].state = "idle"
      end,
      delay = delay
    })
  end

  love.gameState = applyTransition(love.gameState, transition)
  setBusy(false)
end

function TransitionHandlers.handlePlay(args)
  local transition = args.transition
  local card = transition.payload.card
  local cardsToDraw = transition.payload.cardsToDraw
  local index = transition.payload.handIndex
  local sections = args.sections
  local applyTransition = args.applyTransition
  local setBusy = args.setBusy

  local didApplyTransition = false

  local pad = cfg.handPanel.pad

  setBusy(true)
  card.selectable = false
  card.state = "playing"

  -- Start: from hand
  local cardW = cfg.handPanel.cardW
  local cardH = cfg.handPanel.cardH
  local spacingX = math.min(cfg.handPanel.maxSpacingX,
                            (sections.play.w - pad * 2 - cardW * #love.gameState.hand) /
                            math.max(1, #love.gameState.hand - 1))
  local xOffset = (index - 1) * (cardW + spacingX)

  -- Use center of card, not top-left
  local startX = sections.play.x + pad + xOffset + cardW / 2
  local startY = sections.play.y + pad + cardH / 2

  -- Mid: center of screen
  local midX = Display.VIRTUAL_W / 2 - cardW / 2
  local midY = Display.VIRTUAL_H / 2 - cardH / 2

  -- End: under deck
  local deckW = cfg.deckPanel.deckW
  local deckH = cfg.deckPanel.deckH
  local deckRect = sections.deck

  local endX = deckRect.x + cfg.deckPanel.pad + deckW / 2
  local endY = deckRect.y + cfg.deckPanel.pad + deckH / 2

  card.animX, card.animY = startX, startY
  card.animScale = 1

  local duration1 = 0.3
  local durationPause = 0.3
  local duration2 = 0.2
  local totalDuration = duration1 + durationPause + duration2

  Animation.add {
    duration = totalDuration,
    onUpdate = function(t)
      if t < duration1 / totalDuration then
        -- Phase 1: move to center
        local t1 = t / (duration1 / totalDuration)
        card.animX = startX + (midX - startX) * t1
        card.animY = startY + (midY - startY) * t1
        card.animScale = 1
      elseif t < (duration1 + durationPause) / totalDuration then
        -- Phase 2: pause in center
        card.animX = midX
        card.animY = midY
        card.animScale = 1

        -- Apply transition only once during the pause
        if not didApplyTransition then
          if cardsToDraw and #cardsToDraw > 0 then
            local deckPanel = sections.deck
            local handPanel = sections.play

            local startX = deckPanel.x + pad
            local startY = deckPanel.y + pad
            local endY = handPanel.y + pad

            -- emit in loop for each card
            for i = 1, #cardsToDraw do
              local delay = (i - 1) * 0.2 -- staggered delay for each card
              -- we'll have to figure out the endX based on current hand and index
              local cardsInHand = love.gameState.hand
              -- #cardsInHand - 1 because the played card is still "in hand" during the animation
              local xOffset = (#cardsInHand - 1 + i - 1) * (cardW + spacingX)
              local endX = handPanel.x + pad + xOffset
              require("ui.decorators").emit("drawToHand", {
                card = cardsToDraw[i],
                startX = startX,
                startY = startY,
                endX = endX,
                endY = endY,
                onComplete = function()
                  cardsToDraw[i].selectable = true
                  cardsToDraw[i].state = "idle"
                end,
                delay = delay
              })
            end
          end

          love.gameState = applyTransition(love.gameState, transition)
          didApplyTransition = true
        end
      else
        -- Phase 3: move to deck and shrink
        local t3 = (t - (duration1 + durationPause) / totalDuration) / (duration2 / totalDuration)
        local ease = 1 - (1 - t3) ^ 2
        card.animX = midX + (endX - midX) * t3
        card.animY = midY + (endY - midY) * t3
        card.animScale = 1 - 0.5 * ease
      end
    end,
    onComplete = function()
      card.animX = nil
      card.animY = nil
      card.animScale = nil
      card.state = "idle"
      setBusy(false)
    end,
    onDraw = function()
      local fullW = cfg.handPanel.cardW
      local fullH = cfg.handPanel.cardH
      local scale = card.animScale or 1
      local drawW = fullW * scale
      local drawH = fullH * scale

      love.graphics.push()
      love.graphics.translate(card.animX, card.animY)
      love.graphics.translate(-drawW / 2, -drawH / 2)

      Card.drawFace(card, 0, 0, drawW, drawH, pad)

      love.graphics.pop()
    end
  }
end

function TransitionHandlers.handleDestructorPlay(args)
  local transition = args.transition
  local card = transition.payload.card
  local updatedQueue = transition.payload.updatedQueue
  local cardToDestructor = transition.payload.cardToDestructor
  local hasNullify = transition.payload.hasNullify
  local newDeckAfterDrawToDestructor = transition.payload.newDeckAfterDrawToDestructor
  local sections = args.sections
  local applyTransition = args.applyTransition
  local setBusy = args.setBusy

  local didApplyTransition = false

  setBusy(true)

  card.state = "destructorPlaying"
  card.selectable = false

  local destructorPanel = sections.destructor
  local pad = cfg.destructorPanel.pad

  -- Start: from destructor queue center
  local startX = destructorPanel.x + destructorPanel.w / 2 - cfg.destructorPanel.cardW / 2
  local startY = destructorPanel.y + destructorPanel.h / 2 - cfg.destructorPanel.cardH / 2

  -- Mid: center of screen
  local midX = Display.VIRTUAL_W / 2 - cfg.destructorPanel.cardW / 2
  local midY = Display.VIRTUAL_H / 2 - cfg.destructorPanel.cardH / 2

  -- End: under deck
  local deckW = cfg.deckPanel.deckW
  local deckH = cfg.deckPanel.deckH
  local deckRect = sections.deck

  local endX = deckRect.x + cfg.deckPanel.pad + deckW / 2
  local endY = deckRect.y + cfg.deckPanel.pad + deckH / 2

  card.animX, card.animY = startX, startY
  card.animScale = 1

  local duration1 = 0.3
  local durationPause = 0.3
  local duration2 = 0.2
  local totalDuration = duration1 + durationPause + duration2

  Animation.add {
    duration = totalDuration,
    onUpdate = function(t)
      if t < duration1 / totalDuration then
        -- Phase 1: move to center
        local tt = t / (duration1 / totalDuration)
        card.animX = startX + (midX - startX) * tt
        card.animY = startY + (midY - startY) * tt
        card.animScale = 1
      elseif t < (duration1 + durationPause) / totalDuration then
        -- Phase 2: pause in center
        card.animX = midX
        card.animY = midY
        card.animScale = 1

        -- Apply transition only once during the pause
        if not didApplyTransition then
          if cardToDestructor and not hasNullify then
            local deckPanel = sections.deck
            local destructorPanel = sections.destructor

            local startX = deckPanel.x + deckPanel.w / 2
            local startY = deckPanel.y + deckPanel.h / 2
            local endX = destructorPanel.x + destructorPanel.w / 2
            local endY = destructorPanel.y + destructorPanel.h / 2

            require("ui.decorators").emit("drawToDestructor", {
              card = cardToDestructor,
              startX = startX,
              startY = startY,
              endX = endX,
              endY = endY,
              onComplete = function()
                card.state = "idle"
              end
            })
          end

          love.gameState = applyTransition(love.gameState, transition)
          didApplyTransition = true

          if hasNullify then
            hasNullify = false
          end
        end
      else
        -- Phase 3: move to deck and shrink
        local tt = (t - (duration1 + durationPause) / totalDuration) / (duration2 / totalDuration)
        local ease = 1 - (1 - tt) ^ 2
        card.animX = midX + (endX - midX) * tt
        card.animY = midY + (endY - midY) * tt
        card.animScale = 1 - 0.5 * ease
      end
    end,
    onComplete = function()
      card.animX = nil
      card.animY = nil
      card.animScale = nil
      card.state = "idle"
      setBusy(false)
    end,
    onDraw = function()
      local fullW = cfg.destructorPanel.cardW
      local fullH = cfg.destructorPanel.cardH
      local scale = card.animScale or 1
      local drawW = fullW * scale
      local drawH = fullH * scale

      love.graphics.push()
      love.graphics.translate(card.animX, card.animY)
      -- love.graphics.translate(-drawW / 2, -drawH / 2)

      Card.drawFace(card, 0, 0, drawW, drawH, pad)

      love.graphics.pop()
    end
  }
end

return TransitionHandlers
