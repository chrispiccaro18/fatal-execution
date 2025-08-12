local UI = {}

function UI.init()
  return {
    inputLocked = false,
    intents     = {},   -- queue of high-level requests (e.g., "deal_hand")
    active      = {},   -- expanded tweens (per-card)
    anchors     = nil,  -- { sections, handSlots, deckRect }
    doneFlags   = {},   -- doneFlags[kind] = true when finished
  }
end

local function makeTween(cardId, fromRect, toRect, duration)
  return {
    kind     = "card_fly",
    id       = cardId,
    t        = 0,
    duration = duration or 0.25,
    from     = { x = fromRect.x, y = fromRect.y },
    to       = { x = toRect.x,   y = toRect.y },
  }
end

function UI.schedule(view, intents)
  for _, it in ipairs(intents) do table.insert(view.intents, it) end
end

function UI.update(view, dt)
  -- 1) Expand high-level intents into active tweens
  -- Example: "deal_hand" -> per-card fly tweens
  if #view.intents > 0 and not view.inputLocked and view.anchors then
    local it = table.remove(view.intents, 1)
    if it.kind == "deal_hand" then
      view.inputLocked = true
      for i, cardId in ipairs(it.cards) do
        local slot = view.anchors.handSlots[i]
        table.insert(view.active, makeTween(cardId, view.anchors.deckRect, slot, 0.22 + 0.05*(i-1)))
      end
      view.dealCount = #it.cards
      view.doneFlags[it.kind] = false
      view.dealKind = it.kind
    elseif it.kind == "card_fly" then
      view.inputLocked = true
      table.insert(view.active, makeTween(it.cardId, it.fromRect, it.toRect, it.duration))
      view.doneFlags[it.kind] = false
    end
  end

  -- 2) Tick active tweens
  if #view.active > 0 then
    local finished = {}
    for idx, tw in ipairs(view.active) do
      tw.t = math.min(tw.t + dt, tw.duration)
      if tw.t >= tw.duration then table.insert(finished, idx) end
    end
    -- remove finished (back-to-front)
    for i = #finished, 1, -1 do table.remove(view.active, finished[i]) end
  end

  -- 3) Unlock + mark done when all tweens finished
  if #view.active == 0 and view.inputLocked then
    view.inputLocked = false
    if view.dealKind then
      view.doneFlags[view.dealKind] = true
      view.dealKind = nil
    end
  end
end

function UI.isDone(view, kind)
  -- return true when no active anims of 'kind'
  return true
end

return UI
