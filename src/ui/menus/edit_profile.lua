local Display = require("ui.display")
local Click = require("ui.click")

local EditProfile = {}

local inValidName = false

function EditProfile.draw(nameInput)
  local lg = love.graphics
  local W, H = Display.getVirtualSize()
  lg.setFont(lg.newFont(22))

  lg.printf("Enter Profile Name:", 0, 80, W, "center")
  local boxW, boxH = 400, 40
  local boxX = (W - boxW) / 2
  local boxY = 140

  -- Draw input box
  lg.setColor(0.2, 0.2, 0.2)
  lg.rectangle("fill", boxX, boxY, boxW, boxH)
  lg.setColor(1, 1, 1)
  lg.rectangle("line", boxX, boxY, boxW, boxH)
  lg.printf(nameInput, boxX + 10, boxY + 8, boxW - 20, "left")

  local caretVisible = math.floor(love.timer.getTime() * 2) % 2 == 0
  if caretVisible then
    local font = lg.getFont()
    local textWidth = font:getWidth(nameInput)
    local caretX = boxX + 10 + textWidth + 1
    local caretY = boxY + 8
    lg.setColor(1, 1, 1)
    lg.rectangle("fill", caretX, caretY, 2, font:getHeight())
  end

  if inValidName then
    lg.setColor(1, 0, 0)
    lg.printf("Invalid name! Please enter a valid profile name.", 0, boxY + boxH + 10, W, "center")
  else
    lg.setColor(1, 1, 1)
  end

  -- Confirm button
  local btnW, btnH = 120, 40
  local btnX = (W - btnW) / 2
  local btnY = boxY + 60
  Click.addButton("confirm_name", { x = btnX, y = btnY, w = btnW, h = btnH }, "Confirm", {
                    bg = { 0.2, 0.4, 0.2 },
                    border = { 1, 1, 1 },
                    text = { 1, 1, 1 }
                  }, 20)
end

function EditProfile.mousepressed(hit, nameInput)
  if hit.id == "confirm_name" then
    local name = nameInput:match("^%s*(.-)%s*$")
    if name ~= "" then
      -- local index = StartScreen.nameProfileIndex
      -- Profiles.rename(index, name)
      -- StartScreen.activeIndex = index
      -- ActiveProfile.set(index)
      -- StartScreen.state = "menu"
      return { type = "confirm", name = name }
    else
      inValidName = true
      return nil
    end
  end
end

function EditProfile.textinput(text, nameInput)
  if inValidName then
    inValidName = false
  end

  -- Limit input to 20 characters
  if #nameInput < 20 then
    nameInput = nameInput .. text
  end

  return nameInput
end

function EditProfile.backspace(nameInput)
  if inValidName then
    inValidName = false
  end

  -- Remove last character if possible
  if #nameInput > 0 then
    nameInput = nameInput:sub(1, -2)
  end

  return nameInput
end

function EditProfile.returnPressed(nameInput)
  local name = nameInput:match("^%s*(.-)%s*$")
  if name ~= "" then
    return { type = "confirm", name = name }
  else
    inValidName = true
    return nil
  end
end

return EditProfile
