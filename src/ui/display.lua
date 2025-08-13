local lg = love.graphics
local Display                        = {}

Display.presets                      = {
  { w = 1280, h = 720 },  -- 720p
  { w = 1920, h = 1080 }, -- 1080p
  { w = 2560, h = 1440 }, -- 1440p
  { w = 3840, h = 2160 }, -- 4-K
}

-- baseline the whole game was designed for
Display.VIRTUAL_W, Display.VIRTUAL_H = 1280, 720
Display.canvas                       = lg.newCanvas(Display.VIRTUAL_W, Display.VIRTUAL_H)
Display.scale                        = 1
Display.offsetX                      = 0
Display.offsetY                      = 0

function Display.getVirtualSize()
  return Display.VIRTUAL_W, Display.VIRTUAL_H
end

-- Only this module touches real window/screen size
function Display._getWindowSize()
  local w, h = lg.getDimensions()
  return w, h
end

function Display.refresh()
  local ww, wh = Display._getWindowSize()
  local s = math.min(ww / Display.VIRTUAL_W, wh / Display.VIRTUAL_H)
  -- allow fractional scale; clamp to >= 1 if you prefer:
  -- s = math.max(s, 1)
  Display.scale = s
  Display.offsetX = math.floor((ww - Display.VIRTUAL_W * s) / 2)
  Display.offsetY = math.floor((wh - Display.VIRTUAL_H * s) / 2)
end


-- function Display.apply(index, fullscreen)
--   local mode = Display.presets[index]
--   assert(mode, "invalid display preset index")
--   local ok = love.window.setMode(mode.w, mode.h, {
--     fullscreen = fullscreen or false,
--     resizable  = true,  -- allow resizing so refresh() is useful
--     vsync      = true,
--   })
--   assert(ok, "could not switch resolution")
--   Display.refresh()
-- end

function Display.apply(index, fullscreen)
  local mode = Display.presets[index]
  local okay = love.window.setMode(
    mode.w, mode.h,
    {
      fullscreen = fullscreen or false,
      resizable  = false,
      vsync      = true,
    })
  assert(okay, "could not switch resolution")

  -- integer scale ≤ chosen mode
  -- Display.scale = math.floor(
  --   math.min(mode.w / Display.VIRTUAL_W,
  --            mode.h / Display.VIRTUAL_H))

  -- allow fractional scale
  Display.scale = math.min(mode.w / Display.VIRTUAL_W,
                           mode.h / Display.VIRTUAL_H)
  Display.scale = math.max(Display.scale, 1)

  Display.offsetX = math.floor((mode.w - Display.VIRTUAL_W * Display.scale) / 2)
  Display.offsetY = math.floor((mode.h - Display.VIRTUAL_H * Display.scale) / 2)
end

function Display.toVirtual(px, py)
  local vx = (px - Display.offsetX) / Display.scale
  local vy = (py - Display.offsetY) / Display.scale
  return vx, vy
end

return Display
