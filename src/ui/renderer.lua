local Click            = require("ui.click")
local DestructorUI     = require("ui.elements.destructor")
local DeckUI           = require("ui.elements.deck")
local EffectsUI        = require("ui.elements.effects")
local EndTurnUI        = require("ui.elements.end_turn")
local HandUI           = require("ui.elements.hand")
local LogsUI           = require("ui.elements.logs")
local RAMUI            = require("ui.elements.ram")
local SystemsUI        = require("ui.elements.systems")
local ThreatsUI        = require("ui.elements.threats")
local AnimatingCardsUI = require("ui.animations.cards")

local Renderer  = {}

Renderer.drawUI = function(model, view)
  Click.clear()

  local anchors = view.anchors
  assert(anchors, "[Renderer.drawUI]: No anchors set in view!")
  local sections = anchors.sections

  SystemsUI.drawSystemsPanel(sections.systems, model.systems, model.currentSystemIndex)
  EffectsUI.drawEffects(sections.effects, model)
  LogsUI.drawLogs(sections.logs, model.log)
  HandUI.drawHand(view, model.hand)
  DeckUI.drawDeck(sections.deck, model.deck)
  RAMUI.drawRAM(sections.ram, model.ram)
  ThreatsUI.drawThreats(sections.threats, model.threats)
  EndTurnUI.drawEndTurnButton(sections.endTurn)

  local isDestructorEmpty = #model.destructorDeck == 0
  if isDestructorEmpty then DestructorUI.drawDestructor(sections.destructor, model.destructorDeck, model.destructorNullify) end

  AnimatingCardsUI.draw(view, model.animatingCards)

  if not isDestructorEmpty then DestructorUI.drawDestructor(sections.destructor, model.destructorDeck, model.destructorNullify) end
end

return Renderer
