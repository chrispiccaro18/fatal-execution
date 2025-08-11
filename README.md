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
