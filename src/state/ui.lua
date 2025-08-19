local Const               = require("const")
local Tween               = require("ui.animations.tween")
local deepcopy            = require("util.deepcopy")

local ANIMATION_INTERVALS = Const.UI.ANIM
local INTENTS             = Const.UI.INTENTS
local TWEENS              = Const.UI.TWEENS
local ACTIONS             = Const.DISPATCH_ACTIONS

local UI                  = {}
function UI.init()
  return {
    inputLocked    = false,
    intents        = {},
    active         = {}, -- For non-hand animations (draw, discard)
    anchors        = nil,
    hover          = {
      currentHandIndex = nil,
      currentInstanceId = nil,
      animating = {},
    },
    handAnimations = {}, -- For hand-internal animations (reflow)
    signals        = {},
  }
end

function UI.getCardHoverOffset(slot)
  assert(slot, "[getCardHoverOffset] Slot is required")
  return {
    x = slot.x - (slot.w * 0.1) / 2,
    y = slot.y - 30,
    -- y = slot.y - (slot.h * 0.1) / 2,
    w = slot.w * 1.1,
    h = slot.h * 1.1,
  }
  -- to.y = to.y - 30
  -- to.w = to.w * 1.1
  -- to.h = to.h * 1.1
  -- to.x = to.x - (to.w - slot.w) / 2
  -- return to
end

-- The single source of truth for a card's position *within the hand*.
function UI.getCardInHandRect(view, handIndex)
  -- Priority 1: Is there a hand-specific animation (reflow) running?
  if view.handAnimations[handIndex] then
    return view.handAnimations[handIndex]:sample()
    -- Priority 2: Is there an active HOVER tween for this card?
  elseif view.hover.animating[handIndex] then
    return view.hover.animating[handIndex]:sample()
    -- Priority 3: Is this card the CURRENTLY hovered card (static and raised)?
  elseif view.hover.currentHandIndex == handIndex then
    local slot = view.anchors.handSlots.slots[handIndex]
    return UI.getCardHoverOffset(slot)
    -- Priority 4: Default to its static slot in the hand.
  else
    -- print("Should be here")
    return view.anchors.handSlots.slots[handIndex]
  end
end

function UI.schedule(view, intents)
  for _, it in ipairs(intents) do table.insert(view.intents, it) end
end

function UI.update(view, dt)
  -- Process one intent per frame.
  while #view.intents > 0 do
    local uiIntent = table.remove(view.intents, 1)

    if uiIntent.kind == INTENTS.SET_HOVERED_CARD then
      view.inputLocked = false
      local newHoverIndex = uiIntent.handIndex
      if newHoverIndex == view.hover.currentHandIndex then return end

      local oldHoverIndex = view.hover.currentHandIndex
      local oldHoverInstanceId = view.hover.currentInstanceId
      if oldHoverIndex then
        local from = UI.getCardInHandRect(view, oldHoverIndex)
        local to = view.anchors.handSlots.slots[oldHoverIndex]
        view.hover.animating[oldHoverIndex] = Tween.new({
          from = from,
          to = to,
          id = oldHoverInstanceId,
          duration = ANIMATION_INTERVALS.CARD_HOVER_DOWN_TIME,
          tag = TWEENS.CARD_HOVER_DOWN,
        })
      end

      view.hover.currentHandIndex = newHoverIndex
      view.hover.currentInstanceId = uiIntent.cardInstanceId

      if newHoverIndex then
        local newCardInstanceId = uiIntent.cardInstanceId
        local from = UI.getCardInHandRect(view, newHoverIndex)
        local to = UI.getCardHoverOffset(view.anchors.handSlots.slots[newHoverIndex])
        view.hover.animating[newHoverIndex] = Tween.new({
          from = from,
          to = to,
          id = newCardInstanceId,
          duration = ANIMATION_INTERVALS.CARD_HOVER_UP_TIME,
          tag = TWEENS.CARD_HOVER_UP,
        })
      end
    elseif uiIntent.kind == INTENTS.ANIMATE_DRAW_DECK_TO_HAND then
      view.inputLocked = true
      local from = view.anchors.getDeckRect()
      local to = view.anchors.getHandSlots(uiIntent.newSlotCount).slots[uiIntent.newSlotCount]
      local tween = Tween.new({
        from = from,
        to = to,
        duration = ANIMATION_INTERVALS.CARD_DRAW_TIME,
        id = uiIntent.newCardInstanceId,
        tag = TWEENS.CARD_DRAW,
      })
      tween.onComplete = function ()
        table.insert(
          view.signals,
          { type = ACTIONS.FINISH_CARD_DRAW, cardInstanceId = uiIntent.newCardInstanceId, taskId = uiIntent.taskId }
        )
      end
      table.insert(view.active, tween)
    elseif uiIntent.kind == INTENTS.ANIMATE_DISCARD_HAND_TO_DESTRUCTOR then
      view.inputLocked = true
      local from = UI.getCardInHandRect(view, uiIntent.discardedCardHandIndex)
      local to = view.anchors.getDestructorRect()
      local tween = Tween.new({
        from = from,
        to = to,
        duration = ANIMATION_INTERVALS.CARD_DISCARD_TIME,
        id = uiIntent.discardedCardInstanceId,
        tag = TWEENS.CARD_DISCARD,
      })
      tween.onComplete = function()
        table.insert(
          view.signals,
          { type = ACTIONS.FINISH_CARD_DISCARD, discardedCardInstanceId = uiIntent.discardedCardInstanceId }
        )
      end
      table.insert(view.active, tween)

      if view.hover.currentHandIndex == uiIntent.discardedCardHandIndex then
        -- If the hovered card is being discarded, reset hover.
        view.hover.currentHandIndex = nil
        view.hover.currentInstanceId = nil
        view.hover.animating[uiIntent.discardedCardHandIndex] = nil
      end
    elseif uiIntent.kind == INTENTS.ANIMATE_HAND_REFLOW then
      view.inputLocked = true
      local handIds = uiIntent.existingInstanceIds
      local excludingIndex = uiIntent.excludingIndex or nil
      local newSlotCount = uiIntent.finalSlotCount
      local newSlotsAndMode = view.anchors.getHandSlots(newSlotCount)
      local newSlots = newSlotsAndMode.slots

      for i = 1, newSlotCount do
        if i ~= excludingIndex then
          local from = UI.getCardInHandRect(view, i)
          local to = newSlots[i]
          if from and to then
            view.handAnimations[i] = Tween.new({
              from = from,
              to = to,
              id = handIds[i],
              duration = ANIMATION_INTERVALS.HAND_REFLOW_TIME,
              tag = TWEENS.CARD_REFLOW,
            })
          end
        end
      end
      view.anchors.handSlots = newSlotsAndMode
    end
  end

  -- Tick all animation groups
  for index, tween in pairs(view.hover.animating) do
    if tween:update(dt) then view.hover.animating[index] = nil end
  end
  for index, tween in pairs(view.handAnimations) do
    if tween:update(dt) then view.handAnimations[index] = nil end
  end
  for i = #view.active, 1, -1 do
    if view.active[i]:update(dt) then table.remove(view.active, i) end
  end

  -- Unlock when all animations are done
  if view.inputLocked and #view.active == 0 and #view.handAnimations == 0 then
    view.inputLocked = false
  end
end

function UI.consumeSignals(view)
  if #view.signals == 0 then return {} end
  local sigs = view.signals
  view.signals = {}
  return sigs
end

return UI
