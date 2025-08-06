local Profiles = require("profiles.index")
local ActiveProfile = require("profiles.active")
local Version = require("version")
local GameState = require("game_state.index")
local Click = require("ui.click")
local OptionsMenu = require("ui.options_menu")
local utf8 = require("utf8")

local StartScreen = {}

StartScreen.activeIndex = nil
StartScreen.state = "loading" -- "loading", "menu", "select", or "name_entry"
StartScreen.nameInput = ""
StartScreen.nameProfileIndex = nil

function StartScreen.load()
  local index = ActiveProfile.get()
  if index and Profiles.profileExists(index) then
    StartScreen.activeIndex = index
    StartScreen.state = "menu"
  else
    StartScreen.state = "select"
  end
end

function StartScreen.draw()
  local lg = love.graphics
  local W, H = lg.getDimensions()
  lg.setFont(lg.newFont(22))

  Click.clear()

  if StartScreen.state == "select" then
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
      local y = startY + (i - 1) * spacing

      -- Main profile button
      local label = Profiles.profileExists(i)
          and (i .. ". " .. Profiles.getName(i))
          or (i .. ". <Empty>")
      local rect = { x = startX, y = y, w = buttonW, h = buttonH }
      Click.addButton("profile_" .. i, rect, label, colors, 20)

      -- Draw delete button only if profile exists
      if Profiles.profileExists(i) then
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
  elseif StartScreen.state == "name_entry" then
    lg.printf("Enter Profile Name:", 0, 80, W, "center")
    local boxW, boxH = 400, 40
    local boxX = (W - boxW) / 2
    local boxY = 140

    -- Draw input box
    lg.setColor(0.2, 0.2, 0.2)
    lg.rectangle("fill", boxX, boxY, boxW, boxH)
    lg.setColor(1, 1, 1)
    lg.rectangle("line", boxX, boxY, boxW, boxH)
    lg.printf(StartScreen.nameInput, boxX + 10, boxY + 8, boxW - 20, "left")

    local caretVisible = math.floor(love.timer.getTime() * 2) % 2 == 0
    if caretVisible then
      local font = lg.getFont()
      local textWidth = font:getWidth(StartScreen.nameInput)
      local caretX = boxX + 10 + textWidth + 1
      local caretY = boxY + 8
      lg.setColor(1, 1, 1)
      lg.rectangle("fill", caretX, caretY, 2, font:getHeight())
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
  elseif StartScreen.state == "menu" then
    local profile = Profiles.load(StartScreen.activeIndex)

    local buttonW, buttonH = 300, 40
    local startX = (W - buttonW) / 2
    local startY = 100
    local spacing = 50
    local colors = {
      bg = { 0.2, 0.2, 0.2 },
      border = { 1, 1, 1 },
      text = { 1, 1, 1 }
    }

    local function add(id, label, enabled)
      local rect = { x = startX, y = startY + (#Click.list + 1 - 1) * spacing, w = buttonW, h = buttonH }
      local dimmed = enabled and colors or {
        bg = { 0.1, 0.1, 0.1 },
        border = { 0.5, 0.5, 0.5 },
        text = { 0.5, 0.5, 0.5 }
      }
      Click.addButton(id, rect, label, dimmed, 20)
    end

    add("continue", "Continue", profile.currentRun ~= nil)
    add("new", "Start New Run", true)
    add("options", "Options", true)
    add("change", "Change Profile", true)
    add("quit", "Quit", true)

    -- Version number
    lg.setColor(1, 1, 1)
    lg.print("v" .. Version.number, W - 80, H - 30)
  end
end

function StartScreen.mousepressed(x, y, button)
  if button ~= 1 then return end

  local hit = Click.hit(x, y)
  if not hit then return end

  if StartScreen.state == "select" then
    if hit.id:match("^delete_(%d+)$") then
      local index = tonumber(hit.id:match("%d+"))
      Profiles.delete(index)
      return
    elseif hit.id:match("^profile_(%d+)$") then
      local index = tonumber(hit.id:match("%d+"))
      if not Profiles.profileExists(index) then
        StartScreen.state = "name_entry"
        StartScreen.nameInput = ""
        StartScreen.nameProfileIndex = index
        return
      end
      StartScreen.activeIndex = index
      ActiveProfile.set(index)
      StartScreen.state = "menu"
      return
    end
  elseif StartScreen.state == "name_entry" then
    if hit.id == "confirm_name" then
      local name = StartScreen.nameInput:match("^%s*(.-)%s*$")
      if name ~= "" then
        local index = StartScreen.nameProfileIndex
        Profiles.rename(index, name)
        StartScreen.activeIndex = index
        ActiveProfile.set(index)
        StartScreen.state = "menu"
      end
      return
    end
  end

  if StartScreen.state == "menu" then
    local profile = Profiles.load(StartScreen.activeIndex)

    if hit.id == "continue" and profile.currentRun then
      love.gameState = profile.currentRun
      CurrentScreen = "game"
    elseif hit.id == "new" then
      Profiles.clearCurrentRun(StartScreen.activeIndex)
      love.gameState = GameState.beginTurn(GameState.init())
      Profiles.setCurrentRun(StartScreen.activeIndex, love.gameState)
      CurrentScreen = "game"
    elseif hit.id == "options" then
      OptionsMenu.open()
    elseif hit.id == "change" then
      StartScreen.state = "select"
    elseif hit.id == "quit" then
      love.event.quit()
    end
  end
end

function StartScreen.textinput(t)
  if StartScreen.state == "name_entry" then
    if #StartScreen.nameInput < 20 then
      StartScreen.nameInput = StartScreen.nameInput .. t
    end
  end
end

function StartScreen.keypressed(key)
  if StartScreen.state == "name_entry" then
    if key == "backspace" then
      local byteOffset = utf8.offset(StartScreen.nameInput, -1)
      if byteOffset then
        StartScreen.nameInput = string.sub(StartScreen.nameInput, 1, byteOffset - 1)
      end
    elseif key == "return" then
      -- Same as clicking confirm
      local name = StartScreen.nameInput:match("^%s*(.-)%s*$")
      if name ~= "" then
        local index = StartScreen.nameProfileIndex
        Profiles.rename(index, name)
        StartScreen.activeIndex = index
        ActiveProfile.set(index)
        StartScreen.state = "menu"
      end
    end
  end
end

return StartScreen
