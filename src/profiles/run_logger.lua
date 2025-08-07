local Profiles = require("profiles")
local ProfilesUtils = require("profiles.utils")
local Version = require("version")

local RunLogger = {}

local runDataPath = "run_data.lua"

local data = {
  currentRun = nil,
  runHistory = {},
}

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

function RunLogger.init(profileIndex, seed)
  print("RunLogger.init called with profileIndex: " .. tostring(profileIndex))
  -- If a run was abandoned (game crashed or user quit), move it to history
  if data.currentRun then
    data.currentRun.outcome = "unknown abandoned"
    table.insert(data.runHistory, data.currentRun)
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
      ramSpent = 0,
      log = {},
      deckUsed = {},
    }
  end

  RunLogger.save()
end

function RunLogger.completeRun(outcome, gameState)
  if not data.currentRun then return end

  local run = data.currentRun
  run.outcome = outcome or "unknown"

  if gameState and gameState.systems and gameState.currentSystemIndex then
    local sys = gameState.systems[gameState.currentSystemIndex]
    if sys and sys.name then
      run.finalSystem = sys.name
    end
  end

  -- Deck summary (cardName -> total times used)
  run.deckUsed = RunLogger.summarizeDeck(run)

  -- Push into history and clear current
  data.runHistory = data.runHistory or {}
  table.insert(data.runHistory, run)
  data.currentRun = nil
  RunLogger.save()
end

function RunLogger.summarizeDeck(run)
  local usage = {}
  for _, entry in ipairs(run.log or {}) do
    if entry.cardName then
      usage[entry.cardName] = (usage[entry.cardName] or 0) + 1
    end
  end
  return usage
end

return RunLogger
