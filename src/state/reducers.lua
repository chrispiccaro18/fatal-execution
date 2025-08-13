local Const            = require("const")
local immut            = require("util.immut")
local copy             = require("util.copy")

local Log              = require("game_state.log")
local Hand             = require("game_state.hand")
local Effects          = require("game_state.derived.effects")

local TURN_PHASES      = Const.TURN_PHASES
local ACTIONS          = Const.DISPATCH_ACTIONS
local TASKS            = Const.TASKS
local LOG_OPTS         = Const.LOG
local EFFECTS_TRIGGERS = Const.EFFECTS_TRIGGERS

local Reducers         = {}

function Reducers.reduce(model, action)
  local newModel = copy(model)
  local uiIntents = {}
  local newTasks = {}

  if action.type == ACTIONS.LOG_DEBUG then
    newModel = Log.add(
      newModel,
      action.entry,
      { visible = false, category = action.category, severity = LOG_OPTS.SEVERITY.DEBUG }
    )
  end

  if action.type == ACTIONS.BEGIN_TURN then
    local turn          = copy(newModel.turn)
    turn.turnCount      = turn.turnCount + 1
    turn.phase          = TURN_PHASES.IN_PROGRESS
    newModel.turn       = turn
    newModel            = Log.add(newModel, "--- Turn " .. turn.turnCount .. " begins ---")

    newModel.ram        = 0
    local activeEffects = Effects.collectActive(newModel, EFFECTS_TRIGGERS.BEGIN_TURN)
    if #activeEffects > 0 then
      local slices = {
        handSize = newModel.handSize,
        ram      = newModel.ram,
        threats  = newModel.threats
      }
      local notes = {}

      for _, ctx in ipairs(activeEffects) do
        local note = nil
        slices, note = Effects.applySlices(slices, ctx.effect, ctx)
        if note then
          notes[#notes + 1] = {
            entry = note.msg,
            opts = {
              category = LOG_OPTS.CATEGORY.EFFECT,
              severity = LOG_OPTS.SEVERITY.INFO,
              visible  = true, -- show to player; switch to false if you want hidden debug
              data     = { source = note.source, kind = note.kind, index = note.index, tag = note.tag },
            }
          }
        end
      end

      if slices.handSize ~= newModel.handSize then
        newModel = immut.assign(newModel, "handSize", slices.handSize)
      end
      if slices.ram ~= newModel.ram then
        newModel = immut.assign(newModel, "ram", slices.ram)
      end
      if slices.threats ~= newModel.threats then
        newModel = immut.assign(newModel, "threats", slices.threats)
      end

      if #notes > 0 then
        newModel = Log.addMany(newModel, notes)
      end
    end

    local handSize = newModel.handSize
    local have     = #newModel.hand
    local need     = math.max(0, handSize - have)

    -- Queue a small “deal” task that emits one DRAW_CARD per tick
    if need > 0 then
      newTasks[#newTasks + 1] = {
        kind      = TASKS.DEAL_CARDS,
        remaining = need,
        interval  = 1.0, -- sequential
        timer     = 0,
      }
    end

    return newModel, uiIntents, newTasks
  end

  if action.type == ACTIONS.DRAW_CARD then
    local handSize = newModel.handSize
    local newHand, newDeck, drawn = Hand.drawFromDeck(
      newModel.hand,
      newModel.deck,
      1,
      handSize
    )
    newModel.hand = newHand
    newModel.deck = newDeck

    if #drawn > 0 then
      local card = drawn[1]
      uiIntents[#uiIntents+1] = { kind = "card_draw", card = card }
      -- card.selectable = true
      -- local name = (type(card) == "table" and card.name) or "Unknown Card"
      -- newModel = Log.add(newModel, ("Drew %s."):format(name), {
      --   category = LOG_OPTS.CATEGORY.CARD_DRAW,
      --   severity = LOG_OPTS.SEVERITY.INFO,
      --   visible  = true,
      -- })
    else
      newModel = Log.add(newModel, "Deck empty: couldn't draw a card.", {
        category = LOG_OPTS.CATEGORY.CARD_DRAW,
        severity = LOG_OPTS.SEVERITY.WARN,
        visible  = true,
      })
    end
  end

  if action.type == ACTIONS.END_TURN then
    local turn          = copy(newModel.turn)
    turn.phase          = TURN_PHASES.END_TURN
    newModel.turn       = turn

    print("Ending turn:", turn.turnCount)
  end

  if action.type == ACTIONS.PLAY_CARD then
    local handIndex = action.idx
    if handIndex < 1 or handIndex > #newModel.hand then
      error("Invalid hand index: " .. tostring(handIndex))
    end

    local card = newModel.hand[handIndex]
    if not card then
      error("No card found at index: " .. tostring(handIndex))
    end

    print("Playing card:", card.name)
  end

  if action.type == ACTIONS.DISCARD_CARD then
    local handIndex = action.idx
    if handIndex < 1 or handIndex > #newModel.hand then
      error("Invalid hand index: " .. tostring(handIndex))
    end

    local card = newModel.hand[handIndex]
    if not card then
      error("No card found at index: " .. tostring(handIndex))
    end

    print("Discarding card:", card.name)
  end

  return newModel, uiIntents, newTasks
end

return Reducers
