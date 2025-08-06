local Const               = {}

-- Tile and scale settings
Const.TILE_SIZE           = 32 -- source pixel size (per sprite)
Const.SCALE               = 4  -- integer up‑scale factor
-- Compute draw size from TILE_SIZE and SCALE
Const.DRAW_SIZE           = Const.TILE_SIZE * Const.SCALE

-- UI positions and dimensions
Const.CARD_WIDTH          = 180
Const.CARD_HEIGHT         = 270
Const.CARD_SPACING_X      = 20

Const.EFFECTS = {
  MODIFY_HAND_SIZE = "modifyHandSize",
  GAIN_RAM = "gainRAM",
  MULTIPLY_EFFECTS = "multiplyEffects",
  THREAT_TICK = "threatTick"
}

Const.EFFECTS_TRIGGERS = {
  START_OF_TURN = "startOfTurn",
  END_OF_TURN = "endOfTurn",
  IMMEDIATE = "immediate",
  ON_DRAW = "onDraw",
  ON_PLAY = "onPlay"
}

return Const
