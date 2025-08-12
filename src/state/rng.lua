-- rng.lua (pure Lua 5.1 compatible, no bit libs)
local RNG = {}

-- Park–Miller "minimal standard" constants (31-bit)
local M = 2147483647       -- 2^31 - 1 (prime)
local A = 16807            -- multiplier
-- Note: A * (M-1) < 3.6e13  <<  2^53, so double math is exact here.

local function step(seed)
  -- next = (A * seed) mod M, with exact double arithmetic
  return (A * seed) % M
end

-- Simple 31-bit string hash using the same safe multiply
local function hash31(seed, str)
  local h = seed
  for i = 1, #str do
    h = (A * h + string.byte(str, i) + 1) % M
  end
  -- keep in [1, M-1] to avoid the zero state
  if h == 0 then h = 1 end
  return h
end

function RNG.makeStream(rootSeed, label)
  -- normalize user seed to [1, M-1]
  local s = tonumber(rootSeed) or 1
  s = math.floor(math.abs(s)) % (M - 1)
  if s == 0 then s = 1 end

  if label then
    s = hash31(s, tostring(label))
  end

  return { seed = s, idx = 0 }
end

local function nextInt31(state)
  local x = step(state.seed)
  state.seed = x
  state.idx = state.idx + 1
  return x
end

function RNG.next01(state)
  return nextInt31(state) / M
end

function RNG.nextInt(state, lo, hi)
  local r = RNG.next01(state)
  return lo + math.floor(r * (hi - lo + 1))
end

function RNG.pick(state, array)
  if #array == 0 then return nil end
  return array[RNG.nextInt(state, 1, #array)]
end

return RNG
