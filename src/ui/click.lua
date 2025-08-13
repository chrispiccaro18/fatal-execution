local Click = { list = {} }

-- id:   "endTurn", "card", …
-- rect: {x,y,w,h}
-- payload: any extra info you need later (card index, etc.)
function Click.register(id, rect, payload)
  table.insert(Click.list, { id = id, rect = rect, payload = payload })
end

-- call once per frame
function Click.clear()
  Click.list = {}
end

-- simple AABB
local function inside(r, px, py)
  return px >= r.x and px <= r.x + r.w
      and py >= r.y and py <= r.y + r.h
end

-- iterate top-to-bottom so last drawn (top-most) wins
function Click.hit(px, py)
  for i = #Click.list, 1, -1 do
    local h = Click.list[i]
    if inside(h.rect, px, py) then return h end
  end
end

function Click.addButton(id, rect, label, colors, fontSize)
  local lg = love.graphics

  -- background
  lg.setColor(colors.bg)
  lg.rectangle("fill", rect.x, rect.y, rect.w, rect.h)

  -- border
  lg.setColor(colors.border)
  lg.rectangle("line", rect.x, rect.y, rect.w, rect.h)

  -- label
  lg.setColor(colors.text)
  lg.setFont(lg.newFont(fontSize))
  lg.printf(label, rect.x, rect.y + (rect.h - fontSize) / 2,
            rect.w, "center")

  -- register for hit-test
    Click.register(id, rect)
end

return Click

-- ONLY USE VIRTUAL COORDINATES
-- HOW TO USE
-- function love.mousepressed(sx, sy, button)
--   if button ~= 1 then return end
--   local hit = Click.hitScreen(sx, sy)   -- screen → virtual happens here
--   if hit then
--     -- handle hit.id / hit.payload
--   end
-- end
-- ui/click.lua
-- local Display = require("ui.display")

-- local Click = { list = {} }

-- function Click.register(id, rect, payload)
--   table.insert(Click.list, { id = id, rect = rect, payload = payload })
-- end

-- function Click.clear()
--   Click.list = {}
-- end

-- local function inside(r, px, py)
--   return px >= r.x and px <= r.x + r.w
--      and py >= r.y and py <= r.y + r.h
-- end

-- -- Core hit in VIRTUAL coords (rects are virtual)
-- function Click.hitVirtual(vx, vy)
--   for i = #Click.list, 1, -1 do
--     local h = Click.list[i]
--     if inside(h.rect, vx, vy) then return h end
--   end
--   return nil
-- end

-- -- Convenience: take SCREEN coords and convert once
-- function Click.hitScreen(sx, sy)
--   local vx, vy = Display.toVirtual(sx, sy)
--   return Click.hitVirtual(vx, vy)
-- end

-- -- Optional: keep your draw+register helper (but don't newFont every time)
-- function Click.addButton(id, rect, label, colors, font)
--   local lg = love.graphics

--   lg.setColor(colors.bg);     lg.rectangle("fill",  rect.x, rect.y, rect.w, rect.h)
--   lg.setColor(colors.border); lg.rectangle("line",  rect.x, rect.y, rect.w, rect.h)
--   lg.setColor(colors.text);   lg.setFont(font)
--   lg.printf(label, rect.x, rect.y + (rect.h - font:getHeight()) / 2, rect.w, "center")

--   Click.register(id, rect)
-- end

-- return Click
