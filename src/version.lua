-- ===========================
--  PROJECT UPDATE CHECKLIST
-- ===========================
--
-- When adding or removing fields:
--
-- PROFILE FIELDS:
--  1) Update data/default_profile.lua
--  2) Update schema/profile_spec.lua (ProfileSpec)
--  3) If the field needs defaults/normalization, update profiles/factory.lua
--  4) If the field needs migration for old saves, add logic in profiles/init.lua loadSlot
--
-- SETTINGS FIELDS:
--  1) Add to data/default_settings.lua with default value
--  2) Update schema/profile_spec.lua (SettingsSpec)
--  3) Update normalizeSettings() in profiles/factory.lua
--  4) (Optional) Migrate old profiles in profiles/init.lua loadSlot if needed
--
-- MODEL (gameState / currentRun) FIELDS:
--  1) Update src/model/init.lua (Model.new) with default
--  2) Update schema/model_spec.lua (ModelSpec) to match shape
--  3) If the field has a complex sub-shape, create a sub-spec and require it in model_spec.lua
--  4) If the field is derived/ephemeral, consider excluding it from persisted saves
--     (persistedSlice or save logic)
--  5) If the field must be migrated for old saves, handle it in profiles/init.lua loadSlot

local VERSION_TAG = "0.1.1"

local Version = {}

Version.number = VERSION_TAG

function Version.warnIfMismatch(context, savedVersion)
  local cur = Version.number or "unknown"
  if type(savedVersion) ~= "string" or savedVersion == "" then
    print(("[version] %s: missing/invalid gameVersion; expected %s")
      :format(context, cur))
    return true
  end
  if savedVersion ~= cur then
    print(("[version] %s: gameVersion %s != %s (current) — migration may be required.")
      :format(context, savedVersion, cur))
    return true
  end
  return false
end

return Version