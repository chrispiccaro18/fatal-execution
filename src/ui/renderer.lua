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

  SystemsUI.drawSystemsPanel(sections.systems, model.systems, model.currentSystemIndex)
  EffectsUI.drawEffects(sections.effects, model)
  LogsUI.drawLogs(sections.logs, model.log)
  HandUI.drawHand(sections.play, model.hand)
  DeckUI.drawDeck(sections.deck, model.deck)
  RAMUI.drawRAM(sections.ram, model.ram)
  ThreatsUI.drawThreats(sections.threats, model.threats)
  DestructorUI.drawDestructor(sections.destructor, model.destructorDeck, model.destructorNullify)
  EndTurnUI.drawEndTurnButton(sections.endTurn)
end

return Renderer
