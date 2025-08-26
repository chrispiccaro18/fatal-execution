local TaskIdGen = {
  _nextId = 1
}

function TaskIdGen.next()
  local id = "task_" .. TaskIdGen._nextId
  TaskIdGen._nextId = TaskIdGen._nextId + 1
  return id
end

return TaskIdGen
