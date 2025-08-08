local Profiles = require("profiles")
local ProfilesUtils = require("profiles.utils")
local Version = require("version")
local EventSystem = require("events.index")

local RunLogger = {}

local runDataPath = "run_data.lua"

local data = {
  currentRun = nil,
  runHistory = {},
}

EventSystem.subscribe("gameOver", function()
  RunLogger.completeRun(love.gameState)
end)

-- called in main.lua for now
function RunLogger.load()
  if love.filesystem.getInfo(runDataPath) then
    local chunk = love.filesystem.load(runDataPath)
    local loaded = chunk()
    if type(loaded) == "table" then
      data = loaded
    end
  end
end

function RunLogger.getRunDataAsString()
  local serialized = "return " .. ProfilesUtils.serialize(data)
  return serialized
end

function RunLogger.save()
  love.filesystem.write(runDataPath, RunLogger.getRunDataAsString())
end

function RunLogger.getCurrentRun()
  return data.currentRun
end

function RunLogger.getRunHistory()
  return data.runHistory
end

function RunLogger.getFileFullPath()
  local sep = package.config:sub(1, 1) -- returns "\" on Windows, "/" on Unix
  return love.filesystem.getSaveDirectory() .. sep .. runDataPath
end

function RunLogger.openFolder()
  if love.system.getOS() == "Web" then
    -- fallback behavior
    print("[RunLogger] Can't open folder on Web. Prompting user to download instead.")
    RunLogger.save()
  else
    local folderPath = love.filesystem.getSaveDirectory()
    local cmd
    if love.system.getOS() == "Windows" then
      cmd = string.format('start "" "%s"', folderPath)
    elseif love.system.getOS() == "OS X" then
      cmd = string.format('open "%s"', folderPath)
    else
      cmd = string.format('xdg-open "%s"', folderPath)
    end
    os.execute(cmd)
  end
end

local function findRunInHistory(seed)
  for i, run in ipairs(data.runHistory) do
    if run.seed == seed then
      return i, run
    end
  end
  return nil, nil
end

function RunLogger.init(profileIndex, seed)
  print("RunLogger.init called with profileIndex: " .. tostring(profileIndex))

  if data.currentRun and data.currentRun.seed == seed then
    print("Seed matches current run, skipping initialization.")
    return
  end

  -- If a run was abandoned (game crashed or user quit), move it to history
  if data.currentRun then
    data.currentRun.outcome = "unknown abandoned"
    local existingIndex, existingRun = findRunInHistory(data.currentRun.seed)
    if existingIndex then
      print("Found existing run with seed " .. data.currentRun.seed .. ", updating it.")
      data.runHistory[existingIndex] = data.currentRun
    else
      print("No existing run found with seed " .. data.currentRun.seed .. ", adding to history.")
      table.insert(data.runHistory, data.currentRun)
    end

    data.currentRun = nil
  end

  -- search for seed in history
  local foundRun = nil
  if seed then
    for _, run in ipairs(data.runHistory) do
      if run.seed == seed then
        print("Found existing run with seed " .. seed .. ", reusing it.")
        foundRun = run
        foundRun.outcome = "resumed"
        break
      end
    end
  end

  if foundRun then
    data.currentRun = foundRun
  else
    local profile = Profiles.load(profileIndex)

    data.currentRun = {
      version = Version.number or "unknown",
      profileName = profile and profile.name or "unknown",
      profileIndex = profileIndex or -1,
      seed = seed,
      timestamp = os.time(),
      outcome = nil,
      turnCount = 0,
      -- ramSpent = 0,
      log = {},
      -- deckUsed = {},
    }
  end

  RunLogger.save()
end

local function isSeedMatch(run, gameState)
  if not run.seed or not gameState.seed then return false end
  return run.seed == gameState.seed
end

function RunLogger.updateCurrent(gameState)
  if not data.currentRun then return end

  if not isSeedMatch(data.currentRun, gameState) then
    print("Current run seed mismatch, moving current to history, resetting current run.")
    data.currentRun.outcome = "seed mismatch"
    table.insert(data.runHistory, data.currentRun)
    data.currentRun = nil
    return
  end

  local run = data.currentRun
  run.turnCount = gameState and gameState.turn and gameState.turn.turnCount or 0
  run.outcome = gameState and gameState.turn and gameState.turn.phase or "unknown"
  run.log = gameState and gameState.log or {}

  RunLogger.save()
end

function RunLogger.completeRun(gameState)
  if not data.currentRun then return end

  print("Completing run with seed: " .. tostring(data.currentRun.seed))

  RunLogger.updateCurrent(gameState)

  -- Push into history and clear current
  data.runHistory = data.runHistory or {}
  local existingIndex, existingRun = findRunInHistory(data.currentRun.seed)
    if existingIndex then
      print("[completeRun]: Found existing run with seed " .. data.currentRun.seed .. ", updating it.")
      data.runHistory[existingIndex] = data.currentRun
    else
      print("[completeRun]: No existing run found with seed " .. data.currentRun.seed .. ", adding to history.")
      table.insert(data.runHistory, data.currentRun)
    end
  data.currentRun = nil
  RunLogger.save()
end

return RunLogger
