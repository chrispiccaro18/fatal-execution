local filename = "active_profile.txt"

local ActiveProfile = {}

function ActiveProfile.set(index)
  love.filesystem.write(filename, tostring(index))
end

function ActiveProfile.get()
  local exists = love.filesystem.getInfo(filename)
  if not exists then return nil end
  local content = love.filesystem.read(filename)
  local index = tonumber(content)
  return (index and index >= 1 and index <= 3) and index or nil
end

return ActiveProfile
