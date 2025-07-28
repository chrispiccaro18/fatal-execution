local Display                        = {}

Display.presets                      = {
  { w = 1280, h = 720 },  -- 720p
  { w = 1920, h = 1080 }, -- 1080p
  { w = 2560, h = 1440 }, -- 1440p
  { w = 3840, h = 2160 }, -- 4-K
}

-- baseline the whole game was designed for
Display.VIRTUAL_W, Display.VIRTUAL_H = 1280, 720
Display.canvas                       = love.graphics.newCanvas(Display.VIRTUAL_W, Display.VIRTUAL_H)
Display.scale                        = 1
Display.offsetX, Display.offsetY     = 0, 0

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
