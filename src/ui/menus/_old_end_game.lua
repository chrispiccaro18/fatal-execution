local cfg           = require("ui.cfg")
local Display       = require("ui.display")
local Click         = require("ui.click")
local Profiles      = require("profiles")
local RunLogger     = require("profiles.run_logger")
local ActiveProfile = require("profiles.active")
local GameState     = require("game_state.index")
local EventSystem   = require("events.index")
local lg            = love.graphics

local EndGameUI     = { isOpen = false }

EventSystem.subscribe("gameOver", function(phase)
  EndGameUI.isOpen = true
end)

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

  -- Three buttons
  local restart    = cfg.endGamePanel.restartButton
  local quit       = cfg.endGamePanel.quitButton

  local btnW, btnH = restart.buttonW, restart.buttonH
  local cx         = P.x + P.w / 2
  local startY     = P.y + P.pad + 80
  local gapY       = 24

  local buttons    = {
    {
      id = "play_again",
      label = "Play Again",
      y = startY,
      style = restart
    },
    {
      id = "main_menu",
      label = "Main Menu",
      y = startY + (btnH + gapY),
      style = restart
    },
    {
      id = "quit",
      label = "Quit",
      y = startY + 2 * (btnH + gapY),
      style = quit
    }
  }

  for _, btn in ipairs(buttons) do
    local rect = {
      x = cx - btnW / 2,
      y = btn.y,
      w = btnW,
      h = btnH
    }
    Click.addButton(btn.id, rect, btn.label, {
                      bg = btn.style.bgColor,
                      border = btn.style.borderColor,
                      text = btn.style.textColor
                    }, btn.style.fontSize)
  end
end

function EndGameUI.mousepressed(px, py, button)
  if button ~= 1 or not EndGameUI.isOpen then return end

  -- convert physical → virtual
  local vx, vy = Display.toVirtual(px, py)
  local hit    = Click.hit(vx, vy)
  if not hit then return end

  local activeProfileIndex = ActiveProfile.get()

  if hit.id == "play_again" then
    local seed = os.time()
    local restartState = GameState.init(seed)
    RunLogger.init(activeProfileIndex, restartState.seed)
    -- Profiles.setCurrentRun(activeProfileIndex, restartState)
    love.gameState = restartState
    restartState = GameState.beginTurn(restartState)
    EndGameUI.isOpen = false
    Click.clear()
  elseif hit.id == "main_menu" then
    Profiles.clearCurrentRun(activeProfileIndex)
    EndGameUI.isOpen = false
    Click.clear()
    CurrentScreen = "start"
  elseif hit.id == "quit" then
    Profiles.clearCurrentRun(activeProfileIndex)
    love.event.quit()
  end
  EndGameUI.isOpen = false
end

return EndGameUI
