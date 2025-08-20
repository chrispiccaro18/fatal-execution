local Const = require("const")
local cfg = require("ui.cfg")

local MODE = Const.UI.HAND_LAYOUT_MODE

local math_min, math_max, abs = math.min, math.max, math.abs
local General = require("util.general")
local deepcopy = require("util.deepcopy")
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
    local t = (i - center) / (center - 1) -- ~[-1,1]
    if n == 2 then t = (i == 1) and -1 or 1 end
    local ang  = (leftA + (rightA - leftA) * ((i - 1) / (n - 1)))
    local aRad = rad(ang)
    local x    = centerX + (i - center) * stepFan - cardW / 2
    local y    = baseY - (1 - abs(t)) * (cfg.handPanel.fan.centerLift)
    slots[i]   = { x = x, y = y, w = cardW, h = cardH, angle = ang, z = i }
  end

  return { mode = MODE.FAN, slots = slots }
end

-- Returns per-slot x-offsets (pixels) to apply when a slot is hovered.
-- handSlots = { mode=..., slots={ {x,y,w,h,angle,z}, ... } }
-- hoveredIndex = index of hovered card (1..n) or nil
function LayoutHand.computeHoverOffsets(handSlots, hoveredIndex, panel)
  local slots = handSlots.slots
  local n = #slots
  if not hoveredIndex or n <= 1 then return {} end

  local C = cfg.handPanel
  local cardW = C.cardW
  local pad = C.pad or 0
  local areaX = panel.x + pad
  local areaW = panel.w - pad * 2

  local C_hover = C.hover
  local hoveredCardOriginal = slots[hoveredIndex]
  local hoveredCardW = hoveredCardOriginal.w * C_hover.scale
  local hoveredCardX = hoveredCardOriginal.x - (hoveredCardW - hoveredCardOriginal.w) / 2

  local offsets = {}
  for i = 1, n do offsets[i] = 0 end

  local neighborOverlap = C_hover.neighborOverlapPx or 10

  -- == 1. LAYOUT CARDS TO THE LEFT ==
  local numLeft = hoveredIndex - 1
  if numLeft > 0 then
    local leftAreaEnd = hoveredCardX + neighborOverlap
    local leftAreaW = leftAreaEnd - areaX
    local step = (numLeft > 1) and (leftAreaW - cardW) / (numLeft - 1) or 0
    local minVis = C.minVisiblePx or 15
    if step < minVis then step = minVis end

    for i = 1, numLeft do
      local newX = areaX + (i - 1) * step
      offsets[i] = newX - slots[i].x
    end

    -- Correction pass: Prevent inward movement (positive offset for left side)
    local maxInwardShift = 0
    for i = 1, numLeft do
      maxInwardShift = math.max(maxInwardShift, offsets[i])
    end
    if maxInwardShift > 0 then
      for i = 1, numLeft do
        offsets[i] = offsets[i] - maxInwardShift
      end
    end
  end

  -- == 2. LAYOUT CARDS TO THE RIGHT ==
  local numRight = n - hoveredIndex
  if numRight > 0 then
    local rightAreaStart = hoveredCardX + hoveredCardW - neighborOverlap
    local rightAreaW = (areaX + areaW) - rightAreaStart
    local step = (numRight > 1) and (rightAreaW - cardW) / (numRight - 1) or 0
    local minVis = C.minVisiblePx or 15
    if step < minVis then step = minVis end

    for i = 1, numRight do
      local cardIndex = hoveredIndex + i
      local newX = (areaX + areaW - cardW) - (numRight - i) * step
      offsets[cardIndex] = newX - slots[cardIndex].x
    end

    -- Correction pass: Prevent inward movement (negative offset for right side)
    local minInwardShift = 0
    for i = hoveredIndex + 1, n do
      minInwardShift = math.min(minInwardShift, offsets[i])
    end
    if minInwardShift < 0 then
      for i = hoveredIndex + 1, n do
        offsets[i] = offsets[i] - minInwardShift
      end
    end
  end

  return offsets
end

-- Applies hover effects (enlarge, lift) and offsets to a set of slots.
-- Returns a new table of slots.
function LayoutHand.getHoveredLayout(panel, n, hoveredIndex)
  -- 1. Get base layout
  local handSlots = LayoutHand.computeSlots(panel, n)
  if n == 0 then return handSlots end

  -- 2. Get hover offsets for pushing cards apart
  local offsets = LayoutHand.computeHoverOffsets(handSlots, hoveredIndex, panel)

  -- 3. Create the new layout by applying offsets and transformations
  -- Make a deep copy to avoid modifying the original slots table
  local newSlots = deepcopy(handSlots.slots)

  -- Apply x-offsets to all cards
  for i = 1, n do
    newSlots[i].x = newSlots[i].x + (offsets[i] or 0)
  end

  -- 4. Apply transformations to the hovered card
  if hoveredIndex and newSlots[hoveredIndex] then
    local cfgLocal = cfg.handPanel.hover
    local slot = newSlots[hoveredIndex]

    -- Enlarge and re-center
    local originalW = slot.w
    slot.w = slot.w * cfgLocal.scale
    slot.h = slot.h * cfgLocal.scale
    slot.x = slot.x - (slot.w - originalW) / 2

    -- Lift
    slot.y = slot.y - cfgLocal.liftPx

    -- Bring to front (higher z-index)
    slot.z = n + 1
  end

  return { mode = handSlots.mode, slots = newSlots }
end

return LayoutHand
