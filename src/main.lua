local Const = require("const")
local StartScreen = require("ui.start_screen")
local GameLoop = require("game_loop")
local RunLogger = require("profiles.run_logger")
local OptionsMenu = require("ui.options_menu")

package.path = package.path
    .. ";src/?.lua"
    .. ";src/?/init.lua"
    .. ";src/?/?.lua"

_G.CurrentScreen = Const.CURRENT_SCREEN.START

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  math.randomseed(os.time())
  RunLogger.load()
  StartScreen.load()
end

function love.update(dt)
  if CurrentScreen == Const.CURRENT_SCREEN.START then
    -- start screen doesn't need update yet
  elseif CurrentScreen == Const.CURRENT_SCREEN.GAME then
    GameLoop.update(dt)
  end
end

function love.draw()
  if CurrentScreen == Const.CURRENT_SCREEN.START then
    StartScreen.draw()
  elseif CurrentScreen == Const.CURRENT_SCREEN.GAME then
    GameLoop.draw()
  end

  OptionsMenu.draw()
end

function love.mousepressed(x, y, button)
  if OptionsMenu.isOpen then
    OptionsMenu.mousepressed(x, y, button)
    return
  end

  if CurrentScreen == Const.CURRENT_SCREEN.START then
    StartScreen.mousepressed(x, y, button)
  elseif CurrentScreen == Const.CURRENT_SCREEN.GAME then
    GameLoop.mousepressed(x, y, button)
  end
end

function love.keypressed(key)
  if CurrentScreen == Const.CURRENT_SCREEN.START then
    StartScreen.keypressed(key)
  elseif CurrentScreen == Const.CURRENT_SCREEN.GAME then
    GameLoop.keypressed(key)
  end
end

function love.textinput(text)
  if CurrentScreen == Const.CURRENT_SCREEN.START then
    StartScreen.textinput(text)
  end
end
