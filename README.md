# BattleText for World of Warcraft: Forever

## Installation

Copy the `BattleText` folder into `World of Warcraft/_forever_/Interface/AddOns/` so the game can find `AddOns/BattleText/BattleText.toc`. Restart the client if BattleText is missing from the AddOns list.

Type `/battletext` in game. Change text size, scroll speed and the three area colors while the preview plays. Select **Move text areas**, drag the handles in the game world, then choose **Done moving**. **Reset positions** restores the default locations. Settings are shared across characters.

Use the **Up**, **Down** or **Arc** button beside each area to cycle through its motion. **Arc** bends damage text outward and downward while received healing scrolls straight down. Use **Move text areas** to adjust where the text starts.

## 0.1.0

- Targets Forever 1.60.1, interface 16001.
- Incoming damage and healing received use real values and critical flags when the client supplies them for display. The panel reports when a protected amount could not be shown.
- Outgoing damage is available in the preview. The combat signals evaluated for this release do not reliably attribute a hit to the player.
- The Lua smoke test covered loading, preview samples, moving and resetting areas, crit formatting and the 12-line limit. Live combat, protected values and persistence through a client reload still need an in-game acceptance test.
