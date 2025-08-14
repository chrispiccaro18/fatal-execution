local IdGen = {}

function IdGen.nextCard(model)
  model.ids.nextCard = model.ids.nextCard + 1
  return string.format("%s:c-%06d", model.ids.run or "r-unknown", model.ids.nextCard)
end

return IdGen
