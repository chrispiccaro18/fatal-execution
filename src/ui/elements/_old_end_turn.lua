local cfg = require("ui.cfg")
local lg   = love.graphics
local Click = require("ui.click")

local EndTurnUI = {}

function EndTurnUI.drawEndTurnButton(panelRect)
  local C = cfg.endTurnPanel

  local r = {
    x = panelRect.x + (panelRect.w - C.buttonW)/2,
    y = panelRect.y + (panelRect.h - C.buttonH)/2,
    w = C.buttonW,
    h = C.buttonH,
  }

  lg.setColor(0,0.6,0.1)
  lg.rectangle("fill", r.x, r.y, r.w, r.h)
  lg.setColor(1,1,1)
  lg.rectangle("line", r.x, r.y, r.w, r.h)
  lg.setFont(lg.newFont(C.fontSize))
  lg.printf("END TURN", r.x, r.y+14, r.w, "center")

  Click.register("endTurn", r)
end

return EndTurnUI
