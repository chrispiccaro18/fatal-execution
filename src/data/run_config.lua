-- Build a normalized RunConfig from user/preset choices.
-- !!!Keep this small, explicit, and serializable!!!

-- NOTES
-- deckSpec shapes supported:
--   { kind="preset", id="starter_v1", shuffle=true|false }
--   { kind="custom_list", entries={ {id="...", count=1}, ... }, shuffle=true|false }
--   { kind="custom_pool",
--     base={ {id="...", count=1}, ... },
--     pool={ {id="...", weight=1}, ... },
--     poolCount=3, allowDuplicates=true|false, shuffle=true|false
--   }
local Const = require("const")
local copy = require("util.copy")

local DEFAULTS = {
  shipPresetId = Const.SHIPS.BASE_SHIP.ID,
  deckSpec     = { kind = Const.DECK_SPEC.PRESET, id = Const.DECKS.STARTER, shuffle = true },
  difficulty   = "normal",   -- "easy" | "normal" | "hard" | etc.
  handSize     = 4,
  mods         = {},         -- e.g., { "ironman", "permashuffle" }
}

local ALLOWED_KINDS = {
  preset       = true,
  custom_list  = true,
  custom_pool  = true,
}

local function normalizeDeckSpec(spec)
  spec = spec or DEFAULTS.deckSpec
  if type(spec) ~= "table" or not ALLOWED_KINDS[spec.kind or ""] then
    return copy(DEFAULTS.deckSpec)
  end

  local kind = spec.kind

  if kind == Const.DECK_SPEC.PRESET then
    return {
      kind    = Const.DECK_SPEC.PRESET,
      id      = spec.id or DEFAULTS.deckSpec.id,
      shuffle = (spec.shuffle ~= false), -- default true
    }

  elseif kind == Const.DECK_SPEC.CUSTOM_LIST then
    -- entries: { {id, count}, ... }
    local out = {
      kind    = Const.DECK_SPEC.CUSTOM_LIST,
      entries = {},
      shuffle = (spec.shuffle == true), -- default false unless asked
    }
    if type(spec.entries) == "table" then
      for _, e in ipairs(spec.entries) do
        if e and e.id then
          out.entries[#out.entries+1] = { id = e.id, count = tonumber(e.count) or 1 }
        end
      end
    end
    return out

  elseif kind == Const.DECK_SPEC.CUSTOM_POOL then
    -- base: locked cards, pool: weighted picks into poolCount
    local out = {
      kind            = Const.DECK_SPEC.CUSTOM_POOL,
      base            = {},
      pool            = {},
      poolCount       = tonumber(spec.poolCount) or 0,
      allowDuplicates = (spec.allowDuplicates ~= false), -- default true
      shuffle         = (spec.shuffle ~= false),         -- default true
    }
    if type(spec.base) == "table" then
      for _, e in ipairs(spec.base) do
        if e and e.id then
          out.base[#out.base+1] = { id = e.id, count = tonumber(e.count) or 1 }
        end
      end
    end
    if type(spec.pool) == "table" then
      for _, p in ipairs(spec.pool) do
        if p and p.id then
          out.pool[#out.pool+1] = { id = p.id, weight = tonumber(p.weight) or 1 }
        end
      end
    end
    return out
  end

  -- Fallback
  return copy(DEFAULTS.deckSpec)
end

local function normalizeDifficulty(diff)
  if type(diff) ~= "string" or diff == "" then return DEFAULTS.difficulty end
  -- You can clamp to a list here if you want strictness.
  return diff
end

local function normalizeHandSize(n)
  n = tonumber(n) or DEFAULTS.handSize
  if n < 1 then n = 1 end
  if n > 10 then n = 10 end
  return n
end

local function normalizeMods(mods)
  if type(mods) ~= "table" then return {} end
  local out = {}
  for i,m in ipairs(mods) do
    if type(m) == "string" and m ~= "" then out[#out+1] = m end
  end
  return out
end

-- PUBLIC: build and normalize a RunConfig
local function makeRunConfig(opts)
  opts = opts or {}

  return {
    shipPresetId = opts.shipPresetId or DEFAULTS.shipPresetId,

    deckSpec     = normalizeDeckSpec(opts.deckSpec),

    difficulty   = normalizeDifficulty(opts.difficulty),
    handSize     = normalizeHandSize(opts.handSize),

    mods         = normalizeMods(opts.mods),
  }
end

return makeRunConfig
