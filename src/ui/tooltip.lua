local Tooltip = {
  text = nil,
  visible = false,
  timer = 0,
  delay = 0.4,
  x = 0,
  y = 0
}

function Tooltip:update(dt, isHovered, text)
  local mx, my = love.mouse.getPosition()

  if isHovered then
    if not self.visible or self.text ~= text then
      self.timer = 0
      self.visible = false
    else
      self.timer = self.timer + dt
      if self.timer >= self.delay then
        self.text = text
        self.x = mx
        self.y = my
        self.visible = true
      end
    end
  else
    self.visible = false
    self.timer = 0
  end
end

function Tooltip:draw()
  if not self.visible or not self.text then return end

  local padding = 6
  local width = 160
  local _, lineCount = self.text:gsub("\n", "")
  local height = (lineCount + 1) * love.graphics.getFont():getHeight() + padding * 2

  local screenW, screenH = love.graphics.getDimensions()
  local mx, my = self.x, self.y
  if mx + width + 12 > screenW then mx = screenW - width - 12 end
  if my + height + 12 > screenH then my = screenH - height - 12 end

  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.rectangle("fill", mx + 10, my + 10, width, height, 4, 4)

  love.graphics.setColor(1, 1, 1)
  love.graphics.printf(self.text, mx + 10 + padding, my + 10 + padding, width - padding * 2)
end

return Tooltip

-- call Tooltip:update(...) and Tooltip:draw() anywhere
-- use in main:
-- local Tooltip = require("tooltip")

-- function love.load()
--   love.window.setMode(640, 360)
--   font = love.graphics.newFont(12)
--   love.graphics.setFont(font)

--   card = {
--     x = 100,
--     y = 120,
--     w = 64,
--     h = 96,
--     tooltip = "Play: Restore 1\nDiscard: +1 Threat",
--     hovered = false
--   }
-- end

-- function love.update(dt)
--   local mx, my = love.mouse.getPosition()
--   local wasHovered = card.hovered
--   card.hovered = mx > card.x and mx < card.x + card.w and my > card.y and my < card.y + card.h

--   Tooltip:update(dt, card.hovered, card.tooltip)
-- end

-- function love.draw()
--   love.graphics.setColor(0.2, 0.5, 0.9)
--   love.graphics.rectangle("fill", card.x, card.y, card.w, card.h, 4, 4)

--   Tooltip:draw()
-- end
