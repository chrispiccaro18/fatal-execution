local Version         = require("version")
local defaultProfile  = require("data.default_profile")
local defaultSettings = require("data.default_settings")
local deepcopy        = require("util.deepcopy")

-- optional: validate on create (nice guardrails)
local Validate        = require("schema.validate")
local ProfileSchema   = require("schema.profile_spec")

local Factory = {}

local function clamp01(n)
  n = tonumber(n) or 0
  if n < 0 then return 0 end
  if n > 1 then return 1 end
  return n
end

local function normalizeSettings(s)
  if type(s) ~= "table" then
    print("[profiles/factory] invalid settings; using defaults")
    return deepcopy(defaultSettings, nil, { copyMeta = false })
  end
  local out = deepcopy(s, nil, { copyMeta = false })

  if not out then
    print("[profiles/factory] invalid settings; using defaults")
    return deepcopy(defaultSettings, nil, { copyMeta = false })
  end

  out.musicVolume     = clamp01(out.musicVolume ~= nil and out.musicVolume or defaultSettings.musicVolume)
  out.sfxVolume       = clamp01(out.sfxVolume   ~= nil and out.sfxVolume   or defaultSettings.sfxVolume)
  out.showTooltips    = not not (out.showTooltips ~= nil and out.showTooltips or defaultSettings.showTooltips)
  out.resolutionIndex = math.max(1, tonumber(out.resolutionIndex or defaultSettings.resolutionIndex or 1))
  out.fullscreen      = not not (out.fullscreen ~= nil and out.fullscreen or defaultSettings.fullscreen)
  return out
end

--- Build a brand-new profile object (not saved).
-- @param opts { name?: string }
function Factory.newProfile(opts)
  opts = opts or {}

  local p = deepcopy(defaultProfile, nil, { copyMeta = false })

  if not p then
    assert(false, "[profiles/factory] failed to create profile")
    return
  end

  -- Never allow nil here; your invariant is false | table
  if p.currentRun == nil then p.currentRun = false end

  p.name        = opts.name or p.name or "New Profile"
  p.gameVersion = Version.number
  p.createdAt   = os.time()
  p.updatedAt   = p.createdAt

  p.settings    = normalizeSettings(p.settings)

  -- Validate once on creation (quiet log on error; still return p)
  local ok, errs = Validate.validate(p, ProfileSchema.ProfileSpec)
  if not ok then
    print("[profiles/factory] default profile failed validation on create")
    for _, e in ipairs(errs or {}) do
      print(("  - %s: expected %s, got %s"):format(e.path or "(root)", tostring(e.expected), tostring(e.got)))
    end
  end

  return p
end

return Factory
