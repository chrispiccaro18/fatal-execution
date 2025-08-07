-- local defaultData = require("data")
local ProfilesUtils = require("profiles.utils")
local Version = require("version")

local Profiles = {}

local MAX_PROFILES = 3
local savePrefix = "profile_"
local cachedProfiles = {}

-- Default profile structure
local defaultProfile = require("data.default_profile")
-- local defaultProfile = defaultData.defaultProfile

-- deep copy utility
local function deepCopy(tbl)
  if type(tbl) ~= "table" then return tbl end
  local copy = {}
  for k, v in pairs(tbl) do
    copy[deepCopy(k)] = deepCopy(v)
  end
  return copy
end

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

-- Serialize Lua table into a string
-- local function serialize(tbl, indent)
--   indent = indent or 0
--   local buffer = {}
--   local prefix = string.rep("  ", indent)
--   table.insert(buffer, "{\n")
--   for k, v in pairs(tbl) do
--     local key = type(k) == "string" and string.format("[%q]", k) or "[" .. k .. "]"
--     local value
--     if type(v) == "table" then
--       value = serialize(v, indent + 1)
--     elseif type(v) == "string" then
--       value = string.format("%q", v)
--     else
--       value = tostring(v)
--     end
--     table.insert(buffer, string.format("%s  %s = %s,\n", prefix, key, value))
--   end
--   table.insert(buffer, prefix .. "}")
--   return table.concat(buffer)
-- end

-- Save file per profile
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

-- Load profile from file or default
function Profiles.load(index)
  print(string.format("[Profiles.load] Loading profile %d", index))
  assert(index >= 1 and index <= MAX_PROFILES, "Invalid profile index")
  if cachedProfiles[index] then return cachedProfiles[index] end

  local filename = getFilename(index)
  print("Save directory: " .. love.filesystem.getSaveDirectory())
  print(string.format("[Profiles.load] Loading profile %d from %s", index, filename))
  local ok, chunk = pcall(love.filesystem.load, filename)

  if not ok or not chunk then
    cachedProfiles[index] = deepCopy(defaultProfile)
    return cachedProfiles[index]
  end

  local ok2, data = pcall(chunk)
  if not ok2 or type(data) ~= "table" then
    cachedProfiles[index] = deepCopy(defaultProfile)
    return cachedProfiles[index]
  end

  -- local wasModified = validateAndMigrate(data)
  cachedProfiles[index] = data
  -- if wasModified then
  --   print("Profile data changed — saving updated profile.")
  --   Profiles.save(index)
  -- end

  return data
end

-- Save profile to file
function Profiles.save(index)
  assert(index >= 1 and index <= MAX_PROFILES, "Invalid profile index")
  local data = cachedProfiles[index]
  if not data then return end
  local encoded = "return " .. ProfilesUtils.serialize(data)
  love.filesystem.write(getFilename(index), encoded)
end

function Profiles.create(index)
  assert(index >= 1 and index <= MAX_PROFILES, "Invalid profile index")
  if Profiles.profileExists(index) then
    print(string.format("[Profiles.create] Profile %d already exists", index))
    return false
  end

  local newProfile = defaultProfile
  newProfile.name = "Profile " .. index
  newProfile.gameVersion = Version.number
  cachedProfiles[index] = newProfile
  Profiles.save(index)
  print(string.format("[Profiles.create] Created new profile %d", index))
  return true
end

-- Delete profile
function Profiles.delete(index)
  assert(index >= 1 and index <= MAX_PROFILES, "Invalid profile index")
  love.filesystem.remove(getFilename(index))
  cachedProfiles[index] = nil
end

-- Check for existing save file
function Profiles.profileExists(index)
  return love.filesystem.getInfo(getFilename(index)) ~= nil
end

-- Access specific sections
function Profiles.getSettings(index) return Profiles.load(index).settings end

function Profiles.getProgress(index) return Profiles.load(index).progress end

function Profiles.getCurrentRun(index) return Profiles.load(index).currentRun end

function Profiles.getName(index) return Profiles.load(index).name end

-- Mutators
function Profiles.setCurrentRun(index, gameState)
  Profiles.load(index).currentRun = gameState
  Profiles.save(index)
end

function Profiles.clearCurrentRun(index)
  love.gameState = nil
  Profiles.load(index).currentRun = false
  Profiles.save(index)
end

function Profiles.updateSetting(index, key, value)
  Profiles.load(index).settings[key] = value
  Profiles.save(index)
end

function Profiles.unlockSystem(index, system)
  local progress = Profiles.load(index).progress
  for _, s in ipairs(progress.unlockedSystems) do
    if s == system then return end
  end
  table.insert(progress.unlockedSystems, system)
  Profiles.save(index)
end

function Profiles.rename(index, newName)
  Profiles.load(index).name = newName
  Profiles.save(index)
end

function Profiles.getCachedProfiles()
  -- Ensure all profiles are loaded into the cache
  for i = 1, MAX_PROFILES do
    if not cachedProfiles[i] then
      Profiles.load(i)
    end
  end
  return cachedProfiles
end

function Profiles.getMaxProfiles()
  return MAX_PROFILES
end

return Profiles
