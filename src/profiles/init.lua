-- deepcopy options
-- skipFns=true, skipUd=true, copyMeta=false
local deepcopy       = require("util.deepcopy")
local ProfilesUtils  = require("profiles.utils")
local Factory        = require("profiles.factory")
local Version        = require("version")
local Validate       = require("schema.validate")
local ProfileSchema  = require("schema.profile_spec")
local ModelSchemas   = require("schema.model_spec")

local Profiles       = {}

local MAX_PROFILES   = 3
local savePrefix     = "profile_"
local cachedProfiles = {}

local SAVE_DEBOUNCE  = 0.5
local dirty          = {} -- [index] = true if there are unsaved changes
local timers         = {} -- [index] = seconds remaining until save

-- ---------- utils ----------
local function getFilename(index)
  return savePrefix .. tostring(index) .. ".lua"
end

-- ---------- IO ----------
local function loadSlot(index)
  local filename = getFilename(index)
  local info = love.filesystem.getInfo(filename)
  if not info then
    cachedProfiles[index] = nil
    return nil
  end

  local okLoad, chunk = pcall(love.filesystem.load, filename)
  if not okLoad or not chunk then
    cachedProfiles[index] = nil
    return nil
  end

  local okRun, data = pcall(chunk)
  if not okRun or type(data) ~= "table" then
    cachedProfiles[index] = nil
    return nil
  end

  Version.warnIfMismatch(("profile slot %s"):format(index), data.gameVersion)

  local okProf, errsProf = Validate.validate(data, ProfileSchema.ProfileSpec)
  if not okProf then
    print(("[profiles] slot %s: profile failed validation."):format(tostring(index)))
    for _, e in ipairs(errsProf) do
      print(("  - %s: expected %s, got %s"):format(e.path or "(root)", tostring(e.expected), tostring(e.got)))
    end
    -- Optional: try to patch common issues (e.g., missing currentRun)
  end

  -- Validate currentRun, and false it if invalid.
  local run = data.currentRun
  if run == nil then
    -- Should never be nil; treat as error.
    print(("[profiles] slot %s: currentRun was nil; setting to false."):format(tostring(index)))
    data.currentRun = false
  elseif run == false then
    -- Explicitly no active run; nothing to validate.
    print(("[profiles] slot %s: currentRun was false; nothing to validate."):format(tostring(index)))
  elseif type(run) ~= "table" then
    -- Unexpected type
    print(("[profiles] slot %s: currentRun has invalid type %s; setting to false.")
      :format(tostring(index), type(run)))
    data.currentRun = false
  else
    local ok, errs = Validate.validate(run, ModelSchemas.ModelSpec)

    -- Only try the deckSpec union check if we have the fields
    local okDeckSpec, errsDeck = true, nil
    if ok and run.runConfig and run.runConfig.deckSpec then
      okDeckSpec, errsDeck = ModelSchemas.validateDeckSpecUnion(run.runConfig.deckSpec, Validate.validate)
    end

    if (not ok) or (not okDeckSpec) then
      print(("[profiles] currentRun failed validation for slot %s; clearing it."):format(tostring(index)))
      if errs then
        for _, e in ipairs(errs) do
          print(("  - %s: expected %s, got %s"):format(e.path or "(root)", tostring(e.expected), tostring(e.got)))
        end
      end
      if errsDeck then
        for _, e in ipairs(errsDeck) do
          print(("  - %s: expected %s, got %s"):format(e.path or "(deckSpec)", tostring(e.expected), tostring(e.got)))
        end
      end
      data.currentRun = false
    end
  end

  cachedProfiles[index] = data
  return data
end

local function saveSlot(index)
  local data = cachedProfiles[index]
  if not data then return end
  local encoded = "return " .. ProfilesUtils.serialize(data)
  love.filesystem.write(getFilename(index), encoded)
end

-- ---------- cache-safe access ----------
function Profiles._getProfileData(index)
  assert(index >= 1 and index <= MAX_PROFILES, "Invalid profile index")
  if not cachedProfiles[index] then
    loadSlot(index)
  end
  return cachedProfiles[index]
end

-- ---------- debounce helpers ----------
function Profiles.touch(index)
  -- Mark dirty and (re)start the timer
  dirty[index]  = true
  timers[index] = SAVE_DEBOUNCE
