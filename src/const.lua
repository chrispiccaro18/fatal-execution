local Const                   = {}

Const.RNG_STREAMS             = {
  DECK_BUILD = "deck_build",
  DRAWS = "draws",
  DESTRUCTOR = "destructor",
  GENERAL = "general",
}

-- Tile and scale settings
Const.TILE_SIZE               = 32 -- source pixel size (per sprite)
Const.SCALE                   = 4  -- integer up‑scale factor
-- Compute draw size from TILE_SIZE and SCALE
Const.DRAW_SIZE               = Const.TILE_SIZE * Const.SCALE

Const.CURRENT_SCREEN          = {
  START = "start",
  GAME  = "game",
}

Const.START_SCREEN_STATES     = {
  LOADING    = "loading",
  MENU       = "menu",
  SELECT     = "select",
  NAME_ENTRY = "name_entry",
}

Const.DISPATCH_ACTIONS        = {
  BEGIN_TURN = "begin_turn",
  DRAW_CARD = "draw_card",
  FINISH_CARD_DRAW = "finish_card_draw",
  DISCARD_CARD = "discard_card",
  FINISH_CARD_DISCARD = "finish_card_discard",
  PLAY_CARD = "play_card",
  PLAYED_CARD_IN_CENTER = "played_card_in_center",
  PLAYED_CARD_IN_DECK = "played_card_in_deck",
  END_TURN = "end_turn",
  LOG_DEBUG  = "log_debug",
  TASK_IN_PROGRESS = "task_in_progress",
}

Const.TASKS                = {
  DEAL_CARDS = "deal_cards",
  DISCARD_CARD = "discard_card",
  PLAY_CARD = "play_card",
}

Const.UI                      = {
  ANIM = {
    -- CARD_DRAW_INTERVAL = 1, -- spacing between successive draws
    HAND_REFLOW_TIME = .75,
    CARD_DISCARD_TIME = .75,    -- time to discard a single card, SHOULD BE LESS THAN REFLOW TIME?
    CARD_DRAW_TIME = .75,      -- time to draw a single card
    CARD_HOVER_UP_TIME = 0.1,
    CARD_HOVER_DOWN_TIME = 0.5,
    PLAYED_CARD_TO_CENTER = 2,
    PLAYED_CARD_CENTER_PAUSE = 2,
    PLAYED_CARD_FROM_CENTER_TO_DECK = 2,
  },
  INTENTS = {
    ANIMATE_DRAW_DECK_TO_HAND = "animate_draw_deck_to_hand",
    ANIMATE_DISCARD_HAND_TO_DESTRUCTOR = "animate_discard_hand_to_destructor",
    ANIMATE_HAND_REFLOW = "animate_hand_reflow",
    SET_HOVERED_CARD = "set_hovered_card",
    LOCK_UI_FOR_TASK = "lock_ui_for_task",
    UNLOCK_UI_FOR_TASK = "unlock_ui_for_task",
    PLAY_CARD_TO_CENTER = "play_card_to_center",
    PLAY_CARD_PAUSE_THEN_TO_DECK = "play_card_pause_then_to_deck",
  },
  TWEENS = {
    CARD_FLY = "card_fly",
    CARD_DRAW = "card_draw",
    CARD_REFLOW = "card_reflow",
    CARD_DISCARD = "card_discard",
    CARD_HOVER_UP = "card_hover_up",
    CARD_HOVER_DOWN = "card_hover_down",
    PLAY_CARD_TO_CENTER = "play_card_to_center",
    PLAY_CARD_PAUSE_THEN_TO_DECK = "play_card_pause_then_to_deck",
  },
  HAND_LAYOUT_MODE = {
    SPACED = "spaced",
    OVERLAP = "overlap",
    FAN = "fan",
  }
}

Const.TURN_PHASES             = {
  BEGIN_FIRST_TURN = "begin_first_turn",
  START = "start",
  IN_PROGRESS = "in_progress",
  END_TURN = "end_turn",
  WON = "won",
  LOST = "lost",
}

Const.HIT_IDS                 = {
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
  CARD = "card",
}

