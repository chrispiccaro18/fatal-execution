local Const               = {}

-- Tile and scale settings
Const.TILE_SIZE           = 32 -- source pixel size (per sprite)
Const.SCALE               = 4 -- integer up‑scale factor
-- Compute draw size from TILE_SIZE and SCALE
Const.DRAW_SIZE           = Const.TILE_SIZE * Const.SCALE

Const.CURRENT_SCREEN      = {
  START = "start",
  GAME  = "game",
}

Const.START_SCREEN_STATES = {
  LOADING    = "loading",
  MENU       = "menu",
  SELECT     = "select",
  NAME_ENTRY = "name_entry",
}

Const.HIT_IDS             = {
  START_SCREEN = {
    CONTINUE = "continue",
    NEW      = "new",
    OPTIONS  = "options",
    CHANGE   = "change",
    QUIT     = "quit",
  },
  IN_GAME_MENU = {
    CONTINUE  = "continue",
    OPTIONS   = "options",
    MAIN_MENU = "mainmenu",
    SAVE_QUIT = "savequit",
    ABANDON   = "abandon",
  },
  OPTIONS_MENU = {
    VOL_UP_music      = "vol_up_music",
    VOL_DOWN_music    = "vol_down_music",
    VOL_LABEL_music   = "vol_label_music",
    VOL_UP_sfx        = "vol_up_sfx",
    VOL_DOWN_sfx      = "vol_down_sfx",
    VOL_LABEL_sfx     = "vol_label_sfx",
    TOGGLE_TOOLTIPS   = "toggle_tooltips",
    TOGGLE_FULLSCREEN = "toggle_fullscreen",
    RES_LABEL         = "res_label",
    RES_LEFT          = "res_left",
    RES_RIGHT         = "res_right",
    BACK              = "options_back",
  },
}

Const.BUTTON_LABELS       = {
  START_SCREEN = {
    CONTINUE = "Continue",
    NEW      = "New Run",
    OPTIONS  = "Options",
    CHANGE   = "Change Profile",
    QUIT     = "Quit",
  },
  IN_GAME_MENU = {
    CONTINUE  = "Continue",
    OPTIONS   = "Options",
    MAIN_MENU = "Main Menu",
    SAVE_QUIT = "Save and Quit",
    ABANDON   = "Abandon Run",
  },
  OPTIONS_MENU = {
    VOLUME_music = "Music Volume",
    VOLUME_sfx = "SFX Volume",
    TOOLTIPS_ENABLED = "Tooltips: ON",
    TOOLTIPS_DISABLED = "Tooltips: OFF",
    FULLSCREEN_ENABLED = "Fullscreen: ON",
    FULLSCREEN_DISABLED = "Fullscreen: OFF",
    RESOLUTION = "Resolution: ",
    BACK = "Back to Menu",
  },
}

Const.VOLUME_CONTROLS     = {
  {
    key = "music",
    settingKey = "musicVolume",
    labelId = "VOLUME_music",
    upId = Const.HIT_IDS.OPTIONS_MENU.VOL_UP_music,
    downId = Const.HIT_IDS.OPTIONS_MENU.VOL_DOWN_music,
    labelHitId = Const.HIT_IDS.OPTIONS_MENU.VOL_LABEL_music,
  },
  {
    key = "sfx",
    settingKey = "sfxVolume",
    labelId = "VOLUME_sfx",
    upId = Const.HIT_IDS.OPTIONS_MENU.VOL_UP_sfx,
    downId = Const.HIT_IDS.OPTIONS_MENU.VOL_DOWN_sfx,
    labelHitId = Const.HIT_IDS.OPTIONS_MENU.VOL_LABEL_sfx,
  },
}

-- UI positions and dimensions
Const.CARD_WIDTH          = 180
Const.CARD_HEIGHT         = 270
Const.CARD_SPACING_X      = 20

Const.EFFECTS             = {
  MODIFY_HAND_SIZE = "modifyHandSize",
  GAIN_RAM = "gainRAM",
  MULTIPLY_EFFECTS = "multiplyEffects",
  THREAT_TICK = "threatTick"
}

Const.EFFECTS_TRIGGERS    = {
  START_OF_TURN = "startOfTurn",
  END_OF_TURN = "endOfTurn",
  IMMEDIATE = "immediate",
  ON_DRAW = "onDraw",
  ON_PLAY = "onPlay"
}

return Const
