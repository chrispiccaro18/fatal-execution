local Const               = require("const")
local Tween               = require("ui.animations.tween")
local deepcopy            = require("util.deepcopy")
local General             = require("util.general")

local ANIMATION_INTERVALS = Const.UI.ANIM
local INTENTS             = Const.UI.INTENTS
local TWEENS              = Const.UI.TWEENS
local ACTIONS             = Const.DISPATCH_ACTIONS

local UI                  = {}
local DEBUG_UI            = false
function UI.setDebug(v) DEBUG_UI = not not v end

function UI.init()
  return {
    inputLocked          = false,
    intents              = {},
    active               = {}, -- For non-hand animations (draw, discard)
    anchors              = nil,
    hover                = {
      currentHandIndex = nil,
      currentInstanceId = nil,
      animating = {},
      spreadPx = Const.CARD_WIDTH / 4,
    },
    tweensById           = {}, -- map cardInstanceId -> tween (for robust lookup)
    handAnimations       = {}, -- For hand-internal animations (reflow)
    signals              = {},
    lockedTasks          = {},
    _debug_discard_count = 0,
    _last_hand_rects     = nil,
  }
end

local function debugShouldLog(view, tag)
  if not DEBUG_UI then return false end
  if tag == TWEENS.CARD_DISCARD then return true end
  if view and view._debug_discard_count and view._debug_discard_count > 0 then return true end
  return false
end

-- helper registry so tweens can be found/cleared by cardInstanceId
local function registerTween(view, tween)
  if not view or not tween then return end
  if tween.id then view.tweensById[tween.id] = tween end
  if debugShouldLog(view, tween and tween.tag) and General and tween then
    print("DEBUG: registerTween", tween.tag or "?", tween.id or "?")
    if tween.from then print("  from:", General.dump(tween.from)) end
    if tween.to then print("  to:  ", General.dump(tween.to)) end
  end
end
local function unregisterTween(view, tween)
  if not view or not tween then return end
  if tween.id then view.tweensById[tween.id] = nil end
  if debugShouldLog(view, tween and tween.tag) and tween then
    print("DEBUG: unregisterTween", tween.tag or "?", tween.id or "?")
  end
end

-- Helpers to derive instance id from a hand slot (anchors may carry different field names)
local local_getSlotInstanceId = function(slot)
  if not slot then return nil end
  return slot.cardInstanceId or slot.instanceId or slot.id or nil
end

-- Find slot index for a given instance id (scans current handSlots)
local function findSlotIndexForInstance(view, instanceId)
  if not view or not view.anchors or not view.anchors.handSlots or not instanceId then return nil end
  for i, slot in ipairs(view.anchors.handSlots.slots) do
    if local_getSlotInstanceId(slot) == instanceId then return i end
  end
  return nil
end

function UI.getCardInstanceIdAt(view, handIndex)
  if not view or not view.anchors or not view.anchors.handSlots then return nil end
  local slot = view.anchors.handSlots.slots[handIndex]
  return local_getSlotInstanceId(slot)
end

-- Utility: lookup a tween by card instance id
local function getTweenById(view, id)
  if not view or not id then return nil end
  return view.tweensById[id]
end

-- Helper exposed: get a sampled rect for an instance id if a tween exists,
-- otherwise try hover/static fallbacks.
function UI.getTweenById(view, id)
  return getTweenById(view, id)
end

function UI.getRectForInstance(view, instanceId)
  if not view or not instanceId then return nil end
  local t = getTweenById(view, instanceId)
  if t then return t:sample() end
  -- if currently hovered, return hover offset
  if view.hover.currentInstanceId == instanceId and view.hover.currentHandIndex and view.anchors and view.anchors.handSlots then
    local slot = view.anchors.handSlots.slots[view.hover.currentHandIndex]
    if slot then
      local n = #view.anchors.handSlots.slots
      local layout = view.anchors.getHandLayout(n, view.hover.currentHandIndex)
      return layout.slots[view.hover.currentHandIndex]
    end
  end
  -- try to find the index of this instance in the hand and fall back to index-based rect
  local idx = findSlotIndexForInstance(view, instanceId)
  if idx then return UI.getCardInHandRect(view, idx) end
  return nil
