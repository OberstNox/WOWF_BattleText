# BattleText for World of Warcraft: Forever

## Installation

Copy the `BattleText` folder into `World of Warcraft/_forever_/Interface/AddOns/` so the game can find `AddOns/BattleText/BattleText.toc`. Restart the client if BattleText is missing from the AddOns list.

Type `/battletext` in game. Change text size, scroll speed and area colors while the preview plays. Select **Move text areas**, drag the handles in the game world, then choose **Done moving**. **Reset positions** restores the default locations. Settings are shared across characters.

Use the **Up**, **Down** or **Arc** button beside each area to cycle through its motion. **Arc** bends damage text outward and downward while healing and XP scroll straight down. Use **Move text areas** to adjust where the text starts.

## 0.1.6

- Enable **Hold critical hits and heals** to pause crits for 0.6 seconds before they scroll. The option applies to live text and the preview and starts off by default.

## 0.1.5

- **Combat status** displays **Combat started** and **Combat ended** as the player enters and leaves combat. The area can be moved, recolored and turned off, and both messages are shown in the preview.

## 0.1.4

- **Loot received** shows your own item loot messages in a dedicated area. The game supplies the localized item message and any stack count. You can move the area, change its color and movement, or turn it off.

## 0.1.3

- **XP gained** displays the client's XP gain messages in a dedicated area above the character by default. It has its own visibility, color, movement and position settings. The preview includes a sample XP message, and the damage and healing minimum does not apply to XP.

## 0.1.2

- **Minimum amount** hides damage and healing below the selected value in live text and preview. Set it to 0 to show all amounts. Outcomes such as Dodge stay visible. Protected values use the display behavior allowed by the client because BattleText cannot compare them.

## 0.1.1

- Incoming combat text shows reported outcomes such as dodge, parry and absorb. Partial blocks, absorbs and resists include the damage taken when available.

## 0.1.0

- Targets Forever 1.60.1, interface 16001.
- Incoming damage and healing received use real values and critical flags when the client supplies them for display. The panel reports when a protected amount could not be shown.
- Outgoing damage is available in the preview. The combat signals evaluated for this release do not reliably attribute a hit to the player.
- The Lua smoke test covered loading, preview samples, moving and resetting areas, crit formatting and the 12-line limit. Live combat, protected values and persistence through a client reload still need an in-game acceptance test.
