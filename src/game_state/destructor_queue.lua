local DestructorQueue = {}

function DestructorQueue.init()
  return {}
end

function DestructorQueue.enqueue(queue, effect)
  local newQueue = {}
  for i, item in ipairs(queue) do newQueue[i] = item end
  table.insert(newQueue, effect)
  return newQueue
end

function DestructorQueue.dequeue(queue)
  local newQueue = {}
  for i = 2, #queue do
    table.insert(newQueue, queue[i])
  end
  return queue[1], newQueue
end

local function shuffle(t)
  local n = #t
  for i = n, 2, -1 do
    local j = math.random(1, i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end

function DestructorQueue.shuffleDisruptor(queue)
  return shuffle(queue)
end

return DestructorQueue
