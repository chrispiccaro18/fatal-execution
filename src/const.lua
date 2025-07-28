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

return Const