end


-- The single source of truth for a card's position *within the hand*.
function UI.getCardInHandRect(view, handIndex)
  -- Guard: require anchors/slots
  if not view or not view.anchors or not view.anchors.handSlots or not view.anchors.handSlots.slots then
    if debugShouldLog(view) then print("DEBUG: getCardInHandRect - missing anchors/slots") end
    return nil
  end

  -- Priority 1: Is there a hand-specific animation (reflow) running?
  if view.handAnimations[handIndex] then
    return view.handAnimations[handIndex]:sample()
  end

  -- Priority 2: Is there an active HOVER tween for this card?
  if view.hover.animating[handIndex] then
    return view.hover.animating[handIndex]:sample()
  end

  -- Priority 3: Default to its static slot in the hand, considering hover.
  -- The layout module now handles all hover logic.
  local n = #view.anchors.handSlots.slots
  local layout = view.anchors.getHandLayout(n, view.hover.currentHandIndex)
  if layout and layout.slots and layout.slots[handIndex] then
    return layout.slots[handIndex]
  end

  -- Fallback to the non-hovered layout if something went wrong
  return view.anchors.handSlots.slots[handIndex]
end

function UI.schedule(view, intents)
  for _, it in ipairs(intents) do table.insert(view.intents, it) end
end

function UI.update(view, dt)
  while #view.intents > 0 do
    local uiIntent = table.remove(view.intents, 1)

    if uiIntent.kind == INTENTS.SET_HOVERED_CARD then
      local newHoverIndex = uiIntent.handIndex
      if newHoverIndex ~= view.hover.currentHandIndex then
        local oldHoverIndex = view.hover.currentHandIndex
        local slotCount = #view.anchors.handSlots.slots

        -- Get a snapshot of where all cards currently are on screen
        local fromByIndex = {}
        for i = 1, slotCount do
          fromByIndex[i] = UI.getCardInHandRect(view, i)
        end

        -- Determine the target layout for all cards
        local targetLayout = view.anchors.getHandLayout(slotCount, newHoverIndex)
        local targetSlots = targetLayout.slots

        -- Update hover state *before* creating new tweens
        view.hover.currentHandIndex = newHoverIndex
        view.hover.currentInstanceId = uiIntent.cardInstanceId

        -- Create tweens for all cards to move to their new positions
        if not view.inputLocked then
          for i = 1, slotCount do
            local from = fromByIndex[i]
            local to = targetSlots[i]
            if from and to then
              if view.hover.animating[i] then unregisterTween(view, view.hover.animating[i]) end
              local cardId = UI.getCardInstanceIdAt(view, i)
              local duration
              if i == newHoverIndex then
                duration = ANIMATION_INTERVALS.CARD_HOVER_UP_TIME
              elseif i == oldHoverIndex then
                duration = ANIMATION_INTERVALS.CARD_HOVER_DOWN_TIME
              else
                duration = ANIMATION_INTERVALS.HAND_REFLOW_TIME
              end
              local t = Tween.new({
                from = deepcopy(from),
                to = deepcopy(to),
                id = cardId,
                duration = duration,
                tag = TWEENS.CARD_REFLOW, -- A generic tag for hand movements
              })
              view.hover.animating[i] = t
              registerTween(view, t)
            end
          end
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
        from = deepcopy(from),
        to = deepcopy(to),
        duration = ANIMATION_INTERVALS.CARD_DRAW_TIME,
        id = uiIntent.newCardInstanceId,
        tag = TWEENS.CARD_DRAW,
      })
      registerTween(view, tween)
      tween.onComplete = function()
        table.insert(
          view.signals,
          { type = ACTIONS.FINISH_CARD_DRAW, cardInstanceId = uiIntent.newCardInstanceId, taskId = uiIntent.taskId }
        )
      end
      table.insert(view.active, tween)
    elseif uiIntent.kind == INTENTS.ANIMATE_DISCARD_HAND_TO_DESTRUCTOR then
      view.inputLocked = true
      -- mark debug counting so prints happen during this discard operation
      view._debug_discard_count = (view._debug_discard_count or 0) + 1

      local from = UI.getCardInHandRect(view, uiIntent.discardedCardHandIndex)
      local to = view.anchors.getDestructorRect()
      local tween = Tween.new({
        from = deepcopy(from),
        to = deepcopy(to),
        duration = ANIMATION_INTERVALS.CARD_DISCARD_TIME,
        id = uiIntent.discardedCardInstanceId,
        tag = TWEENS.CARD_DISCARD,
      })
      registerTween(view, tween)
      tween.onComplete = function()
        -- decrement debug counter and emit finish signal
        view._debug_discard_count = math.max(0, (view._debug_discard_count or 1) - 1)
        table.insert(
          view.signals,
          { type = ACTIONS.FINISH_CARD_DISCARD, discardedCardInstanceId = uiIntent.discardedCardInstanceId }
        )
      end
      table.insert(view.active, tween)

      -- Snapshot current visible hand rects BEFORE clearing hover/spread state.
      -- This snapshot is consumed by the upcoming ANIMATE_HAND_REFLOW so reflow
      -- animates from the actual on-screen positions.
      if view.anchors and view.anchors.handSlots and view.anchors.handSlots.slots then
        local slotCount = #view.anchors.handSlots.slots
        view._last_hand_rects = {}
        for i = 1, slotCount do
          local r = UI.getCardInHandRect(view, i)
          view._last_hand_rects[i] = r and deepcopy(r) or nil
        end
      end

      if view.hover.currentHandIndex == uiIntent.discardedCardHandIndex then
        -- If the hovered card is being discarded, reset hover.
        view.hover.currentHandIndex = nil
        view.hover.currentInstanceId = nil
        if view.hover.animating[uiIntent.discardedCardHandIndex] then
          unregisterTween(view, view.hover.animating[uiIntent.discardedCardHandIndex])
        end
        view.hover.animating[uiIntent.discardedCardHandIndex] = nil
      end
    elseif uiIntent.kind == INTENTS.ANIMATE_HAND_REFLOW then
      view.inputLocked = true

      local newSlotCount = uiIntent.newSlotCount
      local oldSlotCount = uiIntent.oldSlotCount
      local holeIndex = uiIntent.holeIndex
      local reflowMap = uiIntent.reflowMap

      -- Capture current on-screen rects BEFORE clearing handAnimations so we sample
      -- any active hand tweens / hover tweens as the "from" positions.
      local fromByIndex = {}
      if view._last_hand_rects then
        for i = 1, oldSlotCount do
          fromByIndex[i] = view._last_hand_rects[i] and deepcopy(view._last_hand_rects[i]) or nil
        end
        -- consume snapshot so future unrelated reflows don't reuse it
        view._last_hand_rects = nil
      else
        for i = 1, oldSlotCount do
          local cur = UI.getCardInHandRect(view, i)
          fromByIndex[i] = cur and deepcopy(cur) or nil
        end
      end

      -- unregister and clear any existing hand animations (now safe to clear)
      for _, t in pairs(view.handAnimations) do unregisterTween(view, t) end
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
            if view.handAnimations[newSlotIndex] then unregisterTween(view, view.handAnimations[newSlotIndex]) end
            local t = Tween.new({
              from = deepcopy(from),
              to = deepcopy(to),
              id = cardId,
              duration = ANIMATION_INTERVALS.HAND_REFLOW_TIME,
              tag = TWEENS.CARD_REFLOW,
            })
            view.handAnimations[newSlotIndex] = t
            registerTween(view, t)
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
            unregisterTween(view, tween)
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
    if tween:update(dt) then
      unregisterTween(view, tween)
      view.hover.animating[index] = nil
    end
  end
  for index, tween in pairs(view.handAnimations) do
    if tween:update(dt) then
      unregisterTween(view, tween)
      view.handAnimations[index] = nil
    end
  end
  for i = #view.active, 1, -1 do
    if view.active[i]:update(dt) then
      unregisterTween(view, view.active[i])
      table.remove(view.active, i)
    end
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
