local Profiles = require("profiles.index")
local ActiveProfile = require("profiles.active")
local Version = require("version")
local GameState = require("game_state.index")
local Click = require("ui.click")
local OptionsMenu = require("ui.options_menu")

local StartScreen = {}

StartScreen.activeIndex = nil
StartScreen.state = "loading" -- "loading", "menu", or "select"

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
        Profiles.rename(index, "Player " .. index)
      end
      StartScreen.activeIndex = index
      ActiveProfile.set(index)
      StartScreen.state = "menu"
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

return StartScreen
