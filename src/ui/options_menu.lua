local Click = require("ui.click")
local Display = require("ui.display")
local Profiles = require("profiles")
local ActiveProfile = require("profiles.active")

local OptionsMenu = {}
OptionsMenu.activeIndex = nil
OptionsMenu.isOpen = false

local function applyDisplay(resIndex, fullscreen)
  Display.apply(resIndex, fullscreen)
end

function OptionsMenu.open()
  OptionsMenu.activeIndex = ActiveProfile.get()
  OptionsMenu.isOpen = true
end

function OptionsMenu.close()
  OptionsMenu.isOpen = false
  Profiles.save(OptionsMenu.activeIndex)
  OptionsMenu.activeIndex = nil
end

function OptionsMenu.draw()
  if not OptionsMenu.isOpen then return end

  local lg = love.graphics
  local W, H = lg.getDimensions()
  lg.setFont(lg.newFont(22))
  Click.clear()

  local profile = Profiles.load(OptionsMenu.activeIndex)
  local settings = profile.settings
  local x = (W - 400) / 2
  local y = 100
  local spacing = 60
  local btnW, btnH = 400, 40
  local fontSize = 20
  local colors = {
    bg = {0.2, 0.2, 0.2},
    border = {1, 1, 1},
    text = {1, 1, 1}
  }

  local function drawVolume(label, key)
    local percent = math.floor(settings[key] * 100)
    Click.addButton("vol_up_" .. key, {x = x, y = y, w = 40, h = btnH}, "+", colors, fontSize)
    Click.addButton("vol_down_" .. key, {x = x + btnW - 40, y = y, w = 40, h = btnH}, "-", colors, fontSize)
    Click.addButton("vol_label_" .. key, {x = x + 50, y = y, w = btnW - 100, h = btnH},
      string.format("%s Volume: %d%%", label, percent), colors, fontSize)
    y = y + spacing
  end

  drawVolume("Music", "musicVolume")
  drawVolume("SFX", "sfxVolume")

  -- Tooltip toggle
  local tooltipText = settings.showTooltips and "Tooltips: ON" or "Tooltips: OFF"
  Click.addButton("toggle_tooltips", {x = x, y = y, w = btnW, h = btnH}, tooltipText, colors, fontSize)
  y = y + spacing

  -- Resolution
  local currentPreset = Display.presets[settings.resolutionIndex]
  Click.addButton("res_left", {x = x, y = y, w = 40, h = btnH}, "<", colors, fontSize)
  Click.addButton("res_label", {x = x + 50, y = y, w = btnW - 100, h = btnH},
    string.format("Resolution: %dx%d", currentPreset.w, currentPreset.h), colors, fontSize)
  Click.addButton("res_right", {x = x + btnW - 40, y = y, w = 40, h = btnH}, ">", colors, fontSize)
  y = y + spacing

  -- Fullscreen toggle
  local fsLabel = settings.fullscreen and "Fullscreen: ON" or "Fullscreen: OFF"
  Click.addButton("toggle_fullscreen", {x = x, y = y, w = btnW, h = btnH}, fsLabel, colors, fontSize)
  y = y + spacing

  -- Back
  Click.addButton("options_back", {x = x, y = y, w = btnW, h = btnH}, "Back to Menu", colors, fontSize)
end

function OptionsMenu.mousepressed(x, y, button)
  if not OptionsMenu.isOpen or button ~= 1 then return end
  local hit = Click.hit(x, y)
  if not hit then return end

  local profile = Profiles.load(OptionsMenu.activeIndex)
  local settings = profile.settings

  if hit.id == "vol_up_musicVolume" then
    settings.musicVolume = math.min(1.0, settings.musicVolume + 0.05)
  elseif hit.id == "vol_down_musicVolume" then
    settings.musicVolume = math.max(0.0, settings.musicVolume - 0.05)
  elseif hit.id == "vol_up_sfxVolume" then
    settings.sfxVolume = math.min(1.0, settings.sfxVolume + 0.05)
  elseif hit.id == "vol_down_sfxVolume" then
    settings.sfxVolume = math.max(0.0, settings.sfxVolume - 0.05)
  elseif hit.id == "toggle_tooltips" then
    settings.showTooltips = not settings.showTooltips
  elseif hit.id == "toggle_fullscreen" then
    settings.fullscreen = not settings.fullscreen
    applyDisplay(settings.resolutionIndex, settings.fullscreen)
  elseif hit.id == "res_left" then
    local count = #Display.presets
    settings.resolutionIndex = ((settings.resolutionIndex - 2 + count) % count) + 1
    applyDisplay(settings.resolutionIndex, settings.fullscreen)
  elseif hit.id == "res_right" then
    local count = #Display.presets
    settings.resolutionIndex = (settings.resolutionIndex % count) + 1
    applyDisplay(settings.resolutionIndex, settings.fullscreen)
  elseif hit.id == "options_back" then
    Profiles.save(OptionsMenu.activeIndex)
    OptionsMenu.close()
  end
end

return OptionsMenu
