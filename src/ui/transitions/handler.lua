local Animation = require("ui.animate")
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
    (handPanel.w - pad * 2 - cfg.handPanel.cardW * #love.gameState.hand) / math.max(1, #love.gameState.hand - 1))

  local xOffset = (handIndex - 1) * (cfg.handPanel.cardW + spacingX)
  local startX = handPanel.x + pad + xOffset
  local startY = handPanel.y + pad

  local destPanel = sections.right
  local endX = destPanel.x + destPanel.w / 2 - cfg.handPanel.cardW / 2
  local endY = destPanel.y + destPanel.h / 2 - cfg.handPanel.cardH / 2

  card.animX = startX
  card.animY = startY

  Animation.add{
    duration = 0.4,
    onUpdate = function(t)
      local tt = 1 - (1 - t)^2
      card.animX = startX + (endX - startX) * tt
      card.animY = startY + (endY - startY) * tt
    end,
    onComplete = function()
      card.animX = nil
      card.animY = nil
      love.gameState = applyTransition(love.gameState, transition)
      setBusy(false)
    end,
    onDraw = function()
      love.graphics.setColor(0.5, 0.5, 0.5)
      love.graphics.rectangle("fill", card.animX, card.animY, cfg.handPanel.cardW, cfg.handPanel.cardH)
      love.graphics.setColor(1, 0.5, 0.5)
      love.graphics.rectangle("line", card.animX, card.animY, cfg.handPanel.cardW, cfg.handPanel.cardH)
    end
  }
end

function TransitionHandlers.handleDraw(args)
  local transition = args.transition
  local card = transition.payload.card
  local index = transition.payload.index
  local sections = args.sections
  local applyTransition = args.applyTransition
  local setBusy = args.setBusy

  setBusy(true)

  local deckPanel = sections.deck
  local handPanel = sections.play
  local pad = cfg.handPanel.pad

  local spacingX = math.min(cfg.handPanel.maxSpacingX,
      (handPanel.w - pad * 2 - cfg.handPanel.cardW * index) / math.max(1, index - 1))
  local xOffset = (index - 1) * (cfg.handPanel.cardW + spacingX)

  local startX = deckPanel.x + pad
  local startY = deckPanel.y + pad
  local endX = handPanel.x + pad + xOffset
  local endY = handPanel.y + pad

  card.animX = startX
  card.animY = startY
  card.state = "animating"
  card.selectable = false

  Animation.add{
    duration = 0.4,
    onUpdate = function(t)
      local tt = 1 - (1 - t)^2
      card.animX = startX + (endX - startX) * tt
      card.animY = startY + (endY - startY) * tt
    end,
    onComplete = function()
      card.animX = nil
      card.animY = nil
      card.state = "idle"
      card.selectable = true
      love.gameState = applyTransition(love.gameState, transition)
      setBusy(false)
    end,
    onDraw = function()
      love.graphics.setColor(0.8, 0.8, 0.8)
      love.graphics.rectangle("fill", card.animX, card.animY, cfg.handPanel.cardW, cfg.handPanel.cardH)
      love.graphics.setColor(1, 1, 0)
      love.graphics.rectangle("line", card.animX, card.animY, cfg.handPanel.cardW, cfg.handPanel.cardH)
    end
  }
end

return TransitionHandlers
