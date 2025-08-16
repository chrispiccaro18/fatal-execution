local Const   = require("const")
local Tween   = require("ui.animations.tween")
local deepcopy = require("util.deepcopy")

local ANIMATION_INTERVALS = Const.UI.ANIM
local INTENTS             = Const.UI.INTENTS
local TWEENS              = Const.UI.TWEENS
local ACTIONS             = Const.DISPATCH_ACTIONS

local UI                  = {}

function UI.init()
  return {
    inputLocked = false,
    intents     = {},
    active      = {},
    anchors     = nil,
    signals     = {},
  }
end

function UI.schedule(view, intents)
  for _, it in ipairs(intents) do table.insert(view.intents, it) end
end

function UI.update(view, dt)
  -- Process one intent per frame.
  if #view.intents > 0 and not view.inputLocked then
    local uiIntent = table.remove(view.intents, 1)

    if uiIntent.kind == INTENTS.ANIMATE_DRAW_AND_REFLOW then
      view.inputLocked = true

      local currentSlots = deepcopy(view.anchors.handSlots or {})
      local newSlots = view.anchors.getHandSlots(uiIntent.finalSlotCount).slots
      local deckR = view.anchors.getDeckRect()

      -- Create the draw tween for the new card
      local drawTween = Tween.new({
        from = deckR,
        to = newSlots[uiIntent.finalSlotCount],
        duration = ANIMATION_INTERVALS.CARD_DRAW_TIME,
        id = uiIntent.newCardInstanceId,
        tag = TWEENS.CARD_DRAW,
      })

      -- Create the reflow tweens for existing cards
      local reflowTweens = {}
      if #uiIntent.existingInstanceIds > 0 then
        for i, id in ipairs(uiIntent.existingInstanceIds) do
          local from = currentSlots[i]
          local to   = newSlots[i]
          if from and to then
            table.insert(reflowTweens, Tween.new({
              from = { x = from.x, y = from.y, w = from.w, h = from.h, angle = from.angle or 0 },
              to = { x = to.x, y = to.y, w = to.w, h = to.h, angle = to.angle or 0 },
              duration = ANIMATION_INTERVALS.HAND_REFLOW_TIME,
              id = id,
              tag = TWEENS.CARD_REFLOW,
            }))
          end
        end
      end

      -- Create the master animation group
      local masterGroup
      if #reflowTweens > 0 then
        local reflowGroup = Tween.parallel(reflowTweens)
        masterGroup = Tween.parallel({ reflowGroup, drawTween })
      else
        masterGroup = drawTween
      end

      -- Attach the completion signal
      masterGroup.onComplete = function()
        table.insert(view.signals, {
          type = ACTIONS.FINISH_CARD_DRAW,
          cardInstanceId = uiIntent.newCardInstanceId,
          taskId = uiIntent.taskId
        })
      end

      table.insert(view.active, masterGroup)
      view.anchors.handSlots = newSlots
    end
  end

  -- Tick active tweens
  if #view.active > 0 then
    local finishedIdx = {}
    for idx, tw in ipairs(view.active) do
      if tw:update(dt) then
        table.insert(finishedIdx, idx)
      end
    end
    for i = #finishedIdx, 1, -1 do table.remove(view.active, finishedIdx[i]) end
  end

  -- Unlock when all animations and subsequent intents are processed
  if view.inputLocked and #view.active == 0 and #view.intents == 0 then
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