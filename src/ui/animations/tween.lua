local Const = require("const")
local General = require("util.general")
local TWEENS = Const.UI.TWEENS

local Tween = {}
Tween.__index = Tween

-- ---------- EASING ----------
local Easing = {
  linear = function(t) return t end,
  easeInQuad = function(t) return t*t end,
  easeOutQuad = function(t) return 1 - (1 - t)*(1 - t) end,
  easeInOutQuad = function(t) return (t < 0.5) and (2*t*t) or (1 - (-2*t+2)^2/2) end,
}
Tween.Easing = Easing

-- ---------- HELPERS ----------
local function lerp(a, b, p) return a + (b - a) * p end

-- Interpolate all numeric keys present in `to` (and optional `from`)
local function blend(from, to, p)
  local out = {}
  for k, vTo in pairs(to) do
    local vFrom = (from and from[k]) or 0
    if type(vTo) == "number" and type(vFrom) == "number" then
      out[k] = lerp(vFrom, vTo, p)
    end
  end
  return out
end

-- If from is a function, call it once at start to resolve dynamic 'from'
local function resolveFrom(spec)
  if type(spec.from) == "function" then
    return spec.from()
  end
  return spec.from
end

-- ---------- CORE ----------
-- spec = {
--   from = {x=..., y=..., w=..., h=..., r=..., alpha=...} | function()->table | nil
--   to   = { ... numeric fields ... }    -- required
--   duration = 0.25,                     -- seconds
--   delay    = 0,                        -- seconds
--   ease     = Tween.Easing.easeOutQuad, -- function(t)->t
--   tag      = "card_fly",               -- arbitrary label
--   id       = <anything>,               -- arbitrary id (e.g. card id)
--   apply    = function(stateTbl) end,   -- optional: mutate a target each frame
--   onComplete = function() end,         -- optional
-- }
function Tween.new(spec)
  assert(spec and spec.to, "Tween.new: spec.to is required")
  local self = setmetatable({}, Tween)
  self._fromResolved = false
  self.from      = nil         -- resolved lazily
  self.to        = spec.to
  self.duration  = spec.duration or 0.25
  self.delay     = spec.delay or 0
  self.ease      = spec.ease or Easing.easeOutQuad
  self.t         = 0           -- elapsed (excludes delay)
  self.d         = self.duration
  self.wait      = self.delay
  self.tag       = spec.tag
  self.id        = spec.id
  self.apply     = spec.apply
  self.onComplete= spec.onComplete
  self._fromSpec = spec.from   -- keep original for lazy resolve
  self.done      = false
  return self
end

function Tween:startIfNeeded()
  if not self._fromResolved then
    self.from = resolveFrom({ from = self._fromSpec }) or {}
    self._fromResolved = true
  end
end

-- Update time. Returns true if finished this frame.
function Tween:update(dt)
  if self.done then return true end
  self:startIfNeeded()

  if self.wait > 0 then
    self.wait = math.max(0, self.wait - dt)
    return false
  end

  self.t = math.min(self.t + dt, self.d)
  local p = (self.d == 0) and 1 or (self.t / self.d)
  local e = self.ease(math.max(0, math.min(1, p)))
  local state = blend(self.from, self.to, e)

  if self.apply then self.apply(state) end

  if self.t >= self.d then
    self.done = true
    if self.apply then self.apply(self.to) end
    if self.onComplete then self.onComplete() end
    return true
  end

  return false
end

-- Sample current interpolated values without applying.
function Tween:sample()
  self:startIfNeeded()
  if self.wait > 0 then return blend(self.from, self.from or {}, 0) end
  local p = (self.d == 0) and 1 or (self.t / self.d)
  local e = self.ease(math.max(0, math.min(1, p)))
  return blend(self.from, self.to, e)
end

function Tween:progress()
  if self.wait > 0 then return 0 end
  return (self.d == 0) and 1 or (self.t / self.d)
end

-- ---------- GROUPS ----------
-- Parallel: update all children each frame, completes when all complete.
local Parallel = {}
Parallel.__index = Parallel

function Tween.parallel(children)
  local self = setmetatable({ children = children or {}, done = false }, Parallel)
  return self
end

function Parallel:update(dt)
  if self.done then return true end
  local allDone = true
  for _, tw in ipairs(self.children) do
    if not tw.done then
      tw:update(dt)
    end
    if not tw.done then allDone = false end
  end
  if allDone then
    self.done = true
    if self.onComplete then self.onComplete() end
  end
  return self.done
end

-- Sequence: run children in order, one after another.
local Sequence = {}
Sequence.__index = Sequence

function Tween.sequence(children)
  local self = setmetatable({ children = children or {}, i = 1, done = false }, Sequence)
  return self
end

function Sequence:update(dt)
  if self.done then return true end

  -- Start processing from the current child
  local currentChild = self.children[self.i]

  -- If there are no more children, the sequence is done.
  if not currentChild then
    self.done = true
    if self.onComplete then self.onComplete() end
    return true
  end

  -- Process the current child.
  -- If it's a function, execute it and move to the next.
  if type(currentChild) == "function" then
    currentChild()
    self.i = self.i + 1
    -- We've done something this frame, so let's try to update the *next* thing immediately.
    -- This recursive call handles multiple callbacks in a single frame without a `while true`.
    -- It's safe because it will always eventually hit a tween or the end of the sequence.
    return self:update(dt)
  else
    -- It's a tween. Update it.
    local finished = currentChild:update(dt)
    if finished then
      self.i = self.i + 1
    end
  end

  -- Check if the entire sequence is now complete.
  if self.i > #self.children then
    self.done = true
    if self.onComplete then self.onComplete() end
    return true
  end

  return false
end

local function findTweenInGroup(group, cardId)
  if group.id == cardId then return group end
  if group.children then
    for _, child in ipairs(group.children) do
      local found = findTweenInGroup(child, cardId)
      if found then return found end
    end
  end
  return nil
end

function Tween.rectForCard(view, cardId)
  -- An active tween targeting this cardId takes precedence.
  for i = #view.active, 1, -1 do
    local tw = view.active[i]
    local found = findTweenInGroup(tw, cardId)
    if found then
      local r = found:sample()
      return r, r.angle or 0
    end
  end

  -- Fallback
  print("[Tween.rectForCard] Falling back to default")
  print("[Tween.rectForCard] CardId:", cardId)
  return { x = 0, y = 0, w = 0, h = 0 }, 0, true
end

local function num(x, fallback) return (type(x) == "number") and x or fallback end

function Tween.makeTween(cardId, fromRect, toRect, duration, delay)
  return {
    kind      = TWEENS.CARD_FLY,
    id        = cardId,
    elapsed   = 0,
    duration  = num(duration, 0.22),
    delay     = num(delay, 0.00),

    from      = { x = fromRect.x, y = fromRect.y, w = fromRect.w, h = fromRect.h },
    to        = { x = toRect.x, y = toRect.y, w = toRect.w, h = toRect.h },

    -- optional angle tween (used by reflow/fan)
    fromAngle = num(fromRect.angle, 0),
    toAngle   = num(toRect.angle, 0),
  }
end

return Tween