Const.BUTTON_LABELS           = {
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

Const.CARD_STATES             = {
  IDLE = "idle",
  ANIMATING = "animating",
}

Const.CARDS                   = {
  TREE_SHAKING = {
    ID = "tree_shaking",
    NAME = "Tree Shaking"
  },
  DANGLING_POINTER = {
    ID = "dangling_pointer",
    NAME = "Dangling Pointer"
  },
  GURU_MEDITATION = {
    ID = "guru_meditation",
    NAME = "Guru Meditation"
  },
  MEMORY_LEAK = {
    ID = "memory_leak",
    NAME = "Memory Leak"
  },
  OOPS = {
    ID = "oops",
    NAME = "Oops"
  },
  GARBAGE_COLLECTION = {
    ID = "garbage_collection",
    NAME = "Garbage Collection"
  },
  SYSTEM_SHUFFLE = {
    ID = "system_shuffle",
    NAME = "System Shuffle"
  },
  MEMORY_PROBE = {
    ID = "memory_probe",
    NAME = "Memory Probe"
  },
  ANOMALY_MASK = {
    ID = "anomaly_mask",
    NAME = "Anomaly Mask"
  },
  PULSE_SPIKE = {
    ID = "pulse_spike",
    NAME = "Pulse Spike"
  }
}

Const.PLAY_EFFECT_KINDS       = {
  SYSTEM = "system",
  THREAT = "threat",
}

Const.PLAY_EFFECT_TYPES       = {
  PROGRESS = "progress",
  THREAT = "threat",
  SHUFFLE_DISRUPTOR = "shuffle_disruptor",
  DRAW = "draw",
  NULLIFY_DESTRUCTOR = "nullify_destructor",
  NONE = "none",
}

Const.DESTRUCTOR_EFFECT_TYPES = {
  PROGRESS = "progress",
  THREAT = "threat",
  DRAW_TO_DESTRUCTOR = "draw_to_destructor",
  THREAT_MULTIPLIER = "threat_multiplier",
  NONE = "none",
}

Const.ON_DISCARD_EFFECT_TYPES = {
  RAM_MULTIPLIER = "ram_multiplier",
}

Const.DECKS                   = {
  STARTER = "starter_v1",
}

Const.DECK_SPEC               = {
  PRESET = "preset",
  CUSTOM_LIST = "custom_list",
  CUSTOM_POOL = "custom_pool",
}

Const.DESTRUCTOR_DECKS        = {
  EMPTY = "empty",
}

Const.SYSTEMS                 = {
  POWER = {
    ID = "power",
    NAME = "Power"
  },
  REACTOR = {
    ID = "reactor",
    NAME = "Reactor"
  },
  THRUSTERS = {
    ID = "thrusters",
    NAME = "Thrusters"
  }
}

Const.THREATS                 = {
  IMPACT_IMMINENT = {
    ID = "impact_imminent",
    NAME = "Impact Imminent"
  }
}

Const.SHIPS                   = {
  BASE_SHIP = {
    ID = "base_ship_v1",
  }
}

Const.LOG                     =
{
  SEVERITY = {
    INFO  = "info",
    WARN  = "warn",
    ERROR = "error",
    DEBUG = "debug",

  },
  CATEGORY = {
    GENERAL = "general",
    TASK_DEBUG = "task_debug",
    CARD_DRAW = "card_draw",
    CARD_DISCARD = "card_discard",
    CARD_PLAY = "card_play",
    EFFECT = "effect"
  }
}

Const.VOLUME_CONTROLS         = {
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
Const.CARD_WIDTH              = 180
Const.CARD_HEIGHT             = 270
Const.CARD_SPACING_X          = 20

Const.EFFECTS                 = {
  MODIFY_HAND_SIZE = "modifyHandSize",
  GAIN_RAM = "gainRAM",
  MULTIPLY_EFFECTS = "multiplyEffects",
  THREAT_TICK = "threatTick"
}

Const.EFFECTS_TRIGGERS        = {
  START_OF_TURN = "startOfTurn",
  END_OF_TURN = "endOfTurn",
  IMMEDIATE = "immediate",
  ON_DRAW = "onDraw",
  ON_PLAY = "onPlay"
}

Const.END_TURN_BUTTON = {
  ID = "endTurnButton",
  LABEL = "END TURN",
}

return Const