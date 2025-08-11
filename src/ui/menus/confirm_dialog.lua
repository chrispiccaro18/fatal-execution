-- src/ui/confirm_dialog.lua
local Click = require("ui.click")
local cfg   = require("ui.cfg")
local lg    = love.graphics

local ConfirmDialog = {
  isOpen     = false,
  text       = "",
  onConfirm  = nil,
  onCancel   = nil,
  confirmLbl = "Confirm",
  cancelLbl  = "Cancel",
}

-- You can style these in ui.cfg.confirm if you want
local function palette()
  local p = (cfg.confirm or {})
  return {
    panelBg   = (p.panelBg   or {0.10, 0.10, 0.10, 0.95}),
    panelLine = (p.panelLine or {1, 1, 1, 1}),
    dim       = (p.dim       or {0, 0, 0, 0.6}),
    yesBg     = (p.yesBg     or {0.20, 0.60, 0.20, 1}),
    noBg      = (p.noBg      or {0.60, 0.20, 0.20, 1}),
    border    = (p.border    or {1, 1, 1, 1}),
    text      = (p.text      or {1, 1, 1, 1}),
    fontSize  = (p.fontSize  or cfg.fontSizeBig),
  }
end

local function panelRect()
  local sw, sh = lg.getDimensions()
  local w, h = math.min(520, sw * 0.8), math.min(240, sh * 0.6)
  return { x = (sw - w)/2, y = (sh - h)/2, w = w, h = h, pad = 24 }
end

function ConfirmDialog.open(text, onConfirm, onCancel, opts)
  ConfirmDialog.isOpen    = true
  ConfirmDialog.text      = text or ""
  ConfirmDialog.onConfirm = onConfirm
  ConfirmDialog.onCancel  = onCancel
  opts = opts or {}
  ConfirmDialog.confirmLbl = opts.confirmLabel or "Confirm"
  ConfirmDialog.cancelLbl  = opts.cancelLabel  or "Cancel"
end

function ConfirmDialog.close()
  ConfirmDialog.isOpen = false
end

function ConfirmDialog.draw()
  if not ConfirmDialog.isOpen then return end
  local P = panelRect()
  local c = palette()

  -- Dim the world
  lg.setColor(c.dim); lg.rectangle("fill", 0, 0, lg.getDimensions())

  -- Panel
  lg.setColor(c.panelBg);   lg.rectangle("fill", P.x, P.y, P.w, P.h)
  lg.setColor(c.panelLine); lg.rectangle("line", P.x, P.y, P.w, P.h)

  -- Hit layer (only our dialog should receive hits this frame)
  Click.clear()

  -- Title + body
  local fsTitle = math.floor(c.fontSize * 1.1)
  lg.setColor(c.text)
  lg.setFont(lg.newFont(fsTitle))
  -- lg.printf("Confirm", P.x + P.pad, P.y + P.pad, P.w - P.pad*2, "center")

  lg.setFont(lg.newFont(c.fontSize))
  local msg = "Are you sure you want to " .. ConfirmDialog.text .. "?"
  lg.printf(msg, P.x + P.pad, P.y + P.pad + 38, P.w - P.pad*2, "center")

  -- Buttons
  local btnW, btnH, gap = 150, 44, 20
  local cx = P.x + P.w/2
  local y  = P.y + P.h - P.pad - btnH

  local yesRect = { x = cx - gap/2 - btnW, y = y, w = btnW, h = btnH }
  local noRect  = { x = cx + gap/2,        y = y, w = btnW, h = btnH }

  Click.addButton("confirm_yes", yesRect, ConfirmDialog.confirmLbl, {
    bg = c.yesBg, border = c.border, text = {1,1,1,1}
  }, c.fontSize)

  Click.addButton("confirm_no",  noRect,  ConfirmDialog.cancelLbl, {
    bg = c.noBg,  border = c.border, text = {1,1,1,1}
  }, c.fontSize)
end

-- Call from love.mousepressed BEFORE your normal routing when open
function ConfirmDialog.mousepressed(x, y, button)
  if not ConfirmDialog.isOpen or button ~= 1 then return true end
  local hit = Click.hit(x, y)
  if not hit then return true end  -- consume clicks anywhere on the dialog
  if hit.id == "confirm_yes" then
    if ConfirmDialog.onConfirm then ConfirmDialog.onConfirm() end
    ConfirmDialog.close()
    return true
  elseif hit.id == "confirm_no" then
    if ConfirmDialog.onCancel then ConfirmDialog.onCancel() end
    ConfirmDialog.close()
    return true
  end
  return true
end

-- Call from love.keypressed when open
function ConfirmDialog.keypressed(key)
  if not ConfirmDialog.isOpen then return false end
  if key == "return" or key == "kpenter" then
    if ConfirmDialog.onConfirm then ConfirmDialog.onConfirm() end
    ConfirmDialog.close()
    return true
  elseif key == "escape" then
    if ConfirmDialog.onCancel then ConfirmDialog.onCancel() end
    ConfirmDialog.close()
    return true
  end
  return true
end

return ConfirmDialog
