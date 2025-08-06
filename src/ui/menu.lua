local Display = require("ui.display")
local Click = require("ui.click")
local Profiles = require("profiles.index")
local ActiveProfile = require("profiles.active")
local OptionsMenu = require("ui.options_menu")

local Menu = {
  isOpen   = false,
  sel      = 1,
  wantFull = false,
}

local activeProfileIndex = ActiveProfile.get()

local function applyDisplay()
  Display.apply(Menu.sel, Menu.wantFull)
end

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
    { id = "continue", label = "Continue" },
    { id = "options",  label = "Options" },
    { id = "mainmenu", label = "Main Menu" },
    { id = "savequit", label = "Save and Quit" },
    { id = "abandon",  label = "Abandon Run" },
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

  local hit = Click.hit(x, y)
  if not hit then return end

  if hit.id == "continue" then
    Menu.toggle()
  elseif hit.id == "options" then
    OptionsMenu.open()
  elseif hit.id == "mainmenu" then
    Profiles.setCurrentRun(activeProfileIndex, love.gameState)
    Menu.toggle()
    CurrentScreen = "start"
  elseif hit.id == "savequit" then
    Profiles.setCurrentRun(activeProfileIndex, love.gameState)
    love.event.quit()
  elseif hit.id == "abandon" then
    CurrentScreen = "start"
    Menu.toggle()
    Profiles.clearCurrentRun(activeProfileIndex)
  end
end

return Menu


-- local Display = require("ui.display")
-- local Profiles = require("profiles.index")
-- local ActiveProfile = require("profiles.active")

-- local Menu = {
--   isOpen   = false,
--   sel      = 1,  -- index into Display.presets
--   wantFull = false,
-- }

-- local activeProfileIndex = ActiveProfile.get()


-- local function apply()               -- (re)apply current choice
--   Display.apply(Menu.sel, Menu.wantFull)
-- end

-- function Menu.toggle()
--   Menu.isOpen = not Menu.isOpen
--   -- In a bigger game this is where you’d also pause SFX, timers, etc.
-- end

-- function Menu.keypressed(key)
--   if not Menu.isOpen then return false end  -- let game handle it

--   if key == "escape" then
--     Profiles.setCurrentRun(activeProfileIndex, love.gameState)
--     love.event.quit()

--   elseif key == "q" then
--     Profiles.setCurrentRun(activeProfileIndex, love.gameState)
--     Menu.toggle()
--     CurrentScreen = "start"
--   elseif key == "m" then
--     Menu.toggle()

--   elseif key == "right" or key == "d" then
--     Menu.sel = (Menu.sel % #Display.presets) + 1
--     apply()

--   elseif key == "left" or key == "a" then
--     Menu.sel = ((Menu.sel - 2 + #Display.presets) % #Display.presets) + 1
--     apply()

--   elseif key == "f" then
--     Menu.wantFull = not Menu.wantFull
--     apply()
--   end

--   return true   -- menu consumed the key
-- end

-- function Menu.draw()
--   if not Menu.isOpen then return end

--   local lg = love.graphics
--   lg.push()
--   -- draw a semi-transparent blackout behind the menu
--   lg.setColor(0, 0, 0, 0.6)
--   lg.rectangle("fill", 0, 0, love.graphics.getDimensions())

--   -- white text in the centre
--   lg.setColor(1, 1, 1)
--   lg.setFont(lg.newFont(22))

--   local mode = Display.presets[Menu.sel]
--   local msg  = string.format(
--       "Options  (<- ->) to change res, F to toggle fullscreen)\n\n"
--     .. "Resolution : %dx%d\n"
--     .. "Fullscreen : %s\n\n"
--     .. "Press M to Resume\n"
--     .. "Press Q to Save and Go to Start Screen\n"
--     .. "Press Esc to Save and Quit Game",
--     mode.w, mode.h,
--     Menu.wantFull and "on" or "off")

--   local winW, winH = love.graphics.getDimensions()
--   local textH = lg.getFont():getWrap(msg, winW*0.8)
--   lg.printf(msg, winW*0.1, winH*0.5 - textH/2, winW*0.8, "center")

--   lg.pop()
-- end

-- return Menu
