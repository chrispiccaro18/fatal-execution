local Const = require("const")

return {
  [Const.SHIPS.BASE_SHIP.ID] = {
    systems = {
      { id = Const.SYSTEMS.POWER.ID },
      { id = Const.SYSTEMS.REACTOR.ID },
      { id = Const.SYSTEMS.THRUSTERS.ID },
    },
    threats = {
      { id = Const.THREATS.IMPACT_IMMINENT.ID },
    },
    destructor_deck = Const.DESTRUCTOR_DECKS.EMPTY,
  }
}
