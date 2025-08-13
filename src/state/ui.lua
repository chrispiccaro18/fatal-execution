local Const = require("const")
local General = require("util.general")

local ANIMATION_INTERVALS = Const.UI.ANIM
local INTENTS = Const.UI.INTENTS
local TWEENS = Const.UI.TWEENS

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

local function makeTween(cardId, fromRect, toRect, duration, delay)
  return {
    kind     = TWEENS.CARD_FLY,
    id       = cardId,
    elapsed  = 0,
    duration = duration,
    delay    = delay,
    from     = { x = fromRect.x, y = fromRect.y, w = fromRect.w, h = fromRect.h },
    to       = { x = toRect.x, y = toRect.y, w = toRect.w, h = toRect.h },
  }
end

function UI.schedule(view, intents)
  for _, it in ipairs(intents) do table.insert(view.intents, it) end
end

local function tweenProgress(tw)
  local p = (tw.elapsed - tw.delay) / tw.duration
  return General.clamp(p, 0, 1)
end

local function tweenRect(tw)
  local p = General.easeOutCubic(tweenProgress(tw))
  local r = {
    x = General.lerp(tw.from.x, tw.to.x, p),
    y = General.lerp(tw.from.y, tw.to.y, p),
    w = General.lerp(tw.from.w, tw.to.w, p),
    h = General.lerp(tw.from.h, tw.to.h, p),
  }
  local ang = General.lerp(tw.fromAngle or 0, tw.toAngle or 0, p)
  return r, ang
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
    local it = table.remove(view.intents, 1)

    if it.kind == "deal_hand" then
      view.inputLocked = true
      -- optional: clear selectability while animating
      for _, id in ipairs(it.cards) do HandUI.set(id, { phase = "animating", selectable = false }) end

      -- staggered fan-out from deck -> handSlots[1..N]
      for i, cardId in ipairs(it.cards) do
        local slot = view.anchors.handSlots[i]
        local delay = 0.06 * (i - 1)
        table.insert(view.active, makeTween(cardId, view.anchors.deckRect, slot, 0.22, delay))
      end
      -- remember to emit which cards to unlock on completion
      view._pendingDeal = { kind = "deal_hand", cards = copy(it.cards) }
    elseif it.kind == "card_fly" then
      view.inputLocked = true
      table.insert(view.active, makeTween(it.cardId, it.fromRect, it.toRect, it.duration or 0.20, it.delay or 0))
      view._pendingFly = { kind = "card_fly", id = it.cardId }
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

    if view._pendingDeal then
      local payload = view._pendingDeal
      view._pendingDeal = nil
      view.doneFlags[payload.kind] = true
      table.insert(view.signals, { type = "done", kind = payload.kind, payload = payload })

      -- flip selectability now that animation has ended
      for _, id in ipairs(payload.cards) do HandUI.set(id, { phase = "idle", selectable = true }) end
    end

    if view._pendingFly then
      local payload = view._pendingFly
      view._pendingFly = nil
      view.doneFlags[payload.kind] = true
      table.insert(view.signals, { type = "done", kind = payload.kind, payload = payload })
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

-- Where to draw a given card *right now*
-- Falls back to its hand slot if no active tween is running for it.
function UI.rectForCard(view, cardId, handIndex)
  -- 1) active tween?
  for _, tw in ipairs(view.active) do
    if tw.kind == "card_fly" and tw.id == cardId then
      return tweenRect(tw)
    end
  end
  -- 2) fall back to anchors.handSlots
  local slots = view.anchors and view.anchors.handSlots
  if slots and slots[handIndex] then
    local s = slots[handIndex]
    return { x = s.x, y = s.y, w = s.w, h = s.h }, (s.angle or 0)
  end
  return { x = 0, y = 0, w = 0, h = 0 }, 0
end

return UI
