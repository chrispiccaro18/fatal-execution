local Profiles = require("profiles")
local Click = require("ui.click")

local SelectScreen = {}

local cachedProfiles = Profiles.getCachedProfiles()

function SelectScreen.draw()
  local lg = love.graphics
  local W, H = lg.getDimensions()
  lg.setFont(lg.newFont(22))

  lg.printf("Select a Profile", 0, 80, W, "center")

  local buttonW, buttonH = 300, 40
  local startX = (W - buttonW) / 2
  local startY = 120
  local spacing = 50
  local colors = {
    bg = { 0.2, 0.2, 0.2 },
    border = { 1, 1, 1 },
    text = { 1, 1, 1 }
  }

  for i = 1, Profiles.getMaxProfiles() do
    local profile = cachedProfiles[i]
    local y = startY + (i - 1) * spacing

    -- Main profile button
    local label = profile
        and (i .. ". " .. profile.name)
        or (i .. ". <Empty>")
    local rect = { x = startX, y = y, w = buttonW, h = buttonH }
    Click.addButton("profile_" .. i, rect, label, colors, 20)

    -- Draw delete button only if profile exists
    if profile then
      local deleteW, deleteH = 30, 30
      local deleteRect = {
        x = startX + buttonW + 10,
        y = y + (buttonH - deleteH) / 2,
        w = deleteW,
        h = deleteH
      }
      Click.addButton("delete_" .. i, deleteRect, "X", {
                        bg = { 0.4, 0.1, 0.1 },
                        border = { 1, 1, 1 },
                        text = { 1, 1, 1 }
                      }, 18)
    end
  end
end

function SelectScreen.mousepressed(hit)
  -- handle profile click / delete
  -- return events like { type = "select", index = 2 } or { type = "new", index = 3 }
  if hit.id:match("^delete_(%d+)$") then
    local index = tonumber(hit.id:match("%d+"))
    return { type = "delete", index = index }
  elseif hit.id:match("^profile_(%d+)$") then
    local index = tonumber(hit.id:match("%d+"))
    if not Profiles.profileExists(index) then
      return { type = "new", index = index }
    end
    return { type = "select", index = index }
  end
end

return SelectScreen
