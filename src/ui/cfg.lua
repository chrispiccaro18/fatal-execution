local Const         = require("const")

local fonts         = {
  default = love.graphics.newFont(14),
  big     = love.graphics.newFont(18),
  xLarge  = love.graphics.newFont(22),
}

local colorDefaults = {
  black        = { 0, 0, 0 },
  white        = { 1, 1, 1 },
  blue         = { 0, 0.4, 1 },
  green        = { 0, 1, 0 },
  lightGreen   = { 0.6, 1, 0.6 },
  darkGreen    = { 0, 0.6, 0.1 },
  yellow       = { 1, 1, 0 },
  red          = { 1, 0, 0 },
  cardFaceGray = { 0.8, 0.8, 0.8 },
  lightGray    = { 0.5, 0.5, 0.5 },
  darkGray     = { 0.2, 0.2, 0.2 },
  darkerGray   = { 0.1, 0.1, 0.1 },
  transparent  = { 0, 0, 0, 0 },
  almostBlack  = { 0.07, 0.07, 0.07 },
}
-- All numbers are *fractions* of window width / height unless noted otherwise
return {
  -- Colors (RGBA 0-1)
  colors          = colorDefaults,
  fonts           = fonts,

  -- Global gutters & stroke
  gutter          = 2,
  lineWidth       = 2,

  -- Global font sizes
  fontSize        = 14, -- default font size
  fontSizeBig     = 18, -- larger font size for titles etc.
  fontSizeXL      = 22, -- extra large font size for important text

  -- Column split
  leftColW        = 0.72, -- 72 % of screen belongs to the left stack
  -- right column automatically = remainder

  -- Left-stack row heights (must sum to ≤ 1.0)
  systemsH        = 0.17, -- white
  effectsH        = 0.31, -- blue
  playH           = 0.40, -- green  (hand / playfield)
  deckH           = 0.12, -- yellow (draw pile etc.)

  systemsPanel    = {
    pad      = 10,  -- inner margin on all four sides
    boxW     = 120, -- fallback when the panel is very wide
    boxH     = 40,
    spacingX = 10,
    spacingY = 0,
    barH     = 30,
  },

  effectsPanel    = {
    pad = 8,
    lnH = 14,
    fontSize = 12,
  },

  logsPanel       = {
    pad = 8,
    lnH = 14,
    fontSize = 12,
  },

  ramPanel        = {
    pad      = 10,
    fontSize = 16,
  },

  deckPanel       = {
    pad           = 10,
    fontSize      = 14,
    deckW         = Const.CARD_WIDTH / 4,
    deckH         = Const.CARD_HEIGHT / 4,
    labelFontSize = 16,
  },

  threatsPanel    = {
    pad  = 10,
    font = fonts.big,
  },

  handPanel       = {
    pad           = 10,
    fontSize      = 12,
    cardW         = Const.CARD_WIDTH,
    cardH         = Const.CARD_HEIGHT,
    maxSpacingX   = 10, -- max spacing between cards
    minVisiblePx  = Const.CARD_WIDTH / 4, -- when overlapping, how much of next card is visible
    fanThresholdN = 2, -- switch to fan at/after this many cards
    angleSpanDeg  = 8, -- -- total span from left to right (e.g., -4..+4)
    hover          = {
      liftPx = 10,
      liftNeighborPx = 16,
      neighborSpreadPx = 12,
      scale = 1.08,
      neighborOverlapPx = 15,
    },
    fan = {
      enabled = true,
      -- The pivot point for the fan is calculated relative to the hand panel:
      -- x = panel.x + panel.w / 2
      -- y = panel.y + panel.h + pivotYOffset
      pivotYOffset = 300, -- pixels below the panel's bottom edge
      radius = 350,       -- pixels from pivot to card center
      -- Total angle of the fan adapts to hand size:
      centerLiftPx = 10,  -- How much higher the center card is than the edges
    },
  },

  destructorPanel = {
    pad                = 10,
    font               = fonts.big,
    cardW              = Const.CARD_WIDTH,
    cardH              = Const.CARD_HEIGHT,
    displayCardOffsetX = -10,
    displayCardOffsetY = -10,
  },

  endTurnPanel    = {
    pad      = 10,
    fontSize = 18,
    buttonW  = 200,
    buttonH  = 50,
  },

  -- End Game UI
  endGamePanel    = {
    pad           = 20,
    fontSize      = 24,

    restartButton = {
      pad         = 10,
      fontSize    = 18,
      buttonW     = 200,
      buttonH     = 50,
      borderColor = colorDefaults.white,
      textColor   = colorDefaults.black,
      bgColor     = colorDefaults.yellow,
    },

    quitButton    = {
      pad         = 10,
      fontSize    = 18,
      buttonW     = 200,
      buttonH     = 50,
      borderColor = colorDefaults.red,
      textColor   = colorDefaults.red,
      bgColor     = colorDefaults.black,
    },
  },
}
