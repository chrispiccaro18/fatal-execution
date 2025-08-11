-- NOTE: When adding/removing settings:
--  1) Add here with default value
--  2) Update schema/profile_spec.lua (SettingsSpec)
--  3) Update normalizeSettings() in profiles/factory.lua
--  4) (Optional) Migrate old profiles in profiles/init.lua loadSlot if needed

local defaultSettings = {
  musicVolume = 0.8,
  sfxVolume = 0.9,
  showTooltips = true,
  resolutionIndex = 1,
  fullscreen = false,
}

return defaultSettings