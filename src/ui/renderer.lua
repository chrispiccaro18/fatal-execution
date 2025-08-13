local UI           = require("state.ui")
local SystemsUI    = require("ui.elements.systems")
local EffectsUI    = require("ui.elements.effects")
local LogsUI       = require("ui.elements.logs")
local HandUI       = require("ui.elements.hand")
local DeckUI       = require("ui.elements.deck")
local RAMUI        = require("ui.elements.ram")
local ThreatsUI    = require("ui.elements.threats")
local DestructorUI = require("ui.elements.destructor")
local EndTurnUI    = require("ui.elements.end_turn")

local Click        = require("ui.click")

local Renderer     = {}

Renderer.drawUI    = function(model, view)
  Click.clear()

  local anchors = view.anchors
  assert(anchors, "[Renderer.drawUI]: No anchors set in view!")

  local sections = anchors.sections
  local getHandSlots = anchors.getHandSlots

  SystemsUI.drawSystemsPanel(sections.systems, model.systems, model.currentSystemIndex)
  EffectsUI.drawEffects(sections.effects, model)
  LogsUI.drawLogs(sections.logs, model.log)

  -- ensure current hand slots exist and reflow if changed
  local handCount = #model.hand
  local newSlots  = getHandSlots(handCount)        -- {mode, slots}
  if not anchors.handSlots then
    anchors.handSlots = newSlots.slots
  elseif #anchors.handSlots == handCount then
    -- schedule reflow if geometry changed (cheap check on first + last x)
    local old = anchors.handSlots
    if old[1].x ~= newSlots.slots[1].x or old[#old].x ~= newSlots.slots[#newSlots.slots].x then
      local ids = {}
      for i,c in ipairs(model.hand) do ids[i] = c.instanceId end
      UI.reflowHand(view, old, newSlots.slots, ids)
      anchors.handSlots = newSlots.slots
    end
  else
    -- count changed (draw/discard) -> just snap new target now; your draw animation will handle incoming cards
    anchors.handSlots = newSlots.slots
  end

  HandUI.drawHand(view, sections.play, model.hand)
  DeckUI.drawDeck(sections.deck, model.deck)
  RAMUI.drawRAM(sections.ram, model.ram)
  ThreatsUI.drawThreats(sections.threats, model.threats)
  DestructorUI.drawDestructor(sections.destructor, model.destructorDeck, model.destructorNullify)
  EndTurnUI.drawEndTurnButton(sections.endTurn)
end

return Renderer
