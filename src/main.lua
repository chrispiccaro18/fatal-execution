local Const          = require("const")
local StartScreen    = require("ui.menus.start_screen")
local GameLoop       = require("game_loop")
-- local RunLogger      = require("profiles.run_logger")
local Display        = require("ui.display")
local DebugOverlay   = require("ui.debug_overlay")
local OptionsMenu    = require("ui.menus.options_menu")
local Profiles       = require("profiles")
local Store          = require("store")
local ConfirmDialog  = require("ui.menus.confirm_dialog")

local lg = love.graphics

package.path         = package.path
    .. ";src/?.lua"
    .. ";src/?/init.lua"
    .. ";src/?/?.lua"

local CURRENT_SCREEN = Const.CURRENT_SCREEN
_G.CurrentScreen     = CURRENT_SCREEN.START

function love.load()
  print("Lua Version: " .. _VERSION)
  print("LOVE Version: " .. love.getVersion())

  love.graphics.setDefaultFilter("nearest", "nearest")

  -- NOTE: You'll eventually stop using math.random and seed your own RNG streams.
  -- math.randomseed(os.time())

  local profileSummaries = Profiles.init()
  print("Loaded profiles:", #profileSummaries)
  print("Available profiles:")
  for i, summary in ipairs(profileSummaries) do
    print(string.format("  %d: %s", i, summary.exists and "Exists" or "Empty"))
  end
  -- RunLogger.load()
  StartScreen.load()

  -- If you ever want to auto-resume a run at boot:
  -- local idx = ... -- active profile index, if you track it here
  -- local run = Profiles.getCurrentRun(idx)
  -- if run then Store.bootstrap(run) end
end

function love.update(dt)
  if CurrentScreen == CURRENT_SCREEN.START then
    -- start screen doesn't need update yet
  elseif CurrentScreen == CURRENT_SCREEN.GAME then
    -- Drive game systems & UI as before
    GameLoop.update(dt)
    -- Drive the Store task runner & UI transition engine (NEW)
    Store.update(dt)
  end

  -- debounce profile saves
  -- If you have settings that must be persisted immediately (e.g., rebinding keys),
  -- call Profiles.flush(i) right after the change.
  Profiles.update(dt)
end

function love.draw()
  lg.push()
  lg.translate(Display.offsetX, Display.offsetY)
  lg.scale(Display.scale, Display.scale)
  lg.setColor(1,1,1,1)
  lg.draw(Display.canvas, 0, 0)
  lg.pop()

  if CurrentScreen == CURRENT_SCREEN.START then
    StartScreen.draw()
  elseif CurrentScreen == CURRENT_SCREEN.GAME then
    GameLoop.draw()
  end

  OptionsMenu.draw()
  ConfirmDialog.draw()

  DebugOverlay.draw(Display)
end

local function inputLocked()
  -- Central gate (NEW). Store.view is ephemeral/UI state.
  return Store.view and Store.view.inputLocked
end

function love.mousepressed(x, y, button)
  if OptionsMenu.isOpen then
    OptionsMenu.mousepressed(x, y, button)
    return
  elseif ConfirmDialog.isOpen then
    ConfirmDialog.mousepressed(x, y, button)
    return
  end

  if inputLocked() then
    -- swallow clicks while animations/tasks are mid-step
    return
  end

  if CurrentScreen == CURRENT_SCREEN.START then
    StartScreen.mousepressed(x, y, button)
  elseif CurrentScreen == CURRENT_SCREEN.GAME then
    GameLoop.mousepressed(x, y, button)
  end
end

function love.mousemoved(x, y)
  if CurrentScreen == CURRENT_SCREEN.GAME then
    GameLoop.mousemoved(x, y)
  end
end

function love.keypressed(key)
  if ConfirmDialog.isOpen then
    if ConfirmDialog.keypressed(key) then return end
  end

  if CurrentScreen == CURRENT_SCREEN.START then
    StartScreen.keypressed(key)
  elseif CurrentScreen == CURRENT_SCREEN.GAME then
    -- Optional: allow some keys while locked (e.g., pause menu).
    if not inputLocked() or key == "escape" or key == "m" then
      GameLoop.keypressed(key)
    end
  end

  if key == "f3" then
    DebugOverlay.toggle()
  end
end

function love.textinput(text)
  if CurrentScreen == CURRENT_SCREEN.START then
    StartScreen.textinput(text)
  end
end

function love.quit()
  Profiles.flushAll()
end
