local Const             = require("const")
local cfg               = require("ui.cfg")
local Profiles          = require("profiles")
local ActiveProfile     = require("profiles.active")
local Version           = require("version")
local GameLoop          = require("game_loop")
local Click             = require("ui.click")
local SelectScreen      = require("ui.menus.select_screen")
local OptionsMenu       = require("ui.menus.options_menu")
local EditProfile       = require("ui.menus.edit_profile")
local ConfirmDialog     = require("ui.menus.confirm_dialog")

local StartScreen       = {}

local startScreenStates = Const.START_SCREEN_STATES
local hitIds            = Const.HIT_IDS.START_SCREEN
local buttonLabels      = Const.BUTTON_LABELS.START_SCREEN

StartScreen.activeIndex = nil
StartScreen.state       = startScreenStates.LOADING
StartScreen.profile     = nil
StartScreen.nameInput   = ""

local function loadProfile(index)
  if not index then return nil end
  if not Profiles.profileExists(index) then return nil end
  return Profiles.get(index) -- cache-first; returns table or nil per your Profiles
end

function StartScreen.load()
  local index = ActiveProfile.get()
  if index and Profiles.profileExists(index) then
    StartScreen.activeIndex = index
    StartScreen.profile     = loadProfile(index)
    StartScreen.state       = startScreenStates.MENU
  else
    StartScreen.activeIndex = nil
    StartScreen.profile     = nil
    StartScreen.state       = startScreenStates.SELECT
  end
end

local function createNewProfile(result)
  if result and result.type == "confirm" then
    Profiles.create(StartScreen.activeIndex, result.name)
    ActiveProfile.set(StartScreen.activeIndex)
    StartScreen.load()
  end
end

local function deleteProfile(result)
  local deleteText = "delete the " .. StartScreen.profile.name .. " profile"
  local onConfirm = function()
    Profiles.delete(result.index)
    if StartScreen.activeIndex == result.index then
      StartScreen.activeIndex = nil
      StartScreen.profile     = nil
    end
  end
  local onCancel = function()
    print("Cancelled profile deletion")
  end
  local options = { confirmLabel = "Delete", cancelLabel = "Keep" }

  ConfirmDialog.open(deleteText, onConfirm, onCancel, options)
  StartScreen.nameInput = ""
  StartScreen.state     = startScreenStates.SELECT
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
    local startX, startY   = (W - buttonW) / 2, 100
    local spacing          = 50
    local defaultColors    = {
      bg = cfg.colors.darkGray,
      border = cfg.colors.white,
      text = cfg.colors.white
    }

    local function add(id, label, disabled)
      local rect = { x = startX, y = startY + (#Click.list) * spacing, w = buttonW, h = buttonH }
      local buttonColors = defaultColors
      if disabled then
        buttonColors = {
          bg = cfg.colors.darkerGray,
          border = cfg.colors.lightGray,
          text = cfg.colors.lightGray
        }
      end

      Click.addButton(id, rect, label, buttonColors, cfg.fontSizeXL)
    end

    local hasRun = StartScreen.profile and StartScreen.profile.currentRun

    add(hitIds.CONTINUE, buttonLabels.CONTINUE, not hasRun)
    add(hitIds.NEW, buttonLabels.NEW, false)
    add(hitIds.OPTIONS, buttonLabels.OPTIONS, false)
    add(hitIds.CHANGE, buttonLabels.CHANGE, false)
    add(hitIds.QUIT, buttonLabels.QUIT, false)

    -- Version number
    lg.setColor(cfg.colors.white)
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
        StartScreen.nameInput   = ""
        StartScreen.activeIndex = result.index
        StartScreen.state       = startScreenStates.NAME_ENTRY
      elseif result.type == "delete" then
        deleteProfile(result)
      end
    end
  elseif StartScreen.state == startScreenStates.NAME_ENTRY then
    local result = EditProfile.mousepressed(hit, StartScreen.nameInput)
    createNewProfile(result)
  elseif StartScreen.state == startScreenStates.MENU then
    if hit.id == hitIds.CONTINUE and StartScreen.profile and StartScreen.profile.currentRun then
      GameLoop.init(StartScreen.activeIndex, StartScreen.profile.currentRun)
      CurrentScreen = Const.CURRENT_SCREEN.GAME
    elseif hit.id == hitIds.NEW then
      GameLoop.init(StartScreen.activeIndex, nil)
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
      createNewProfile(result)
    end
  end
end

return StartScreen
