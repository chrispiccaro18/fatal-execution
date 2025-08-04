local Animation = {}

Animation.active = {}

function Animation.update(dt)
  for i = #Animation.active, 1, -1 do
    local anim = Animation.active[i]
    anim.time = anim.time + dt

    -- Handle delay
    if anim.time < anim.delay then
      -- Skip updating if still in delay period
      goto continue
    end

    -- Adjust time to account for delay
    local elapsed = anim.time - anim.delay
    local t = math.min(elapsed / anim.duration, 1)
    anim.onUpdate(t)

    if t >= 1 then
      if anim.onComplete then anim.onComplete() end
      table.remove(Animation.active, i)
    end
    ::continue::
  end
end

function Animation.add(params)
  params.time = 0
  params.delay = params.delay or 0
  table.insert(Animation.active, params)
end

function Animation.draw()
  for _, anim in ipairs(Animation.active) do
    if anim.onDraw then anim.onDraw() end
  end
end

return Animation
