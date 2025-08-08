local Const = require("const")
local Display = require("ui.display")
local Click = require("ui.click")
local Profiles = require("profiles")
local ActiveProfile = require("profiles.active")
local OptionsMenu = require("ui.options_menu")

local Menu = {
  isOpen   = false,
  sel      = 1,
  wantFull = false,
}

local hitIds = Const.HIT_IDS.IN_GAME_MENU
local buttonLabels = Const.BUTTON_LABELS.IN_GAME_MENU

function Menu.toggle()
  Menu.isOpen = not Menu.isOpen
end

function Menu.keypressed(key)
  if not Menu.isOpen then return false end

  if key == "escape" or key == "m" then
    Menu.toggle()
    return true
  elseif key == "o" then
    OptionsMenu.open()
    return true
  end

  return true
end

function Menu.draw()
  if not Menu.isOpen then return end

  local lg = love.graphics
  local W, H = lg.getWidth(), lg.getHeight()
  lg.push()
  lg.setColor(0, 0, 0, 0.6)
  lg.rectangle("fill", 0, 0, W, H)

  Click.clear()

  local buttonW, buttonH = 300, 40
  local startX = (W - buttonW) / 2
  local startY = 120
  local spacing = 50
  local colors = {
    bg = { 0.2, 0.2, 0.2 },
    border = { 1, 1, 1 },
    text = { 1, 1, 1 }
  }

  local buttons = {
    { id = hitIds.CONTINUE, label = buttonLabels.CONTINUE },
    { id = hitIds.OPTIONS,  label = buttonLabels.OPTIONS },
    { id = hitIds.MAIN_MENU, label = buttonLabels.MAIN_MENU },
    { id = hitIds.SAVE_QUIT, label = buttonLabels.SAVE_QUIT },
    { id = hitIds.ABANDON,  label = buttonLabels.ABANDON },
  }

  for i, b in ipairs(buttons) do
    Click.addButton(
      b.id,
      { x = startX, y = startY + (i - 1) * spacing, w = buttonW, h = buttonH },
      b.label,
      colors,
      20
    )
  end

  lg.pop()
end

function Menu.mousepressed(x, y, button)
  if not Menu.isOpen or button ~= 1 then return end

  local activeProfileIndex = ActiveProfile.get()

  local hit = Click.hit(x, y)
  if not hit then return end

  if hit.id == hitIds.CONTINUE then
    Menu.toggle()
  elseif hit.id == hitIds.OPTIONS then
    OptionsMenu.open(activeProfileIndex)
  elseif hit.id == hitIds.MAIN_MENU then
    Profiles.setCurrentRun(activeProfileIndex, love.gameState)
    Menu.toggle()
    CurrentScreen = Const.CURRENT_SCREEN.START
  elseif hit.id == hitIds.SAVE_QUIT then
    Profiles.setCurrentRun(activeProfileIndex, love.gameState)
    love.event.quit()
  elseif hit.id == hitIds.ABANDON then
    CurrentScreen = Const.CURRENT_SCREEN.START
    Menu.toggle()
    Profiles.clearCurrentRun(activeProfileIndex)
  end
end

return Menu
