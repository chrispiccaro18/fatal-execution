local RNG = {}

local function xor(a, b)
  local result = 0
  local bit = 1
  while a > 0 or b > 0 do
    local a_bit = a % 2
    local b_bit = b % 2
    if a_bit ~= b_bit then
      result = result + bit
    end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
    bit = bit * 2
  end
  return result
end

local function hash32(seed, label)
  -- Tiny string hash
  local h = seed or 0x9E3779B1
  for i = 1, #label do
    h = (((xor(h, string.byte(label, i))) * 0x45d9f3b) % 0x80000000)
  end
  return h
end

function RNG.makeStream(rootSeed, label)
  return { seed = ((rootSeed + hash32(rootSeed, label)) % 0x80000000), idx = 0 }
end

-- super simple LCG; swap later for xoshiro?
local A = 1103515245
local C = 12345
local M = 2^31

local function step(s)
  s.seed = (A * s.seed + C) % M
  s.idx = s.idx + 1
  return s.seed
end

function RNG.next01(s) return step(s) / (M - 1) end

-- helpers for ints and array picks
function RNG.nextInt(s, lo, hi)
  local r = RNG.next01(s)
  return lo + math.floor(r * (hi - lo + 1))
end

function RNG.pick(s, array)
  if #array == 0 then return nil end
  return array[RNG.nextInt(s, 1, #array)]
end

return RNG