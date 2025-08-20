local Const               = require("const")
local Tween               = require("ui.animations.tween")
local deepcopy            = require("util.deepcopy")
local General             = require("util.general")

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
      spreadPx = Const.CARD_WIDTH / 4,
    },
    handAnimations = {}, -- For hand-internal animations (reflow)
    signals        = {},
    lockedTasks    = {},
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

function UI.getSpreadRect(view, handIndex, offsets)
  local base = view.anchors.handSlots.slots[handIndex]
  if not base or not offsets[handIndex] then return base end
  -- local dir = handIndex < hoveredIndex and -1 or 1
  -- local spread = view.hover.spreadPx
  local r = deepcopy(base)
  if r then
    r.x = r.x + (offsets[handIndex] or 0)
  end

  local playPanel = view.anchors and view.anchors.sections and view.anchors.sections.play
  if playPanel and r then
    local minX = playPanel.x
    local maxX = playPanel.x + playPanel.w - r.w
    r.x = General.clamp(r.x, minX, maxX)
  end
  return r
end

-- The single source of truth for a card's position *within the hand*.
function UI.getCardInHandRect(view, handIndex)
  -- Guard: require anchors/slots
  if not view or not view.anchors or not view.anchors.handSlots or not view.anchors.handSlots.slots then
    return nil
  end

  -- Priority 1: Is there a hand-specific animation (reflow) running?
  if view.handAnimations[handIndex] then
    return view.handAnimations[handIndex]:sample()
    -- Priority 2: Is there an active HOVER tween for this card?
  elseif view.hover.animating[handIndex] then
    return view.hover.animating[handIndex]:sample()
    -- Priority 3: Is this card the CURRENTLY hovered card (static and raised)?
  elseif view.hover.currentHandIndex and not view.inputLocked then
    local hovered = view.hover.currentHandIndex
    if handIndex == hovered then
      local slot = view.anchors.handSlots.slots[handIndex]
      if not slot then return nil end
      return UI.getCardHoverOffset(slot)
    else
      if not view.anchors.getHoverOffsets then
        return view.anchors.handSlots.slots[handIndex]
      end
      local offsets = view.anchors.getHoverOffsets(view.anchors.handSlots, hovered)
      return UI.getSpreadRect(view, handIndex, offsets)
    end
    -- Priority 4: Default to its static slot in the hand.
  else
    return view.anchors.handSlots.slots[handIndex]
  end
end

function UI.schedule(view, intents)
  for _, it in ipairs(intents) do table.insert(view.intents, it) end
end

