local Const = require("const")
local cfg = require("ui.cfg")

local MODE = Const.UI.HAND_LAYOUT_MODE

local math_min, math_max, abs = math.min, math.max, math.abs
local General = require("util.general")
local deepcopy = require("util.deepcopy")
local FanLayouts = require("ui.layout.fan_layouts")
local clamp = General.clamp
local rad = General.rad

local LayoutHand = {}


-- returns { mode="spaced"|"overlap"|"fan", slots={ {x,y,w,h,angle,z}, ... } }
function LayoutHand.computeSlots(panel, n)
  local C = cfg.handPanel
  local pad = C.pad
  local cardW = C.cardW
  local cardH = C.cardH

  local areaX = panel.x + pad
  local areaY = panel.y + pad
  local areaW = panel.w - pad * 2
  local areaH = panel.h - pad * 2

  local slots = {}
  if n == 0 then return { mode = MODE.SPACED, slots = slots } end

  -- If fan is enabled, it's the primary layout mode.
  local fanCfg = C.fan
  if fanCfg.enabled then
    if n == 1 then
      slots[1] = { x = areaX + (areaW - cardW) / 2, y = areaY, w = cardW, h = cardH, angle = 0, z = 1 }
      return { mode = MODE.FAN, slots = slots }
    end

    -- FAN LAYOUT (Data-driven)
    local layoutConfig = FanLayouts[math.min(n, #FanLayouts)] -- Clamp to max defined size
    local widthFactor = layoutConfig.width_factor or n
    local cardData = layoutConfig.cards

    -- Calculate the effective width for the hand, which determines overlap.
    local effectiveW = cardW * widthFactor
    -- Don't allow the hand to be wider than the available area.
    effectiveW = math.min(effectiveW, areaW)

    local startX = areaX + (areaW - effectiveW) / 2

    for i = 1, n do
      local data = cardData[i]
      local t = (n > 1) and ((i - 1) / (n - 1)) or 0.5 -- interpolation factor [0,1]

      -- Distribute cards within the effective width
      local x = startX + t * (effectiveW - cardW)
      local y = areaY + data.y_offset

      slots[i] = { x = x, y = y, w = cardW, h = cardH, angle = data.angle, z = i }
    end

    return { mode = MODE.FAN, slots = slots }
  end

  -- LINEAR LAYOUT (Fallback if fan is disabled)
  if n == 1 then
    slots[1] = { x = areaX + (areaW - cardW) / 2, y = areaY, w = cardW, h = cardH, angle = 0, z = 1 }
    return { mode = MODE.SPACED, slots = slots }
  end

  -- Try SPACED linear
  local maxSpacing = C.maxSpacingX
  local totalWSpaced = n * cardW + (n - 1) * maxSpacing
  if totalWSpaced <= areaW then
    local startX = areaX + (areaW - totalWSpaced) / 2
    for i = 1, n do
      local x = startX + (i - 1) * (cardW + maxSpacing)
      slots[i] = { x = x, y = areaY, w = cardW, h = cardH, angle = 0, z = i }
    end
    return { mode = MODE.SPACED, slots = slots }
  end

  -- Fallback to OVERLAP linear
  local minVis = clamp(C.minVisiblePx, 8, cardW)
  local step = (areaW - cardW) / (n - 1)
  if step < minVis then step = minVis end -- Use hard overlap if gentle is too much

  local totalW = cardW + (n - 1) * step
  local startX = areaX + (areaW - totalW) / 2
  for i = 1, n do
    local x = startX + (i - 1) * step
    slots[i] = { x = x, y = areaY, w = cardW, h = cardH, angle = 0, z = i }
  end
  return { mode = MODE.OVERLAP, slots = slots }
end

-- Computes the layout for a fanned hand with a hovered card.
local function computeFanHoverLayout(panel, n, hoveredIndex, baseSlots)
  local newSlots = deepcopy(baseSlots)
  local C = cfg.handPanel
  local C_hover = C.hover

  -- 1. Transform the hovered card first
  local hoveredSlot = newSlots[hoveredIndex]
  hoveredSlot.angle = 0
  hoveredSlot.y = hoveredSlot.y - C_hover.liftPx
  hoveredSlot.z = n + 1
  -- No scaling, the lift and straightening is enough emphasis

  -- 2. Create two new sub-panels on either side of the hovered card
  local pad = C.pad or 0
  local areaX = panel.x + pad
  local areaW = panel.w - pad * 2

  local leftPanel = {
    x = areaX,
    y = panel.y,
    w = hoveredSlot.x - areaX,
    h = panel.h,
  }
  local rightPanel = {
    x = hoveredSlot.x + hoveredSlot.w,
    y = panel.y,
    w = (areaX + areaW) - (hoveredSlot.x + hoveredSlot.w),
    h = panel.h,
  }

  -- 3. Recursively compute new fans for the left and right sides
  local numLeft = hoveredIndex - 1
  if numLeft > 0 then
    local leftLayout = LayoutHand.computeSlots(leftPanel, numLeft)
    for i = 1, numLeft do
      newSlots[i] = leftLayout.slots[i]
    end
  end

  local numRight = n - hoveredIndex
  if numRight > 0 then
    local rightLayout = LayoutHand.computeSlots(rightPanel, numRight)
    for i = 1, numRight do
      newSlots[hoveredIndex + i] = rightLayout.slots[i]
    end
  end

  return { mode = MODE.FAN, slots = newSlots }
end

-- Computes x-axis offsets for a linear hand with a hovered card.
local function computeLinearHoverOffsets(handSlots, hoveredIndex, panel)
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
  local handSlots = LayoutHand.computeSlots(panel, n)
  if not hoveredIndex or n <= 1 then return handSlots end

  if handSlots.mode == MODE.FAN then
    return computeFanHoverLayout(panel, n, hoveredIndex, handSlots.slots)
  end

  -- Default to linear hover logic
  local offsets = computeLinearHoverOffsets(handSlots, hoveredIndex, panel)
  local newSlots = deepcopy(handSlots.slots)

  -- Apply x-offsets to all cards
  for i = 1, n do
    newSlots[i].x = newSlots[i].x + (offsets[i] or 0)
  end

  -- Apply transformations to the hovered card
  if newSlots[hoveredIndex] then
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
