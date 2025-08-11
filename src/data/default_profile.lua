-- NOTE: When adding/removing profile fields:
--  1) Update schema/profile_spec.lua (ProfileSpec)
--  2) If you add new settings, update data/default_settings.lua instead
--  3) If new fields need defaults/normalization, update profiles/factory.lua
--  4) If the field needs migration, handle it in profiles/init.lua loadSlot

local Version = require("version")
local defaultSettings = require("data.default_settings")

-- Default profile structure
local defaultProfile = {
  name = "New Profile",
  settings = defaultSettings,
  progress = {
    unlockedSystems = { "Power" },
    endingsSeen = 0,
  },
  currentRun = false,
  gameVersion = Version.number,
}

return defaultProfile