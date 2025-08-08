local ProfilesUtils = require("profiles.utils")
local Version = require("version")
local defaultProfile = require("data.default_profile")

local Profiles = {}

local MAX_PROFILES = 3
local savePrefix = "profile_"
local cachedProfiles = {}

local function deepCopy(tbl)
  if type(tbl) ~= "table" then return tbl end
  local copy = {}
  for k, v in pairs(tbl) do
    copy[deepCopy(k)] = deepCopy(v)
  end
  return copy
end

local function getFilename(index)
  return savePrefix .. tostring(index) .. ".lua"
end

--- Private: Access profile data safely (via cache)
function Profiles._getProfileData(index)
  assert(index >= 1 and index <= MAX_PROFILES, "Invalid profile index")
  if not cachedProfiles[index] then
    Profiles.load(index)
  end
  return cachedProfiles[index]
end

function Profiles.load(index)
  print(string.format("[Profiles.load] Loading profile %d", index))
  assert(index >= 1 and index <= MAX_PROFILES, "Invalid profile index")
  if cachedProfiles[index] then return cachedProfiles[index] end

  print("[Profiles.load] Profile not found in cache.", index)

  local filename = getFilename(index)
  if not love.filesystem.getInfo(filename) then
    cachedProfiles[index] = nil
    return nil
  end

  local ok, chunk = pcall(love.filesystem.load, filename)
  if not ok or not chunk then
    cachedProfiles[index] = nil
    return nil
  end

  local ok2, data = pcall(chunk)
  if not ok2 or type(data) ~= "table" then
    cachedProfiles[index] = nil
    return nil
  end

  cachedProfiles[index] = data
  return data
end

function Profiles.save(index)
  local data = cachedProfiles[index]
  if not data then return end
  local encoded = "return " .. ProfilesUtils.serialize(data)
  love.filesystem.write(getFilename(index), encoded)
end

function Profiles._markDirtyAndSave(index)
  Profiles.save(index)
end

-- Creation & Deletion
function Profiles.create(index)
  assert(index >= 1 and index <= MAX_PROFILES, "Invalid profile index")
  if Profiles.profileExists(index) then return false end

  local newProfile = deepCopy(defaultProfile)
  newProfile.name = "Profile " .. index
  newProfile.gameVersion = Version.number

  cachedProfiles[index] = newProfile
  Profiles._markDirtyAndSave(index)
  return true
end

function Profiles.delete(index)
  love.filesystem.remove(getFilename(index))
  cachedProfiles[index] = nil
end

-- Metadata
function Profiles.profileExists(index)
  return love.filesystem.getInfo(getFilename(index)) ~= nil
end

function Profiles.getMaxProfiles()
  return MAX_PROFILES
end

function Profiles.getCachedProfiles()
  for i = 1, MAX_PROFILES do
    Profiles._getProfileData(i)
  end
  return cachedProfiles
end

-- Accessors
function Profiles.getSettings(index)
  return Profiles._getProfileData(index).settings
end

function Profiles.getProgress(index)
  return Profiles._getProfileData(index).progress
end

function Profiles.getCurrentRun(index)
  return Profiles._getProfileData(index).currentRun
end

function Profiles.getName(index)
  return Profiles._getProfileData(index).name
end

-- Mutators
function Profiles.setCurrentRun(index, gameState)
  Profiles._getProfileData(index).currentRun = gameState
  Profiles._markDirtyAndSave(index)
end

function Profiles.clearCurrentRun(index)
  love.gameState = nil
  Profiles._getProfileData(index).currentRun = false
  Profiles._markDirtyAndSave(index)
end

function Profiles.updateSetting(index, key, value)
  Profiles._getProfileData(index).settings[key] = value
  Profiles._markDirtyAndSave(index)
end

function Profiles.unlockSystem(index, system)
  local unlocked = Profiles._getProfileData(index).progress.unlockedSystems
  for _, s in ipairs(unlocked) do
    if s == system then return end
  end
  table.insert(unlocked, system)
  Profiles._markDirtyAndSave(index)
end

function Profiles.rename(index, newName)
  Profiles._getProfileData(index).name = newName
  Profiles._markDirtyAndSave(index)
end

return Profiles

-- local function isValidCurrentRun(run)
--   if type(run) ~= "table" then return false end
--   local expected = require("data.default_game_state").init("random_seed")

--   for k in pairs(run) do
--     if expected[k] == nil then return false end
--   end

--   for k, v in pairs(expected) do
--     if run[k] == nil or type(run[k]) ~= type(v) then
--       return false
--     end
--   end

--   return true
-- end


-- local function validateAndMigrate(data, expected, isRoot)
--   expected = expected or defaultProfile
--   isRoot = isRoot ~= false

--   local RECURSIVE_KEYS = {
--     settings = true,
--     progress = true,
--   }

--   local wasModified = false

--   if data.currentRun ~= nil and not isValidCurrentRun(data.currentRun) then
--     print("[validateAndMigrate] currentRun is invalid → setting to nil")
--     data.currentRun = nil
--     wasModified = true
--   end

--   for k, v in pairs(expected) do
--     if k ~= "currentRun" then
--       if data[k] == nil then
--         print(string.format("[validateAndMigrate] Missing field %s → adding default", k))
--         data[k] = deepCopy(v)
--         wasModified = true
--       elseif type(v) == "table" then
--         if type(data[k]) ~= "table" then
--           print(string.format("[validateAndMigrate] Field %s expected table, got %s → replacing with default", k,
--                               type(data[k])))
--           data[k] = deepCopy(v)
--           wasModified = true
--         else
--           -- Only recurse into *expected* nested structures
--           if RECURSIVE_KEYS[k] then
--             if validateAndMigrate(data[k], v, false) then
--               wasModified = true
--             end
--           end
--         end
--       elseif type(data[k]) == "table" then
--         print(string.format("[validateAndMigrate] Field %s expected non-table, got table → replacing with default", k))
--         data[k] = deepCopy(v)
--         wasModified = true
--       end
--     end

--     if isRoot and data.gameVersion ~= Version.number then
--       print(string.format("[validateAndMigrate] Updating gameVersion from %s to %s", tostring(data.gameVersion),
--                           tostring(Version.number)))
--       data.gameVersion = Version.number
--       wasModified = true
--     end

--     return wasModified
--   end
-- end
