-- ui/debug_overlay.lua
local lg = love.graphics
local DebugOverlay = { enabled = false }

function DebugOverlay.toggle()
  DebugOverlay.enabled = not DebugOverlay.enabled
end

-- Draws:
-- 1) a frame around the virtual canvas
-- 2) a coarse grid in virtual space
-- 3) a screen-space frame showing where the canvas lands on the window
function DebugOverlay.draw(Display)
  if not DebugOverlay.enabled then return end

  -- draw on the canvas (virtual coords)
  lg.push("all")
  lg.setCanvas(Display.canvas)
  -- Virtual border
  lg.setColor(1, 0, 0, 1)
  lg.rectangle("line", 0, 0, Display.VIRTUAL_W, Display.VIRTUAL_H)

  -- Virtual grid every 80 px
  lg.setColor(1, 1, 1, 0.15)
  local step = 80
  for x = step, Display.VIRTUAL_W - step, step do
    lg.line(x, 0, x, Display.VIRTUAL_H)
  end
  for y = step, Display.VIRTUAL_H - step, step do
    lg.line(0, y, Display.VIRTUAL_W, y)
  end

  -- Axes labels (cheap)
  lg.setColor(1, 1, 1, 0.7)
  lg.print("VIRTUAL", 6, 6)

  lg.setCanvas()
  lg.pop()

  -- screen-space frame showing where virtual canvas is drawn
  lg.push("all")
  lg.translate(Display.offsetX, Display.offsetY)
  lg.scale(Display.scale, Display.scale)
  lg.setColor(0, 1, 0, 0.8)
  lg.rectangle("line", 0, 0, Display.VIRTUAL_W, Display.VIRTUAL_H)
  lg.pop()

  -- screen-space info text
  local ww, wh = lg.getDimensions()
  lg.setColor(1,1,1,0.9)
  lg.print(
    string.format(
      "DEBUG OVERLAY\nwin: %dx%d  virtual: %dx%d\nscale: %.3f  offset: (%d, %d)",
      ww, wh, Display.VIRTUAL_W, Display.VIRTUAL_H, Display.scale, Display.offsetX, Display.offsetY
    ),
    10, 10
  )
end

return DebugOverlay
