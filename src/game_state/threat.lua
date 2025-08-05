local Threat = {}

function Threat.init()
  return { value = 5, max = 10 }
end

function Threat.increment(threat, amount)
  local newThreat = threat.value + amount
  if newThreat > threat.max then
    newThreat = threat.max
  end
  return { value = newThreat, max = threat.max }
end

function Threat.set(threat, amount)
  if amount < 0 then
    amount = 0
  elseif amount > threat.max then
    amount = threat.max
  end
  return { value = amount, max = threat.max }
end

return Threat