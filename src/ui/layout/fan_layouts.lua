-- This file defines the visual properties of a fanned hand layout.
--
-- `width_factor`: The total width of the hand, as a multiple of card width.
-- `cards`: A list of definitions for each card in the hand.
--   `angle`: The rotation of the card in degrees.
--   `y_offset`: How many pixels to push the card down. A positive value moves it down.
--
-- `hover_modifiers`: Defines how unhovered cards should be pushed away from the
-- hovered card, based on their distance from it.
--   `x_offset`: Horizontal push away from the hovered card.
--   `y_offset`: Vertical push (positive is down).
--   `angle_offset`: Degrees to add to the card's base angle. A positive value
--                   rotates the card clockwise.

return {
  hover_modifiers = {
    -- For immediate neighbors (distance = 1)
    [1] = { x_offset = 55, y_offset = 5, angle_offset = 0 },
    -- For cards 2 away
    [2] = { x_offset = 40, y_offset = 2, angle_offset = 0 },
    -- For cards 3 away
    [3] = { x_offset = 25, y_offset = 0, angle_offset = 0 },
    -- For cards 4+ away
    [4] = { x_offset = 15, y_offset = 0, angle_offset = 0 },
  },

  [1] = {
    width_factor = 1,
    cards = {
      { angle = 0, y_offset = 0 },
    }
  },
  [2] = {
    width_factor = 1.6,
    cards = {
      { angle = -4, y_offset = 2 },
      { angle = 4, y_offset = 2 },
    }
  },
  [3] = {
    width_factor = 2.2,
    cards = {
      { angle = -6, y_offset = 6 },
      { angle = 0, y_offset = 0 },
      { angle = 6, y_offset = 6 },
    }
  },
  [4] = {
    width_factor = 2.8,
    cards = {
      { angle = -9, y_offset = 12 },
      { angle = -3, y_offset = 1 },
      { angle = 3, y_offset = 1 },
      { angle = 9, y_offset = 12 },
    }
  },
  [5] = {
    width_factor = 3.4,
    cards = {
      { angle = -12, y_offset = 20 },
      { angle = -6, y_offset = 6 },
      { angle = 0, y_offset = 0 },
      { angle = 6, y_offset = 6 },
      { angle = 12, y_offset = 20 },
    }
  },
  [6] = {
    width_factor = 4.0,
    cards = {
      { angle = -14, y_offset = 28 },
      { angle = -8, y_offset = 10 },
      { angle = -2, y_offset = 0 },
      { angle = 2, y_offset = 0 },
      { angle = 8, y_offset = 10 },
      { angle = 14, y_offset = 28 },
    }
  },
  [7] = {
    width_factor = 4.6,
    cards = {
      { angle = -16, y_offset = 36 },
      { angle = -11, y_offset = 18 },
      { angle = -5, y_offset = 4 },
      { angle = 0, y_offset = 0 },
      { angle = 5, y_offset = 4 },
      { angle = 11, y_offset = 18 },
      { angle = 16, y_offset = 36 },
    }
  },
  [8] = {
    width_factor = 5.2,
    cards = {
      { angle = -18, y_offset = 45 },
      { angle = -13, y_offset = 24 },
      { angle = -8, y_offset = 10 },
      { angle = -3, y_offset = 1 },
      { angle = 3, y_offset = 1 },
      { angle = 8, y_offset = 10 },
      { angle = 13, y_offset = 24 },
      { angle = 18, y_offset = 45 },
    }
  },
  [9] = {
    width_factor = 5.8,
    cards = {
      { angle = -20, y_offset = 55 },
      { angle = -15, y_offset = 30 },
      { angle = -10, y_offset = 15 },
      { angle = -5, y_offset = 4 },
      { angle = 0, y_offset = 0 },
      { angle = 5, y_offset = 4 },
      { angle = 10, y_offset = 15 },
      { angle = 15, y_offset = 30 },
      { angle = 20, y_offset = 55 },
    }
  },
  [10] = {
    width_factor = 6.4,
    cards = {
      { angle = -22, y_offset = 70 },
      { angle = -17, y_offset = 40 },
      { angle = -12, y_offset = 20 },
      { angle = -7, y_offset = 8 },
      { angle = -2, y_offset = 0 },
      { angle = 2, y_offset = 0 },
      { angle = 7, y_offset = 8 },
      { angle = 12, y_offset = 20 },
      { angle = 17, y_offset = 40 },
      { angle = 22, y_offset = 70 },
    }
  },
}
