-- This file defines the visual properties of a fanned hand layout.
-- By hardcoding these values, we get precise control over the look and feel.
--
-- `width_factor`: The total width of the hand, as a multiple of card width.
--                 A factor of `n` means no overlap. A smaller factor creates overlap.
-- `cards`: A list of definitions for each card in the hand.
--   `angle`: The rotation of the card in degrees.
--   `y_offset`: How many pixels to lift the card. A negative value lifts it up.

return {
  [1] = {
    width_factor = 1,
    cards = {
      { angle = 0, y_offset = 0 },
    }
  },
  [2] = {
    width_factor = 1.6,
    cards = {
      { angle = -4, y_offset = 0 },
      { angle = 4, y_offset = 0 },
    }
  },
  [3] = {
    width_factor = 2.2,
    cards = {
      { angle = -6, y_offset = 0 },
      { angle = 0, y_offset = -5 },
      { angle = 6, y_offset = 0 },
    }
  },
  [4] = {
    width_factor = 2.8,
    cards = {
      { angle = -9, y_offset = 0 },
      { angle = -3, y_offset = -6 },
      { angle = 3, y_offset = -6 },
      { angle = 9, y_offset = 0 },
    }
  },
  [5] = {
    width_factor = 3.4,
    cards = {
      { angle = -12, y_offset = 0 },
      { angle = -6, y_offset = -7 },
      { angle = 0, y_offset = -10 },
      { angle = 6, y_offset = -7 },
      { angle = 12, y_offset = 0 },
    }
  },
  [6] = {
    width_factor = 4.0,
    cards = {
      { angle = -14, y_offset = 0 },
      { angle = -8, y_offset = -8 },
      { angle = -2, y_offset = -12 },
      { angle = 2, y_offset = -12 },
      { angle = 8, y_offset = -8 },
      { angle = 14, y_offset = 0 },
    }
  },
  [7] = {
    width_factor = 4.6,
    cards = {
      { angle = -16, y_offset = 0 },
      { angle = -11, y_offset = -8 },
      { angle = -5, y_offset = -12 },
      { angle = 0, y_offset = -14 },
      { angle = 5, y_offset = -12 },
      { angle = 11, y_offset = -8 },
      { angle = 16, y_offset = 0 },
    }
  },
  [8] = {
    width_factor = 5.2,
    cards = {
      { angle = -18, y_offset = 0 },
      { angle = -13, y_offset = -8 },
      { angle = -8, y_offset = -12 },
      { angle = -3, y_offset = -15 },
      { angle = 3, y_offset = -15 },
      { angle = 8, y_offset = -12 },
      { angle = 13, y_offset = -8 },
      { angle = 18, y_offset = 0 },
    }
  },
  [9] = {
    width_factor = 5.8,
    cards = {
      { angle = -20, y_offset = 0 },
      { angle = -15, y_offset = -8 },
      { angle = -10, y_offset = -12 },
      { angle = -5, y_offset = -15 },
      { angle = 0, y_offset = -17 },
      { angle = 5, y_offset = -15 },
      { angle = 10, y_offset = -12 },
      { angle = 15, y_offset = -8 },
      { angle = 20, y_offset = 0 },
    }
  },
  [10] = {
    width_factor = 6.4,
    cards = {
      { angle = -22, y_offset = 0 },
      { angle = -17, y_offset = -8 },
      { angle = -12, y_offset = -12 },
      { angle = -7, y_offset = -15 },
      { angle = -2, y_offset = -18 },
      { angle = 2, y_offset = -18 },
      { angle = 7, y_offset = -15 },
      { angle = 12, y_offset = -12 },
      { angle = 17, y_offset = -8 },
      { angle = 22, y_offset = 0 },
    }
  },
}