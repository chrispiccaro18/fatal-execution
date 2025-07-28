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

return DestructorQueue
