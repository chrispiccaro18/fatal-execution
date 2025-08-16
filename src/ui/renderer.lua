local cfg          = require("ui.cfg")
local Card         = require("ui.elements.card")
local Click        = require("ui.click")
local DestructorUI = require("ui.elements.destructor")
local DeckUI       = require("ui.elements.deck")
local EffectsUI    = require("ui.elements.effects")
local EndTurnUI    = require("ui.elements.end_turn")
local HandUI       = require("ui.elements.hand")
local LogsUI       = require("ui.elements.logs")
local RAMUI        = require("ui.elements.ram")
local SystemsUI    = require("ui.elements.systems")
local ThreatsUI    = require("ui.elements.threats")
local Tween        = require("ui.animations.tween")
local UI           = require("state.ui")

local Renderer     = {}

local function drawAnimatingCards(view, animatingCards)
  if not animatingCards then return end

  for id, card in pairs(animatingCards) do
    -- Use the rectForCard function which can recursively find the tween
    -- and get its interpolated position.
    local r, angle = Tween.rectForCard(view, id)

    if r then
      love.graphics.push()
      love.graphics.translate(r.x + r.w / 2, r.y + r.h / 2)
      love.graphics.rotate((angle or 0) * math.pi / 180)
      love.graphics.translate(-r.w / 2, -r.h / 2)
      Card.drawFace(card, 0, 0, r.w, r.h, cfg.handPanel.pad)
      love.graphics.pop()
    end
  end
end

Renderer.drawUI = function(model, view)
  Click.clear()

  local anchors = view.anchors
  assert(anchors, "[Renderer.drawUI]: No anchors set in view!")
  local sections = anchors.sections

  SystemsUI.drawSystemsPanel(sections.systems, model.systems, model.currentSystemIndex)
  EffectsUI.drawEffects(sections.effects, model)
  LogsUI.drawLogs(sections.logs, model.log)
  HandUI.drawHand(view, sections.play, model.hand)
  DeckUI.drawDeck(sections.deck, model.deck)
  RAMUI.drawRAM(sections.ram, model.ram)
  ThreatsUI.drawThreats(sections.threats, model.threats)
  DestructorUI.drawDestructor(sections.destructor, model.destructorDeck, model.destructorNullify)
  EndTurnUI.drawEndTurnButton(sections.endTurn)

  drawAnimatingCards(view, model.animatingCards)
end

return Renderer
