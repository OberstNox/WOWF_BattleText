# BattleText for World of Warcraft: Forever

## Installation

Copy the `BattleText` folder into `World of Warcraft/_forever_/Interface/AddOns/` so the game can find `AddOns/BattleText/BattleText.toc`. Restart the client if BattleText is missing from the AddOns list.

Type `/battletext` to open the dashboard. **General** controls text size, scroll speed, minimum amounts and critical hit pauses. In **Text Areas**, select an area to adjust its appearance. Select **Move text areas**, drag the handles in the game world, then choose **Done moving**. **Reset positions** restores the default locations for the active profile.

Use the movement button to cycle through **Up**, **Down** and **Arc**. **Arc** bends damage text outward and downward while the other areas scroll straight down.

## 0.3.3

- Click the **BattleText** minimap icon to open the dashboard. Drag the button along the minimap edge to reposition it.
- `BattleText-CurseForge.png` is the project logo for CurseForge.

## 0.3.2

- **Text Areas → Circle: On/Off** toggles the circle paths for both damage areas. Turning the layout off restores their previous motions and positions. A circle layout saved in an older version returns to the default upward paths if no previous layout was saved.

## 0.3.1

- **NPC target damage** now works in and out of groups whenever its text area is enabled. The separate group switch has been removed. Target damage can include hits from pets and other players.

## 0.3.0

- **General → Show NPC target damage in groups** lets the selected NPC's damage appear while grouped. This is off by default and saved per profile. NPC target damage can include hits from pets and other players.

## 0.2.9

- Solo target damage retains confirmed NPC target eligibility if the client restricts target checks during the fight. Changing targets clears that eligibility.
- Use `/battletext status` after a fight to see target event counts, enabled state, group state and protected-amount failures.

## 0.2.8

- Live text anchors directly to the game screen when profiles change. Use `/battletext test` to show labeled samples in the active profile's enabled areas and check the in-game display independently of combat events.

## 0.2.7

- **Text Areas** always shows the selected area's size slider. Adjust it directly or choose **Use default** to return that area to the shared **General** size.

## 0.2.6

- The dashboard groups shared settings and filters under **General**, and keeps per-area options separate from the **Screen layout** controls. An area shows its inherited text size until you override it.
- Checkbox labels are clickable. The footer explains when NPC target damage is paused because you are in a group.

## 0.2.5

- Enable **Custom text size** for any area under **Text Areas** to set its size independently. Turn it off to use the shared size under **General**. Custom sizes are saved in the active profile.

## 0.2.4

- The dashboard uses a sidebar, flatter controls and a clear highlight for the selected section, text area and profile. The preview remains visible beside the settings.

## 0.2.3

- **Text Areas → Apply Circle Layout** places incoming damage on the left and NPC target damage on the right. Both follow a downward curve around the center of the screen.
- **Circle Down** can also be chosen individually for either damage area. **Move text areas** lets you adjust the starting points. **Reset positions** restores the starting points for the selected motions.

## 0.2.2

- **NPC target damage** can display hits on your selected attackable NPC while playing solo. Forever reports damage taken by the NPC without identifying the attacker, so hits from pets or other players on the same target can appear. The display depends on which events and amounts the client provides.

## 0.2.1

- The dashboard preview shows one area at a time so samples stay readable. On **Text Areas**, it previews the selected area immediately. **Move text areas** still previews the full layout in the game world.

## 0.2.0

- **Profiles** lets you select a profile, start with defaults, copy the active profile, rename it or delete it. Each character remembers its selection. Characters sharing a profile also share edits to that profile.
- Existing settings become **Default**. Deleting a named profile switches characters using it to **Default**.
- The live preview stays visible while you edit settings or switch profiles.

## 0.1.7

- **Move text areas** now plays sample messages at their actual screen positions. The samples follow the handles while you drag and disappear when you finish moving.

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
