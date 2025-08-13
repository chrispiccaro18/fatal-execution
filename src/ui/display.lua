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

-- tailored for preset-only switching
-- ui/display.lua
-- local lg = love.graphics
-- local Display = {}

-- -- Fixed logical size your game is authored for
-- Display.VIRTUAL_W, Display.VIRTUAL_H = 1280, 720

-- -- Preset physical window sizes users can choose from
-- Display.presets = {
--   { w = 1280, h = 720  },  -- 720p
--   { w = 1920, h = 1080 },  -- 1080p
--   { w = 2560, h = 1440 },  -- 1440p
--   { w = 3840, h = 2160 },  -- 4K
-- }

-- -- State
-- Display.canvas    = lg.newCanvas(Display.VIRTUAL_W, Display.VIRTUAL_H)
-- Display.scale     = 1
-- Display.offsetX   = 0
-- Display.offsetY   = 0
-- Display.fullscreen= false
-- Display.index     = 1       -- current preset index

-- -- Internal: compute scale/offset for given physical size
-- local function _computeMapping(physW, physH)
--   -- require physical window >= virtual, so we never downscale
--   assert(physW >= Display.VIRTUAL_W and physH >= Display.VIRTUAL_H,
--     string.format("Preset too small for virtual size (%dx%d < %dx%d)",
--       physW, physH, Display.VIRTUAL_W, Display.VIRTUAL_H))

--   local s = math.min(physW / Display.VIRTUAL_W, physH / Display.VIRTUAL_H)
--   -- If you want pixel-perfect crispness, uncomment to force integer scale:
--   -- s = math.floor(s)

--   local offX = math.floor((physW - Display.VIRTUAL_W * s) / 2)
--   local offY = math.floor((physH - Display.VIRTUAL_H * s) / 2)
--   return s, offX, offY
-- end

-- -- Public: apply a preset + fullscreen flag
-- function Display.apply(index, fullscreen)
--   local mode = Display.presets[index]
--   assert(mode, "invalid display preset index")

--   Display.fullscreen = not not fullscreen
--   Display.index      = index

--   local ok = love.window.setMode(mode.w, mode.h, {
--     fullscreen = Display.fullscreen,
--     resizable  = false,   -- <— lock user resize
--     vsync      = true,
--     highdpi    = true,    -- optional, nice on Retina/HiDPI
--     msaa       = 0,       -- set if you need MSAA
--   })
--   assert(ok, "could not switch resolution")

--   -- Recompute mapping for this preset
--   Display.scale, Display.offsetX, Display.offsetY = _computeMapping(mode.w, mode.h)
-- end

-- -- Helpers (nice for menus/settings)
-- function Display.getVirtualSize()  return Display.VIRTUAL_W, Display.VIRTUAL_H end
-- function Display.getPresetIndex()  return Display.index end
-- function Display.getPreset()       return Display.presets[Display.index] end
-- function Display.isFullscreen()    return Display.fullscreen end

-- -- Convert screen mouse → virtual coords
-- function Display.toVirtual(px, py)
--   local vx = (px - Display.offsetX) / Display.scale
--   local vy = (py - Display.offsetY) / Display.scale
--   return vx, vy
-- end

-- return Display

