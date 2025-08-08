local Const = require("const")
local cfg = require("ui.cfg")
local Profiles = require("profiles")
local ActiveProfile = require("profiles.active")
local Version = require("version")
local GameLoop = require("game_loop")
local Click = require("ui.click")
local OptionsMenu = require("ui.options_menu")
local SelectScreen = require("ui.select_screen")
local EditProfile = require("ui.edit_profile")

local StartScreen = {}

local startScreenStates = Const.START_SCREEN_STATES
local hitIds = Const.HIT_IDS.START_SCREEN
local buttonLabels = Const.BUTTON_LABELS.START_SCREEN

StartScreen.activeIndex = nil
StartScreen.state = startScreenStates.LOADING
StartScreen.profile = nil
StartScreen.nameInput = ""

function StartScreen.load()
  local index = ActiveProfile.get()
  if index and Profiles.profileExists(index) then
    StartScreen.activeIndex = index
    StartScreen.profile = Profiles.load(index)
    StartScreen.state = startScreenStates.MENU
  else
    StartScreen.state = startScreenStates.SELECT
  end
end

function StartScreen.draw()
  local lg = love.graphics
  local W, H = lg.getDimensions()
  lg.setFont(lg.newFont(cfg.fontSizeXL))

  Click.clear()

  if StartScreen.state == startScreenStates.SELECT then
    SelectScreen.draw()
  elseif StartScreen.state == startScreenStates.LOADING then
    lg.printf("Loading...", 0, H / 2 - 20, W, "center")
  elseif StartScreen.state == startScreenStates.NAME_ENTRY then
    EditProfile.draw(StartScreen.nameInput)
  elseif StartScreen.state == startScreenStates.MENU then
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

    add(hitIds.CONTINUE, buttonLabels.CONTINUE, StartScreen.profile.currentRun)
    add(hitIds.NEW, buttonLabels.NEW, true)
    add(hitIds.OPTIONS, buttonLabels.OPTIONS, true)
    add(hitIds.CHANGE, buttonLabels.CHANGE, true)
    add(hitIds.QUIT, buttonLabels.QUIT, true)

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

  if StartScreen.state == startScreenStates.SELECT then
    local result = SelectScreen.mousepressed(hit)
    if result then
      if result.type == "select" then
        ActiveProfile.set(result.index)
        StartScreen.load()
      elseif result.type == "new" then
        StartScreen.nameInput = ""
        StartScreen.activeIndex = result.index
        StartScreen.state = startScreenStates.NAME_ENTRY
      elseif result.type == "delete" then
        -- handle profile deletion
        Profiles.delete(result.index)
        StartScreen.activeIndex = nil
        StartScreen.profile = nil
        StartScreen.nameInput = ""
        StartScreen.state = startScreenStates.SELECT
      end
    end
  elseif StartScreen.state == startScreenStates.NAME_ENTRY then
    local result = EditProfile.mousepressed(hit, StartScreen.nameInput)
    if result and result.type == "confirm" then
      -- if profile doesn't exist
      -- need to create an empty profile
      Profiles.create(StartScreen.activeIndex)
      ActiveProfile.set(StartScreen.activeIndex)
      Profiles.rename(StartScreen.activeIndex, result.name)
      StartScreen.load()
    end
  elseif StartScreen.state == startScreenStates.MENU then
    if hit.id == hitIds.CONTINUE and StartScreen.profile.currentRun then
      GameLoop.init(StartScreen.activeIndex, StartScreen.profile.currentRun)
      CurrentScreen = Const.CURRENT_SCREEN.GAME
    elseif hit.id == hitIds.NEW then
      GameLoop.init(StartScreen.activeIndex)
      CurrentScreen = Const.CURRENT_SCREEN.GAME
    elseif hit.id == hitIds.OPTIONS then
      OptionsMenu.open(StartScreen.activeIndex)
    elseif hit.id == hitIds.CHANGE then
      StartScreen.state = startScreenStates.SELECT
    elseif hit.id == hitIds.QUIT then
      love.event.quit()
    end
  end
end

function StartScreen.textinput(t)
  if StartScreen.state == startScreenStates.NAME_ENTRY then
    StartScreen.nameInput = EditProfile.textinput(t, StartScreen.nameInput)
  end
end

function StartScreen.keypressed(key)
  if StartScreen.state == startScreenStates.NAME_ENTRY then
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
