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