function UI.update(view, dt)
  while #view.intents > 0 do
    local uiIntent = table.remove(view.intents, 1)

    if uiIntent.kind == INTENTS.SET_HOVERED_CARD then
      -- view.inputLocked = false
      local newHoverIndex = uiIntent.handIndex
      if newHoverIndex ~= view.hover.currentHandIndex then
        local oldHoverIndex = view.hover.currentHandIndex
        local oldHoverInstanceId = view.hover.currentInstanceId
        local slots = view.anchors.handSlots.slots
        local slotCount = #slots

        local fromByIndex = {}
        for i = 1, slotCount do
          fromByIndex[i] = UI.getCardInHandRect(view, i)
        end

        if oldHoverIndex then
          local to = slots[oldHoverIndex]
          view.hover.animating[oldHoverIndex] = Tween.new({
            from = fromByIndex[oldHoverIndex],
            to = to,
            id = oldHoverInstanceId,
            duration = ANIMATION_INTERVALS.CARD_HOVER_DOWN_TIME,
            tag = TWEENS.CARD_HOVER_DOWN,
          })
        end

        view.hover.currentHandIndex = newHoverIndex
        view.hover.currentInstanceId = uiIntent.cardInstanceId

        if not view.inputLocked then
          local offsets = {}
          if newHoverIndex then
            offsets = view.anchors.getHoverOffsets(view.anchors.handSlots, newHoverIndex)
          end

          for i = 1, slotCount do
            if i ~= newHoverIndex then
              local to
              if newHoverIndex then
                to = UI.getSpreadRect(view, i, offsets)
              else
                to = slots[i]
              end
              local from = fromByIndex[i]
              if from and to then
                view.hover.animating[i] = Tween.new({
                  from = from,
                  to = to,
                  -- id = uiIntent.cardInstanceId,
                  duration = ANIMATION_INTERVALS.HAND_REFLOW_TIME,
                  tag = TWEENS.CARD_REFLOW,
                })
              else
                view.hover.animating[i] = nil
                print("Warning: from or to is nil for hand index " .. i)
              end
            end
          end
        end

        if newHoverIndex then
          local newCardInstanceId = uiIntent.cardInstanceId
          local from = fromByIndex[newHoverIndex]
          local to = UI.getCardHoverOffset(slots[newHoverIndex])
          view.hover.animating[newHoverIndex] = Tween.new({
            from = from,
            to = to,
            id = newCardInstanceId,
            duration = ANIMATION_INTERVALS.CARD_HOVER_UP_TIME,
            tag = TWEENS.CARD_HOVER_UP,
          })
        end
      else
        -- Keep instanceId in sync when index is unchanged.
        view.hover.currentInstanceId = uiIntent.cardInstanceId
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
      tween.onComplete = function()
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
      view.handAnimations = {}

      local newSlotCount = uiIntent.newSlotCount
      local oldSlotCount = uiIntent.oldSlotCount
      local holeIndex = uiIntent.holeIndex
      local reflowMap = uiIntent.reflowMap

      -- Capture old layout to use as stable "from" positions
      local oldSlots = view.anchors.handSlots.slots
      local fromByIndex = {}
      for i = 1, oldSlotCount do
        if oldSlots[i] then fromByIndex[i] = deepcopy(oldSlots[i]) else fromByIndex[i] = nil end
      end

      view.handAnimations = {}

      local newSlotsAndMode = view.anchors.getHandSlots(newSlotCount)
      local newSlots = newSlotsAndMode.slots

      local oldSlotIndex = 1
      local newSlotIndex = 1

      local isDraw = newSlotCount > oldSlotCount
      local isDiscard = newSlotCount < oldSlotCount

      -- Only skip the hole on the side that actually has one.
      while oldSlotIndex <= oldSlotCount and newSlotIndex <= newSlotCount do
        if isDraw and newSlotIndex == holeIndex then
          -- Hole exists in the NEW layout (draw): skip this new index
          newSlotIndex = newSlotIndex + 1
        elseif isDiscard and oldSlotIndex == holeIndex then
          -- Hole exists in the OLD layout (discard): skip this old index
          oldSlotIndex = oldSlotIndex + 1
        else
          -- Move card from old slot -> new slot
          local from = fromByIndex[oldSlotIndex]
          local to = newSlots[newSlotIndex]

          if from and to then
            local cardId = reflowMap and reflowMap[newSlotIndex] or nil
            view.handAnimations[newSlotIndex] = Tween.new({
              from = from,
              to = to,
              id = cardId,
              duration = ANIMATION_INTERVALS.HAND_REFLOW_TIME,
              tag = TWEENS.CARD_REFLOW,
            })
          end

          oldSlotIndex = oldSlotIndex + 1
          newSlotIndex = newSlotIndex + 1
        end
      end

      -- Keep hover pointing at the same card instance after reflow
      if view.hover.currentInstanceId and reflowMap then
        local newHoverIndex = nil
        for idx, id in ipairs(reflowMap) do
          if id == view.hover.currentInstanceId then
            newHoverIndex = idx
            break
          end
        end
        view.hover.currentHandIndex = newHoverIndex
        for idx, tween in pairs(view.hover.animating) do
          if tween.id == view.hover.currentInstanceId and idx ~= newHoverIndex then
            view.hover.animating[idx] = nil
          end
        end
      end

      view.anchors.handSlots = newSlotsAndMode
    elseif uiIntent.kind == INTENTS.LOCK_UI_FOR_TASK then
      view.lockedTasks[uiIntent.taskId] = true
      view.inputLocked = true
    elseif uiIntent.kind == INTENTS.UNLOCK_UI_FOR_TASK then
      view.lockedTasks[uiIntent.taskId] = nil
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

  -- Unlock when all animations are done AND no task-based locks remain
  local handAnimEmpty = next(view.handAnimations) == nil
  local lockedTasksEmpty = next(view.lockedTasks) == nil
  if view.inputLocked and #view.active == 0 and handAnimEmpty and lockedTasksEmpty then
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
