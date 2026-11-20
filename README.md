# BattleText for World of Warcraft: Forever

BattleText is a scrolling combat text addon by **OberstNox**. It shows incoming damage, healing, XP, loot and combat status in configurable areas around your character.

## Installation

1. Copy the `BattleText` folder into `World of Warcraft/_forever_/Interface/AddOns/`. The manifest should be at `AddOns/BattleText/BattleText.toc`.
2. Start WoW: Forever and enable **BattleText** in the AddOns list.
3. On first login, the welcome guide explains BattleText and lets you keep or hide WoW's other floating combat text.
4. Type `/battletext`, click the minimap button, or open **Options → AddOns → BattleText** to return to the dashboard.

## Settings

- **General** controls default text size, scroll speed, critical hit pauses and the minimum damage and healing amount. In **Interface**, **Show only player hits** enables WoW's damage numbers and turns off its pet damage numbers. You can also show the minimap shortcut, hide other WoW combat text or restore the settings BattleText changed. These choices apply across profiles.
- **Text Areas** controls visibility, movement, color and text size for each area. Use **Move text areas** to drag them into place, **Circle: On/Off** to switch the path for incoming damage, and **Reset positions** to restore the default locations.
- **Profiles** saves individual layouts and lets each character select a profile. Several characters can use the same profile.
- **Help** reopens the welcome guide and changelog.

## Combat data

WoW displays your outgoing damage above the target in its own combat text. Forever's target damage events provide damage received by the target without identifying the attacker. BattleText uses player events for incoming combat text. The availability of amounts and outcomes depends on the combat events supplied by Forever.

Use `/battletext test` to show samples in enabled areas.

## Changelog

### 1.0

Initial release for WoW: Forever. Includes customizable scrolling text, movable areas, an optional circle path for incoming damage, character profile selection, a minimap shortcut and a first-login guide.

## License

[MIT](LICENSE)
