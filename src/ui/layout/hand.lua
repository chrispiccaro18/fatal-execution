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
  local mode  = handSlots.mode
  local slots = handSlots.slots
  local n     = #slots
  if not hoveredIndex or n <= 1 then return {} end
  if mode == MODE.SPACED then return {} end -- no need to spread when fully spaced

  local C          = cfg.handPanel
  local cardW      = C.cardW
  local maxSpacing = C.maxSpacingX

  -- compute available area width (same logic as computeSlots)
  local pad        = C.pad or 0
  local areaW      = (panel and panel.w or 0) - pad * 2
  if areaW <= 0 then areaW = slots[#slots].x - slots[1].x + cardW end

  -- uniform baseline step for non-hovered cards (make overlaps equal)
  local minVis = clamp(C.minVisiblePx, 8, cardW)
  local uniformStep = (n > 1) and ((areaW - cardW) / (n - 1)) or cardW
  if uniformStep < minVis then uniformStep = minVis end

  -- local step around hovered index (fallback to uniformStep)
  local function stepAt(i)
    if i < 1 or i >= n then
      return uniformStep
    end
    -- prefer uniform baseline instead of raw slot spacing to keep non-hovered equal
    return uniformStep
  end

  local baseLeft  = stepAt(hoveredIndex - 1)
  local baseRight = stepAt(hoveredIndex)
  local targetGap = cardW + maxSpacing                 -- make neighbors adjacent to hovered
  local deltaL    = math_max(0, targetGap - baseLeft)  -- extra gap needed on the left side
  local deltaR    = math_max(0, targetGap - baseRight) -- extra gap needed on the right side
  local delta     = math_max(deltaL, deltaR)
  if delta <= 0 then return {} end

  -- Decay: larger hands → stronger falloff (affects fewer distant cards)
  local baseDecay = (mode == MODE.FAN) and 0.55 or 0.60
  local decay     = clamp(baseDecay - 0.02 * (n - 5), 0.25, 0.70)

  -- helper to build offsets for a given delta
  local function buildOffsets(curDelta)
    local offsets = {}
    for i = 1, n do offsets[i] = 0 end

    -- Push right side outwards
    for i = hoveredIndex + 1, n do
      local dist = i - hoveredIndex
      offsets[i] = offsets[i] + (curDelta * (decay ^ (dist - 1)))
    end
    -- Push left side outwards
    for i = hoveredIndex - 1, 1, -1 do
      local dist = hoveredIndex - i
      offsets[i] = offsets[i] - (curDelta * (decay ^ (dist - 1)))
    end

    -- Keep the overall center stable
    local sum = 0
    for i = 1, n do sum = sum + offsets[i] end
    local centerShift = sum / n
    for i = 1, n do offsets[i] = offsets[i] - centerShift end

    return offsets
  end

  -- try the computed delta; if it would make any adjacent visible strip < 10% cardW,
  -- progressively reduce delta (this effectively underlaps the hovered card).
  local minAllowedVisible = 0.10 * cardW
  local tryDelta = delta
  local offsets = buildOffsets(tryDelta)
  local function minVisibleBetween(offsets)
    local minV = math.huge
    for i = 1, n - 1 do
      local leftPos  = slots[i].x + offsets[i]
      local rightPos = slots[i + 1].x + offsets[i + 1]
      local visible  = rightPos - leftPos
      if visible < minV then minV = visible end
    end
    return minV
  end

  local minV = minVisibleBetween(offsets)
  local iter = 0
  while minV < minAllowedVisible and tryDelta > 1 and iter < 6 do
    tryDelta = tryDelta * 0.5
    offsets = buildOffsets(tryDelta)
    minV = minVisibleBetween(offsets)
    iter = iter + 1
  end

  -- If after reduction still too small, just return offsets that minimize disruption (already computed)
  -- Clamp offsets so cards don't escape the panel bounds (panel optional).
  if panel and panel.w and slots and #slots > 0 then
    for i = 1, n do
      local slot = slots[i]
      if slot then
        local minOffset = (panel.x or 0) - slot.x
        local maxOffset = (panel.x or 0) + (panel.w or 0) - slot.x - slot.w
        offsets[i] = clamp(offsets[i], minOffset, maxOffset)
      end
    end
  end

  return offsets
end

return LayoutHand
