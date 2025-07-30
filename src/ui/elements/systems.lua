local cfg = require("ui.cfg")
local Decorators = require("ui.decorators")
local lg = love.graphics

local SystemsUI = {}

local progressFillDecorators = {}

function SystemsUI.triggerProgress(payload)
  local index = payload.systemIndex
  local delta = payload.delta
  if delta == 0 then return end

  progressFillDecorators[index] = progressFillDecorators[index] or {}

  local direction = delta > 0 and "increasing" or "decreasing"
  local absDelta = math.abs(delta)

  for i = 1, absDelta do
    table.insert(progressFillDecorators[index], {
      timer = 0,
      duration = 0.4,
      direction = direction,
      step = i -- Track the sequential step of the animation
    })
  end
end

function SystemsUI.update(dt)
  for index, animations in pairs(progressFillDecorators) do
    for i = #animations, 1, -1 do
      local anim = animations[i]
      anim.timer = anim.timer + dt
      if anim.timer >= anim.duration then
        table.remove(animations, i) -- Remove completed animation
      end
    end

    -- Remove the system entry if no animations are left
    if #animations == 0 then
      progressFillDecorators[index] = nil
    end
  end
end

Decorators.register(SystemsUI.update)

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

  -- Systems row
  for i, sys in ipairs(systems) do
    local r = boxes[i]

    -- background
    lg.setColor(0, 0, 0) -- black-ish fill
    lg.rectangle("fill", r.x, r.y, r.w, r.h)

    -- border: white if current
    if i == curIndex then
      lg.setColor(1, 1, 1)       -- white border
    else
      lg.setColor(0.5, 0.5, 0.5) -- gray border for other systems
    end
    lg.rectangle("line", r.x, r.y, r.w, r.h)

    -- system name
    lg.setFont(lg.newFont(14))
    lg.printf(sys.name, r.x, r.y + 10, r.w, "center")
  end

  -- Progress bar
  local currSys  = systems[curIndex]
  local sectionW = bar.w / currSys.required

  lg.setColor(0, 0, 0) -- background
  lg.rectangle("fill", bar.x, bar.y, bar.w, bar.h)

  -- lg.setColor(0.2, 0.2, 0.8) -- progress fill
  local anim = progressFillDecorators[curIndex]
  local progress = currSys.progress
  -- local direction = anim and anim.direction
  -- local pct = anim and math.min(1, anim.timer / anim.duration) or 1

  for i = 1, currSys.required do
    local sectionX = bar.x + (i - 1) * sectionW
    local drawW = sectionW
    local drawH = bar.h

    local isFilled = i <= progress
    local isAnimating = false

    if progressFillDecorators[curIndex] then
      for _, anim in ipairs(progressFillDecorators[curIndex]) do
        local pct = math.min(1, anim.timer / anim.duration)
        local ease = pct * pct

        -- Determine which bar is being animated
        local targetBar = progress + anim.step
        if anim.direction == "increasing" and i == targetBar then
          -- Animate growing new block
          isAnimating = true
          drawW = sectionW * ease
          lg.setColor(0.2, 0.2, 0.8)
        elseif anim.direction == "decreasing" and i == progress + 1 - anim.step then
          -- Animate shrinking old block (yellow)
          isAnimating = true
          drawW = sectionW * (1 - ease)
          isFilled = true    -- temporarily still filled
          lg.setColor(1, 1, 0) -- yellow
        end
      end
    end

    if isAnimating or isFilled then
      if not isAnimating then
        lg.setColor(0.2, 0.2, 0.8) -- standard filled blue
      end

      lg.rectangle("fill", sectionX, bar.y, drawW, drawH)
    end
  end
  -- for i = 1, currSys.required do
  --   local sectionX = bar.x + (i - 1) * sectionW
  --   local drawW = sectionW
  --   local drawH = bar.h

  --   local isFilled = i <= progress
  --   local isAnimating = false

  --   if anim then
  --     if direction == "increasing" and i == progress then
  --       -- Animate growing new block
  --       isAnimating = true
  --       drawW = sectionW * pct
  --       lg.setColor(0.2, 0.2, 0.8)
  --     elseif direction == "decreasing" and i == progress + 1 then
  --       -- Animate shrinking old block (yellow)
  --       isAnimating = true
  --       drawW = sectionW * (1 - pct)
  --       isFilled = true      -- temporarily still filled
  --       lg.setColor(1, 1, 0) -- yellow
  --     end
  --   end

  --   if isAnimating or isFilled then
  --     if not isAnimating then
  --       lg.setColor(0.2, 0.2, 0.8) -- standard filled blue
  --     end

  --     lg.rectangle("fill", sectionX, bar.y, drawW, drawH)
  --   end
  -- end

  -- section dividers
  lg.setColor(1, 1, 1)
  for i = 1, currSys.required - 1 do
    local x = bar.x + i * sectionW
    lg.line(x, bar.y, x, bar.y + bar.h)
  end
  lg.rectangle("line", bar.x, bar.y, bar.w, bar.h) -- outer border
end

return SystemsUI
