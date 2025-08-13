local Const = require("const")
local Click = require("ui.click")
local Display = require("ui.display")
local Profiles = require("profiles")

local OptionsMenu = {
  activeIndex = nil,
  isOpen = false,
  profile = {},
}

local hitIds = Const.HIT_IDS.OPTIONS_MENU
local buttonLabels = Const.BUTTON_LABELS.OPTIONS_MENU

function OptionsMenu.open(profileIndex)
  OptionsMenu.activeIndex = profileIndex
  OptionsMenu.profile = Profiles.get(profileIndex)
  OptionsMenu.isOpen = true
end

function OptionsMenu.close()
  Profiles.updateAllSettings(OptionsMenu.activeIndex, OptionsMenu.profile.settings)
  OptionsMenu.isOpen = false
  OptionsMenu.activeIndex = nil
  OptionsMenu.profile = {}
end

function OptionsMenu.draw()
  if not OptionsMenu.isOpen then return end

  local lg = love.graphics
  local W, H = Display.getVirtualSize()
  lg.setFont(lg.newFont(22))
  Click.clear()

  local settings = OptionsMenu.profile.settings
  local x = (W - 400) / 2
  local y = 100
  local spacing = 60
  local btnW, btnH = 400, 40
  local fontSize = 20
  local colors = {
    bg = { 0.2, 0.2, 0.2 },
    border = { 1, 1, 1 },
    text = { 1, 1, 1 }
  }

  local function drawVolumeControl(control)
    local percent = math.ceil(settings[control.settingKey] * 100 / 5) * 5

    Click.addButton(control.downId, { x = x, y = y, w = 40, h = btnH }, "-", colors, fontSize)
    Click.addButton(control.upId, { x = x + btnW - 40, y = y, w = 40, h = btnH }, "+", colors, fontSize)

    local labelText = string.format("%s: %d%%", buttonLabels[control.labelId], percent)
    Click.addButton(control.labelHitId, {
                      x = x + 50, y = y, w = btnW - 100, h = btnH
                    }, labelText, colors, fontSize)

    y = y + spacing
  end

  for _, control in ipairs(Const.VOLUME_CONTROLS) do
    drawVolumeControl(control)
  end

  -- Tooltip toggle
  local tooltipText = settings.showTooltips and buttonLabels.TOOLTIPS_ENABLED or buttonLabels.TOOLTIPS_DISABLED
  Click.addButton(hitIds.TOGGLE_TOOLTIPS, { x = x, y = y, w = btnW, h = btnH }, tooltipText, colors, fontSize)
  y = y + spacing

  -- Resolution
  local currentPreset = Display.presets[settings.resolutionIndex]
  Click.addButton(hitIds.RES_LEFT, { x = x, y = y, w = 40, h = btnH }, "<", colors, fontSize)
  Click.addButton(hitIds.RES_LABEL, { x = x + 50, y = y, w = btnW - 100, h = btnH },
                  string.format(buttonLabels.RESOLUTION .. "%dx%d", currentPreset.w, currentPreset.h), colors, fontSize)
  Click.addButton(hitIds.RES_RIGHT, { x = x + btnW - 40, y = y, w = 40, h = btnH }, ">", colors, fontSize)
  y = y + spacing

  -- Fullscreen toggle
  local fsLabel = settings.fullscreen and buttonLabels.FULLSCREEN_ENABLED or buttonLabels.FULLSCREEN_DISABLED
  Click.addButton(hitIds.TOGGLE_FULLSCREEN, { x = x, y = y, w = btnW, h = btnH }, fsLabel, colors, fontSize)
  y = y + spacing

  -- Back
  Click.addButton(hitIds.BACK, { x = x, y = y, w = btnW, h = btnH }, buttonLabels.BACK, colors, fontSize)
end

function OptionsMenu.mousepressed(x, y, button)
  if not OptionsMenu.isOpen or button ~= 1 then return end
  local hit = Click.hit(x, y)
  if not hit then return end

  local settings = OptionsMenu.profile.settings

  if hit.id == hitIds.VOL_UP_music then
    settings.musicVolume = math.min(1.0, settings.musicVolume + 0.05)
  elseif hit.id == hitIds.VOL_DOWN_music then
    settings.musicVolume = math.max(0.0, settings.musicVolume - 0.05)
  elseif hit.id == hitIds.VOL_UP_sfx then
    settings.sfxVolume = math.min(1.0, settings.sfxVolume + 0.05)
  elseif hit.id == hitIds.VOL_DOWN_sfx then
    settings.sfxVolume = math.max(0.0, settings.sfxVolume - 0.05)
  elseif hit.id == hitIds.TOGGLE_TOOLTIPS then
    settings.showTooltips = not settings.showTooltips
  elseif hit.id == hitIds.TOGGLE_FULLSCREEN then
    settings.fullscreen = not settings.fullscreen
    Display.apply(settings.resolutionIndex, settings.fullscreen)
  elseif hit.id == hitIds.RES_LEFT then
    local count = #Display.presets
    settings.resolutionIndex = ((settings.resolutionIndex - 2 + count) % count) + 1
    Display.apply(settings.resolutionIndex, settings.fullscreen)
  elseif hit.id == hitIds.RES_RIGHT then
    local count = #Display.presets
    settings.resolutionIndex = (settings.resolutionIndex % count) + 1
    Display.apply(settings.resolutionIndex, settings.fullscreen)
  elseif hit.id == hitIds.BACK then
    OptionsMenu.close()
  end
end

return OptionsMenu
