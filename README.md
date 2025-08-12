# Shallow Copy vs Deep Copy in Game Models

## 📌 Definitions
- **Shallow copy** — clones the **top level** of a table; child tables are still **references**.
- **Deep copy** — recursively clones all nested tables, producing a fully independent structure.

---

## ✅ When to Use Shallow Copy (`util.copy`)
Use when:
- You only need to protect the **top-level table** from mutation.
- Nested tables are **immutable** or intentionally shared.
- Example: updating a deck list, replacing the entire `deck` table.

**Example:**
```lua
local copy = require("util.copy")
local newDeck = copy(oldDeck)
table.insert(newDeck, card)
return newDeck

# Display Scale Checklist

This checklist helps ensure `Display.scale` is consistently applied throughout the UI.
Run through it before implementing scale-aware fonts or dynamic UI scaling.

---

## 1. **Canvas Setup**
- [ ] **Canvas creation**:
  - Confirm `Display.canvas` is created at virtual resolution (`Display.VIRTUAL_W`, `Display.VIRTUAL_H`).
  - Confirm `Display.scale` is applied when drawing the canvas to the screen:
    ```lua
    lg.translate(Display.offsetX, Display.offsetY)
    lg.scale(Display.scale, Display.scale)
    lg.draw(Display.canvas, 0, 0)
    ```

---

## 2. **Layout Calculation**
- [ ] All layout math (`ui/layout.lua`, `relayout()`) should:
  - Use **virtual width/height** (`Display.VIRTUAL_W`, `Display.VIRTUAL_H`) for positioning.
  - **Never** directly reference `love.graphics.getWidth()` / `getHeight()` except when updating `Display.scale` and `Display.offsetX/Y`.

---

## 3. **Fonts**
- [ ] Fonts in `ui/cfg.lua` are currently fixed pixel sizes.
- [ ] Delay scaling fonts until `Display.scale` is correct everywhere.
- [ ] When ready:
  ```lua
  cfg.fonts.big = love.graphics.newFont(math.floor(18 * Display.scale))

