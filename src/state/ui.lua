local Const = require("const")
local Tween = require("ui.animations.tween")
local HandUI = require("ui.elements.hand")

local ANIMATION_INTERVALS = Const.UI.ANIM
local INTENTS = Const.UI.INTENTS
local TWEENS = Const.UI.TWEENS
local CARD_STATES = Const.CARD_STATES

local UI = {}

function UI.init()
  return {
    inputLocked = false,
    intents     = {},  -- queue of high-level requests (e.g., "deal_hand")
    active      = {},  -- expanded tweens (per-card)
    anchors     = nil, -- { sections, handSlots, deckRect }
    doneFlags   = {},  -- doneFlags[kind] = true when finished
    signals     = {},  -- queue of { type = "done", kind, payload }
  }
end

function UI.schedule(view, intents)
  for _, it in ipairs(intents) do table.insert(view.intents, it) end
end

function UI.ensureHandLayout(view, hand, anchors)
  if view.inputLocked or (view.active and #view.active > 0) or view._pendingDraw or view._pendingReflow then
    return false
  end

  local n = #hand
  local target = anchors.getHandSlots(n).slots -- authoritative geometry for current state

  -- always keep a table (avoid nil checks elsewhere)
  anchors.handSlots = anchors.handSlots or {}

  -- First time / empty hand → just set targets and bail
  if n == 0 then
    if #anchors.handSlots ~= 0 then anchors.handSlots = {} end
    return false
  end
  if #anchors.handSlots == 0 then
    anchors.handSlots = target
    return false
  end

  -- Same count → consider a reflow (covers handSize changes & mode flip too)
  if #anchors.handSlots == #target then
    local old = anchors.handSlots
    local changed =
        (old[1].x ~= target[1].x) or
        (old[#old].x ~= target[#target].x) or
        ((old[1].angle or 0) ~= (target[1].angle or 0)) or
        ((old[#old].angle or 0) ~= (target[#target].angle or 0))

    if changed then
      local ids = {}
      for i, c in ipairs(hand) do ids[i] = c.instanceId end -- 👈 use instanceId
      UI.reflowHand(view, old, target, ids)
      anchors.handSlots = target
      return true
    else
      return false
    end
  end

  -- Different count (draw/discard) → snap new targets; individual draw/discard anims will handle motion
  anchors.handSlots = target
  return false
end

function UI.reflowHand(view, fromSlots, toSlots, ids)
  -- create a tween per card i -> i
  view.inputLocked = true
  for i, id in ipairs(ids) do
    local f, t = fromSlots[i], toSlots[i]
    -- TODO: use makeTween instead
    table.insert(view.active, {
      kind = "card_fly",
      id = id,
      elapsed = 0,
      duration = 0.18,
      delay = 0,
      from = { x = f.x, y = f.y, w = f.w, h = f.h },
      to = { x = t.x, y = t.y, w = t.w, h = t.h },
      fromAngle = f.angle or 0,
      toAngle = t.angle or 0,
    })
  end
end

function UI.update(view, dt)
  -- clear per-frame done flags
  view.doneFlags = {}
  view.signals   = {}

  -- 1) Expand one high-level intent when possible
  if #view.intents > 0 and not view.inputLocked and view.anchors then
    local uiIntent = table.remove(view.intents, 1)

    if uiIntent.kind == INTENTS.CARD_DRAW then
      -- Expect uiIntent = { kind=CARD_DRAW, cardInstanceId, nCardsInHand, existingInstanceIds }
      view.inputLocked = true
      -- card.state = CARD_STATES.ANIMATING
      -- card.selectable = false
      HandUI.set(uiIntent.cardInstanceId, { state = CARD_STATES.ANIMATING, selectable = false })
      local oldSlots = view.anchors.handSlots or {}

      local targetSlots = view.anchors.getHandSlots(uiIntent.nCardsInHand).slots
      local landingSlot = targetSlots[uiIntent.nCardsInHand]

      local deckR = view.anchors.getDeckRect()

      table.insert(view.active, Tween.makeTween(
        uiIntent.cardInstanceId,
        deckR,
        landingSlot,
        ANIMATION_INTERVALS.CARD_DRAW_TIME,
        0
      ))

      -- remember to emit which cards to unlock on completion
      view._pendingDraw = {
        ids = { uiIntent.cardInstanceId },
        existingInstanceIds = uiIntent.existingInstanceIds or {},
        oldSlots = oldSlots,
        newSlots = targetSlots,
      }
    elseif uiIntent.kind == INTENTS.CARD_FLY then
      view.inputLocked = true
      table.insert(view.active, Tween.makeTween(
        uiIntent.cardId, uiIntent.fromRect, uiIntent.toRect,
        uiIntent.duration or 0.20, uiIntent.delay or 0
      ))
      view._pendingFly = { kind = TWEENS.CARD_FLY, id = uiIntent.cardId }
    end
  end

  -- 2) Tick active tweens
  if #view.active > 0 then
    local finishedIdx = {}
    for idx, tw in ipairs(view.active) do
      tw.elapsed = tw.elapsed + dt
      if tw.elapsed >= (tw.delay + tw.duration) then
        table.insert(finishedIdx, idx)
      end
    end
    for i = #finishedIdx, 1, -1 do table.remove(view.active, finishedIdx[i]) end
  end

  -- 3) Unlock + mark done + signal payload when queue drains
  if view.inputLocked and #view.active == 0 then
    view.inputLocked = false

    -- DRAW DONE?
    if view._pendingDraw then
      local pd = view._pendingDraw
      view._pendingDraw = nil

      -- 1) Flip selectability on the newly drawn card(s)
      for _, id in ipairs(pd.ids or {}) do
        HandUI.set(id, { state = CARD_STATES.IDLE, selectable = true })
      end

      -- 2) If geometry changed, schedule reflow for existing cards
      local old = pd.oldSlots or {}
      local new = pd.newSlots or {}
      local needReflow = false
      if #old == #new and #new > 0 and #(pd.existingInstanceIds or {}) > 0 then
        -- cheap compare: first/last x or angle changed
        needReflow =
            (old[1].x ~= new[1].x) or (old[#old].x ~= new[#new].x) or
            ((old[1].angle or 0) ~= (new[1].angle or 0)) or
            ((old[#old].angle or 0) ~= (new[#new].angle or 0))
      end

      if needReflow then
        -- 3) Enqueue a tween per existing card id from old[i] -> new[i]
        for i, id in ipairs(pd.existingInstanceIds) do
          local from = old[i]
          local to   = new[i]
          -- guard: if from/to missing, skip (defensive)
          if from and to then
            table.insert(view.active, Tween.makeTween(
              id,
              { x = from.x, y = from.y, w = from.w, h = from.h, angle = from.angle or 0 },
              { x = to.x, y = to.y, w = to.w, h = to.h, angle = to.angle or 0 },
              0.18, 0.00
            ))
          end
        end

        -- 4) Now that tweens are queued, update target slots
        view.anchors.handSlots = new

        -- 5) Keep input locked until this reflow finishes
        view.inputLocked = true
        view._pendingReflow = { kind = "reflow_hand" }
      else
        -- No reflow needed; set targets immediately
        view.anchors.handSlots = new
        -- Optionally emit a "draw done" signal
        view.doneFlags["card_draw_done"] = true
        table.insert(view.signals, { type = "done", kind = "card_draw_done", payload = { ids = pd.ids } })
      end
    elseif view._pendingReflow then
      -- REFLOW DONE
      view.doneFlags["reflow_hand"] = true
      table.insert(view.signals, { type = "done", kind = "reflow_hand" })
      view._pendingReflow = nil
    end
  end
end

-- Consumers (e.g., controller/game loop) can poll these:
function UI.isDone(view, kind) return view.doneFlags[kind] == true end

function UI.consumeSignals(view)
  local sigs = view.signals
  view.signals = {}
  return sigs
end

return UI
