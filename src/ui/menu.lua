local Display = require("ui.display")

local Menu = {
  isOpen   = false,
  sel      = 1,  -- index into Display.presets
  wantFull = false,
}

local function apply()               -- (re)apply current choice
  Display.apply(Menu.sel, Menu.wantFull)
end

function Menu.toggle()
  Menu.isOpen = not Menu.isOpen
  -- In a bigger game this is where you’d also pause SFX, timers, etc.
end

function Menu.keypressed(key)
  if not Menu.isOpen then return false end  -- let game handle it

  if key == "escape" then
    Menu.toggle()

  elseif key == "right" or key == "d" then
    Menu.sel = (Menu.sel % #Display.presets) + 1
    apply()

  elseif key == "left" or key == "a" then
    Menu.sel = ((Menu.sel - 2 + #Display.presets) % #Display.presets) + 1
    apply()

  elseif key == "f" then
    Menu.wantFull = not Menu.wantFull
    apply()
  end

  return true   -- menu consumed the key
end

function Menu.draw()
  if not Menu.isOpen then return end

  local lg = love.graphics
  lg.push()
  -- draw a semi-transparent blackout behind the menu
  lg.setColor(0, 0, 0, 0.6)
  lg.rectangle("fill", 0, 0, love.graphics.getDimensions())

  -- white text in the centre
  lg.setColor(1, 1, 1)
  lg.setFont(lg.newFont(22))

  local mode = Display.presets[Menu.sel]
  local msg  = string.format(
      "Options  (<- ->) to change res, F to toggle fullscreen)\n\n"
    .. "Resolution : %dx%d\n"
    .. "Fullscreen : %s\n\n"
    .. "Press Esc to resume",
    mode.w, mode.h,
    Menu.wantFull and "on" or "off")

  local winW, winH = love.graphics.getDimensions()
  local textH = lg.getFont():getWrap(msg, winW*0.8)
  lg.printf(msg, winW*0.1, winH*0.5 - textH/2, winW*0.8, "center")

  lg.pop()
end

return Menu