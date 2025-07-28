local cfg = require("ui.cfg")
local lg = love.graphics

local SystemsUI = {}

-- Returns rectangles for each system box and the progress bar, all inside `panel`
local function layoutSystemsPanel(panel, cfgLocal, numSystems)
  local pad      = cfgLocal.pad
  local innerW   = panel.w - pad * 2
  local innerY   = panel.y + pad

  -- First row: system boxes
  local wBox     = math.min(cfgLocal.boxW,
                            (innerW - cfgLocal.spacingX * (numSystems - 1)) / numSystems)
  local boxRects = {}
  for i = 1, numSystems do
    local x = panel.x + pad + (i - 1) * (wBox + cfgLocal.spacingX)
    boxRects[i] = { x = x, y = innerY, w = wBox, h = cfgLocal.boxH }
  end

  -- Second row: progress bar spans full inner width
  local barY = innerY + cfgLocal.boxH
  local barW = innerW
  local barR = { x = panel.x + pad, y = barY, w = barW, h = cfgLocal.barH }

  return boxRects, barR
end

-- Draws the widgets.
SystemsUI.drawSystemsPanel = function(panelRect)
  local cfgSys     = cfg.systemsPanel
  local gs         = love.gameState
  local systems    = gs.systems
  local curIndex   = gs.currentSystemIndex

  local boxes, bar = layoutSystemsPanel(panelRect, cfgSys, #systems)

  -- ── Systems row ──────────────────────────────────────────────
  for i, sys in ipairs(systems) do
    local r = boxes[i]

    -- background
    lg.setColor(0, 0, 0) -- black-ish fill
    lg.rectangle("fill", r.x, r.y, r.w, r.h)

    -- border: white if current
    if i == curIndex then
      lg.setColor(1, 1, 1) -- white border
    else
      lg.setColor(0.5, 0.5, 0.5) -- gray border for other systems
    end
    lg.rectangle("line", r.x, r.y, r.w, r.h)

    -- system name
    lg.setFont(lg.newFont(14))
    lg.printf(sys.name, r.x, r.y + 10, r.w, "center")
  end

  -- ── Progress bar ─────────────────────────────────────────────
  local currSys  = systems[curIndex]
  local sectionW = bar.w / currSys.required

  lg.setColor(0, 0, 0) -- background
  lg.rectangle("fill", bar.x, bar.y, bar.w, bar.h)

  lg.setColor(0.2, 0.2, 0.8) -- progress fill
  for i = 1, currSys.progress do
    lg.rectangle("fill",
                 bar.x + (i - 1) * sectionW, bar.y,
                 sectionW, bar.h)
  end

  -- section dividers
  lg.setColor(1, 1, 1)
  for i = 1, currSys.required - 1 do
    local x = bar.x + i * sectionW
    lg.line(x, bar.y, x, bar.y + bar.h)
  end
  lg.rectangle("line", bar.x, bar.y, bar.w, bar.h) -- outer border
end

return SystemsUI
