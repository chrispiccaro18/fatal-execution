local cfg = require("ui.cfg")
local lg  = love.graphics

local colors = cfg.colors

local SystemsUI = {}

local function layoutSystemsPanel(panel, cfgLocal, numSystems)
  local pad      = cfgLocal.pad
  local innerW   = panel.w - pad * 2
  local innerY   = panel.y + pad

  local wBox     = math.min(cfgLocal.boxW,
                            (innerW - cfgLocal.spacingX * (numSystems - 1)) / numSystems)

  local boxRects = {}
  for i = 1, numSystems do
    local x = panel.x + pad + (i - 1) * (wBox + cfgLocal.spacingX)
    boxRects[i] = { x = x, y = innerY, w = wBox, h = cfgLocal.boxH }
  end

  local barY = innerY + cfgLocal.boxH + cfgLocal.spacingY
  local barR = { x = panel.x + pad, y = barY, w = innerW, h = cfgLocal.barH }
  return boxRects, barR
end

-- Draws without animations.
-- systems: array of { name=..., required=..., progress=..., activated=... }
-- currentIndex: integer (1-based)
function SystemsUI.drawSystemsPanel(panelRect, systems, currentIndex)
  local cfgSys   = cfg.systemsPanel
  local boxes, bar = layoutSystemsPanel(panelRect, cfgSys, #systems)

  -- Systems row
  for i, sys in ipairs(systems) do
    local r = boxes[i]

    -- bg
    lg.setColor(0, 0, 0)
    lg.rectangle("fill", r.x, r.y, r.w, r.h)

    -- border: white if current
    lg.setColor(i == currentIndex and colors.white or colors.lightGray)
    lg.rectangle("line", r.x, r.y, r.w, r.h)

    -- name
    lg.setFont(lg.newFont(14))  -- tip: cache fonts; don’t newFont() every frame
    lg.printf(sys.name or ("System " .. i), r.x, r.y + 10, r.w, "center")
  end

  -- Progress bar (discrete blocks)
  local currSys  = systems[currentIndex]
  if currSys then
    local sectionW = bar.w / math.max(1, currSys.required)

    -- bg
    lg.setColor(0, 0, 0)
    lg.rectangle("fill", bar.x, bar.y, bar.w, bar.h)

    -- filled sections
    for i = 1, currSys.required do
      local filled = (i <= (currSys.progress or 0))
      if filled then
        lg.setColor(colors.blue)
        local sx = bar.x + (i - 1) * sectionW
        lg.rectangle("fill", sx, bar.y, sectionW, bar.h)
      end
    end

    -- dividers + border
    lg.setColor(1, 1, 1)
    for i = 1, currSys.required - 1 do
      local x = bar.x + i * sectionW
      lg.line(x, bar.y, x, bar.y + bar.h)
    end
    lg.rectangle("line", bar.x, bar.y, bar.w, bar.h)
  end
end

return SystemsUI
