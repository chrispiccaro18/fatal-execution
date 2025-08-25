local Click                 = require("ui.click")
local DestructorUI          = require("ui.elements.destructor")
local DeckUI                = require("ui.elements.deck")
local EffectsUI             = require("ui.elements.effects")
local EndTurnUI             = require("ui.elements.end_turn")
local HandUI                = require("ui.elements.hand")
local LogsUI                = require("ui.elements.logs")
local RAMUI                 = require("ui.elements.ram")
local SystemsUI             = require("ui.elements.systems")
local ThreatsUI             = require("ui.elements.threats")

local ShufflingDestructorUI = require("ui.animations.shuffling_destructor")
local AnimatingCardsUI      = require("ui.animations.cards")

local Renderer              = {}

Renderer.drawUI = function(model, view)
  Click.clear()

  local anchors = view.anchors
  assert(anchors, "[Renderer.drawUI]: No anchors set in view!")
  local sections = anchors.sections

  -- Draw all static UI elements
  SystemsUI.drawSystemsPanel(sections.systems, model.systems, model.currentSystemIndex)
  EffectsUI.drawEffects(sections.effects, model)
  LogsUI.drawLogs(sections.logs, model.log)
  DeckUI.drawDeck(sections.deck, model.deck)
  RAMUI.drawRAM(sections.ram, model.ram)
  ThreatsUI.drawThreats(sections.threats, model.threats)
  EndTurnUI.drawEndTurnButton(sections.endTurn)

  -- Draw the hand, which handles all its own internal animations (hover, reflow).
  HandUI.drawHand(view, model.hand)

  local isDestructorEmpty = #model.destructorDeck == 0
  if isDestructorEmpty then
    DestructorUI.drawDestructor(sections.destructor, model.destructorDeck, model.destructorNullify)
  end

  -- Draw cards in transit (e.g., deck-to-hand, hand-to-discard)
  AnimatingCardsUI.draw(view, model.animatingCards)

  if not isDestructorEmpty then
    if view.destructor and view.destructor.isShuffling then
      ShufflingDestructorUI.draw(view, sections.destructor, model.destructorDeck, model.destructorNullify)
    else
      DestructorUI.drawDestructor(sections.destructor, model.destructorDeck, model.destructorNullify)
    end
  end
end

return Renderer
