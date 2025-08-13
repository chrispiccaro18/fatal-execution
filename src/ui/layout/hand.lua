local Const = require("const")
local cfg = require("ui.cfg")

local MODE = Const.UI.HAND_LAYOUT_MODE

local math_min, math_max, abs = math.min, math.max, math.abs
local General = require("util.general")
local clamp = General.clamp
local rad = General.rad

local LayoutHand = {}


-- returns { mode="spaced"|"overlap"|"fan", slots={ {x,y,w,h,angle,z}, ... } }
function LayoutHand.computeSlots(panel, n)
  local C     = cfg.handPanel
  local pad   = C.pad
  local cardW = C.cardW
  local cardH = C.cardH

  local areaX = panel.x + pad
  local areaY = panel.y + pad
  local areaW = panel.w - pad * 2
  local areaH = panel.h - pad * 2

  local slots = {}
  if n == 0 then return { mode = MODE.SPACED, slots = slots } end

  -- First try fully spaced (no overlap)
  if n == 1 then
    slots[1] = { x = areaX + (areaW - cardW) / 2, y = areaY, w = cardW, h = cardH, angle = 0, z = 1 }
    return { mode = MODE.SPACED, slots = slots }
  end

  local maxSpacing = C.maxSpacingX
  local totalWSpaced = n * cardW + (n - 1) * maxSpacing

  -- If fits → SPACED
  if totalWSpaced <= areaW then
    local startX = areaX + (areaW - totalWSpaced) / 2
    for i = 1, n do
      local x = startX + (i - 1) * (cardW + maxSpacing)
      slots[i] = { x = x, y = areaY, w = cardW, h = cardH, angle = 0, z = i }
    end
    return { mode = MODE.SPACED, slots = slots }
  end

  -- Else try LINEAR OVERLAP
  -- visible step for each next card
  local minVis = clamp(C.minVisiblePx, 8, cardW)
  local step   = (areaW - cardW) / (n - 1) -- how much x advance per card
  if step >= minVis then
    -- we can do a gentle overlap that fits
    local totalW = cardW + (n - 1) * step
    local startX = areaX + (areaW - totalW) / 2
    for i = 1, n do
      local x = startX + (i - 1) * step
      slots[i] = { x = x, y = areaY, w = cardW, h = cardH, angle = 0, z = i }
    end
    return { mode = MODE.OVERLAP, slots = slots }
  end

  -- Else FAN (compact but readable)
  local fanEnabled = C.fan.enabled
  if not fanEnabled then
    -- fallback: hard overlap using minVis
    local totalW = cardW + (n - 1) * minVis
    local startX = areaX + (areaW - totalW) / 2
    for i = 1, n do
      local x = startX + (i - 1) * minVis
      slots[i] = { x = x, y = areaY, w = cardW, h = cardH, angle = 0, z = i }
    end
    return { mode = MODE.OVERLAP, slots = slots }
  end

  -- FAN LAYOUT
  -- angles go from -max..+max around center; x spreads accordingly
  local maxA    = C.fan.maxAngleDeg
  -- If few cards, reduce angle; if many, cap at max
  local span    = math_min(maxA, 4 + (n - 2)) -- simple growth rule
  local leftA   = -span
  local rightA  = span
  local center  = (n + 1) / 2
  -- compute spread so edges fit in areaW
  -- approximate horizontal projection per step using visible strip
  local stepFan = clamp(minVis * 0.85, 10, cardW) -- compact but readable
  -- baseline center x
  local centerX = areaX + areaW / 2
  local baseY   = areaY + C.fan.liftPx

  for i = 1, n do
    local t = (i - center) / (center - 1)    -- ~[-1,1]
    if n == 2 then t = (i == 1) and -1 or 1 end
    local ang  = (leftA + (rightA - leftA) * ((i - 1) / (n - 1)))
    local aRad = rad(ang)
    local x    = centerX + (i - center) * stepFan - cardW / 2
    local y    = baseY - (1 - abs(t)) * (cfg.handPanel.fan.centerLift)
    slots[i]   = { x = x, y = y, w = cardW, h = cardH, angle = ang, z = i }
  end

  return { mode = MODE.FAN, slots = slots }
end

return LayoutHand
