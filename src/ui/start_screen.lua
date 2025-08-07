local Profiles = require("profiles")
local ActiveProfile = require("profiles.active")
local Version = require("version")
local GameLoop = require("game_loop")
local Click = require("ui.click")
local OptionsMenu = require("ui.options_menu")
local SelectScreen = require("ui.select_screen")
local EditProfile = require("ui.edit_profile")
local utf8 = require("utf8")

local StartScreen = {}

StartScreen.activeIndex = nil
StartScreen.state = "loading" -- "loading", "menu", "select", or "name_entry"
StartScreen.profile = nil
StartScreen.nameInput = ""

function StartScreen.load()
  local index = ActiveProfile.get()
  if index and Profiles.profileExists(index) then
    StartScreen.activeIndex = index
    StartScreen.profile = Profiles.load(index)
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
    SelectScreen.draw()
  elseif StartScreen.state == "loading" then
    lg.printf("Loading...", 0, H / 2 - 20, W, "center")
  elseif StartScreen.state == "name_entry" then
    EditProfile.draw(StartScreen.nameInput)
  elseif StartScreen.state == "menu" then
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

    add("continue", "Continue", StartScreen.profile.currentRun)
    add("new", "Start New Run", true)
    add("options", "Options", true)
    add("change", "Change Profile", true)
    add("quit", "Quit", true)

    -- Version number
    lg.setColor(1, 1, 1)
    lg.print("v" .. Version.number, W - 80, H - 30)

    -- Profile name in bottom left
    if StartScreen.profile then
      lg.print("Profile: " .. StartScreen.profile.name, 10, H - 30)
    else
      lg.print("No active profile", 10, H - 30)
    end
  end
end

function StartScreen.mousepressed(x, y, button)
  if button ~= 1 then return end

  local hit = Click.hit(x, y)
  if not hit then return end

  if StartScreen.state == "select" then
    local result = SelectScreen.mousepressed(hit)
    if result then
      if result.type == "select" then
        ActiveProfile.set(result.index)
        StartScreen.load()
      elseif result.type == "new" then
        StartScreen.nameInput = ""
        StartScreen.activeIndex = result.index
        StartScreen.state = "name_entry"
      elseif result.type == "delete" then
        -- handle profile deletion
        Profiles.delete(result.index)
        StartScreen.activeIndex = nil
        StartScreen.profile = nil
        StartScreen.nameInput = ""
        StartScreen.state = "select"
      end
    end
  elseif StartScreen.state == "name_entry" then
    local result = EditProfile.mousepressed(hit, StartScreen.nameInput)
    if result and result.type == "confirm" then
      -- if profile doesn't exist
      -- need to create an empty profile
      Profiles.create(StartScreen.activeIndex)
      ActiveProfile.set(StartScreen.activeIndex)
      Profiles.rename(StartScreen.activeIndex, result.name)
      StartScreen.load()
    end
  elseif StartScreen.state == "menu" then
    if hit.id == "continue" and StartScreen.profile.currentRun then
      GameLoop.init(StartScreen.activeIndex, StartScreen.profile.currentRun)
      CurrentScreen = "game"
    elseif hit.id == "new" then
      GameLoop.init(StartScreen.activeIndex)
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
    StartScreen.nameInput = EditProfile.textinput(t, StartScreen.nameInput)
  end
end

function StartScreen.keypressed(key)
  if StartScreen.state == "name_entry" then
    if key == "backspace" then
      StartScreen.nameInput = EditProfile.backspace(StartScreen.nameInput)
    elseif key == "return" then
      local result = EditProfile.returnPressed(StartScreen.nameInput)
      if result and result.type == "confirm" then
        -- if profile doesn't exist
        -- need to create an empty profile
        Profiles.create(StartScreen.activeIndex)
        ActiveProfile.set(StartScreen.activeIndex)
        Profiles.rename(StartScreen.activeIndex, result.name)
        StartScreen.load()
      end
    end
  end
end

return StartScreen
