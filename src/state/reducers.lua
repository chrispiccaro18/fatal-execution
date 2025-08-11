local Reducers = {}

function Reducers.reduce(model, action)
  local ui = {}
  local tasks = {}

  if action.type == "BEGIN_TURN" then
    -- append a resumable task; no immediate UI required
    table.insert(tasks, { type="begin_turn", pc=1, args={} })
    return model, ui, tasks

  elseif action.type == "PLAY_CARD" then
    -- enqueue play-card task; the task will move the card, apply effects, schedule anims
    table.insert(tasks, { type="play_card", pc=1, args={ handIndex = action.idx } })
    return model, ui, tasks

  elseif action.type == "END_TURN" then
    table.insert(tasks, { type="end_turn", pc=1, args={} })
    return model, ui, tasks
  end

  return model, ui, tasks
end

return Reducers
