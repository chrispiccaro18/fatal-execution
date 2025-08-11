local T = require("schema.types")

-- Settings shape (from data/default_settings.lua)
local SettingsSpec = T.shape({
  musicVolume    = T.num,
  sfxVolume      = T.num,
  showTooltips   = T.bool,
  resolutionIndex= T.num,
  fullscreen     = T.bool,
}, { __allowUnknown = false })

-- Progress shape (from data/default_profile.lua)
local ProgressSpec = T.shape({
  unlockedSystems = T.arr(T.str),
  endingsSeen     = T.num,
}, { __allowUnknown = false })

-- Profile:
-- Note: currentRun is validated separately. Here we just enforce “not nil”
-- and allow either `false` or a table (one-of). Easiest way: accept `any`
-- here and do the stricter check in load/save code.
local ProfileSpec = T.shape({
  name        = T.str,
  settings    = SettingsSpec,
  progress    = ProgressSpec,
  currentRun  = T.any,     -- must NOT be nil (checked in code); either false or table
  gameVersion = T.str,     -- helpful for migrations
  createdAt   = T.optional(T.num),     -- optional, for tracking profile creation time
  updatedAt   = T.optional(T.num),     -- optional, for tracking profile update time
}, { __allowUnknown = false })

return {
  SettingsSpec = SettingsSpec,
  ProgressSpec = ProgressSpec,
  ProfileSpec  = ProfileSpec,
}