end

function Profiles.flush(index)
  if dirty[index] then
    saveSlot(index)
    dirty[index]  = nil
    timers[index] = nil
  end
end

function Profiles.flushAll()
  for i = 1, MAX_PROFILES do
    if dirty[i] then
      saveSlot(i)
      dirty[i]  = nil
      timers[i] = nil
    end
  end
end

-- ---------- lifecycle ----------
function Profiles.init()
  print("[Profiles.init]", love.filesystem.getSaveDirectory())
  local summary = {}
  for i = 1, MAX_PROFILES do
    local data = loadSlot(i) -- may be nil if no file
    summary[i] = { exists = data ~= nil }
  end
  return summary
end

function Profiles.update(dt)
  local toCheck = {}
  for i, remaining in pairs(timers) do
    toCheck[i] = remaining
  end
  for i, remaining in pairs(toCheck) do
    remaining = remaining - dt
    if remaining <= 0 then
      Profiles.flush(i)
    else
      timers[i] = remaining
    end
  end
end

-- ---------- create/delete ----------
function Profiles.create(index, name)
  assert(index >= 1 and index <= MAX_PROFILES, "Invalid profile index")
  if Profiles.profileExists(index) then return false end
  local fallbackName = "Profile " .. index
  local p = Factory.newProfile({ name = name or fallbackName })
  cachedProfiles[index] = p
  saveSlot(index)
  return true
end

function Profiles.delete(index)
  love.filesystem.remove(getFilename(index))
  cachedProfiles[index] = nil
end

-- ---------- metadata ----------
function Profiles.getMaxProfiles() return MAX_PROFILES end
function Profiles.profileExists(index) return love.filesystem.getInfo(getFilename(index)) ~= nil end
function Profiles.getCachedProfiles() return cachedProfiles end
function Profiles.get(index) return Profiles._getProfileData(index) end

-- ---------- accessors ----------
function Profiles.getSettings(i) return Profiles._getProfileData(i) and Profiles._getProfileData(i).settings end
function Profiles.getProgress(i) return Profiles._getProfileData(i) and Profiles._getProfileData(i).progress end
function Profiles.getCurrentRun(i) return Profiles._getProfileData(i) and Profiles._getProfileData(i).currentRun end
function Profiles.getName(i) return Profiles._getProfileData(i) and Profiles._getProfileData(i).name end
function Profiles.hasCurrentRun(i)
  local run = Profiles.getCurrentRun(i)
  return run and run ~= false
end

-- ---------- mutators ----------
function Profiles.setCurrentRun(index, gameState)
  local p = Profiles._getProfileData(index)
  assert(p, "Profile must exist to setCurrentRun")
  -- strip transient values from gameState
  -- local gameStateForSave = deepcopy(gameState)
  -- gameStateForSave.tasks = nil
  -- gameStateForSave.animatingCards = nil
  -- p.currentRun = gameStateForSave
  p.currentRun = gameState
  Profiles.touch(index)
end

function Profiles.clearCurrentRun(index)
  local p = Profiles._getProfileData(index)
  assert(p, "Profile must exist to clearCurrentRun")
  p.currentRun = false
  saveSlot(index)
end

function Profiles.updateSetting(index, key, value)
  local p = Profiles._getProfileData(index)
  assert(p, "Profile must exist to update setting")
  p.settings[key] = value
  saveSlot(index)
end

function Profiles.updateAllSettings(index, settings)
  local p = Profiles._getProfileData(index)
  assert(p, "Profile must exist to update all settings")
  for k, v in pairs(settings) do
    p.settings[k] = v
  end
  saveSlot(index)
end

function Profiles.unlockSystem(index, system)
  local p = Profiles._getProfileData(index)
  assert(p, "Profile must exist to unlock system")
  for _, s in ipairs(p.progress.unlockedSystems) do
    if s == system then return end
  end
  table.insert(p.progress.unlockedSystems, system)
  saveSlot(index)
end

function Profiles.rename(index, newName)
  local p = Profiles._getProfileData(index)
  assert(p, "Profile must exist to rename")
  p.name = newName
  saveSlot(index)
end

return Profiles
