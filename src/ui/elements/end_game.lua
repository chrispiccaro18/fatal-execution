local cfg       = require("ui.cfg")
local Display   = require("ui.display")
local Click     = require("ui.click")
local GameState = require("game_state.index")
local lg        = love.graphics

local EndGameUI = { isOpen = false }

local function panelRect()
  -- centre the whole panel on the virtual canvas
  local pad = cfg.endGamePanel.pad
  local w   = Display.VIRTUAL_W * 0.6
  local h   = Display.VIRTUAL_H * 0.5
  local x   = (Display.VIRTUAL_W - w) / 2
  local y   = (Display.VIRTUAL_H - h) / 2
  return { x = x, y = y, w = w, h = h, pad = pad }
end

function EndGameUI.draw()
  if not EndGameUI.isOpen then return end
  Click.clear()

  -- Dim the game behind the overlay (drawn in *screen* coords)
  lg.setColor(0, 0, 0, 0.6)
  lg.rectangle("fill", 0, 0, love.graphics.getDimensions())

  -- Main centred panel (virtual coords -> drawn on canvas already)
  local P = panelRect()
  lg.setColor(0.10, 0.10, 0.10, 0.94)
  lg.rectangle("fill", P.x, P.y, P.w, P.h)
  lg.setColor(1, 1, 1)
  lg.rectangle("line", P.x, P.y, P.w, P.h)

  -- “Game Over” / “You Win”
  local msg = love.gameState.turn.phase == "won" and "You Win!" or "Game Over"
  lg.setFont(lg.newFont(cfg.endGamePanel.fontSize))
  lg.printf(msg, P.x, P.y + P.pad, P.w, "center")

  -- Two buttons
  local restart     = cfg.endGamePanel.restartButton
  local quit        = cfg.endGamePanel.quitButton
  local gapY        = 24

  local btnW, btnH  = restart.buttonW, restart.buttonH
  local cx          = P.x + P.w / 2

  -- Restart button (upper)
  local restartRect = {
    x = cx - btnW / 2,
    y = P.y + P.pad + 80,
    w = btnW,
    h = btnH
  }
  Click.addButton("restart", restartRect, "Restart",
                  {
                    bg = restart.bgColor,
                    border = restart.borderColor,
                    text = restart.textColor
                  }, restart.fontSize)

  -- Quit button (below)
  local quitRect = {
    x = cx - btnW / 2,
    y = restartRect.y + btnH + gapY,
    w = btnW,
    h = btnH
  }
  Click.addButton("quit", quitRect, "Quit",
                  {
                    bg = quit.bgColor,
                    border = quit.borderColor,
                    text = quit.textColor
                  }, quit.fontSize)
end

function EndGameUI.mousepressed(px, py, button)
  if button ~= 1 or not EndGameUI.isOpen then return end

  -- convert physical → virtual
  local vx, vy = Display.toVirtual(px, py)
  local hit    = Click.hit(vx, vy)
  if not hit then return end

  if hit.id == "restart" then
    local restartState = GameState.init()
    restartState = GameState.beginTurn(restartState)
    love.gameState = restartState
    EndGameUI.isOpen = false
    Click.clear()
  elseif hit.id == "quit" then
    love.event.quit()
  end
end

return EndGameUI
