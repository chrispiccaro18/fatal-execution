local Click = { list = {} }

-- id:   "endTurn", "card", …
-- rect: {x,y,w,h}
-- payload: any extra info you need later (card index, etc.)
function Click.register(id, rect, payload)
  table.insert(Click.list, {id=id, rect=rect, payload=payload})
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
