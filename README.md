# BattleText for World of Warcraft: Forever

BattleText is a scrolling combat text addon by **OberstNox**. It shows damage, healing, XP, loot and combat status in configurable areas around your character.

## Installation

1. Copy the `BattleText` folder into `World of Warcraft/_forever_/Interface/AddOns/`. The manifest should be at `AddOns/BattleText/BattleText.toc`.
2. Start WoW: Forever and enable **BattleText** in the AddOns list.
3. On first login, the welcome guide explains BattleText and lets you keep or hide WoW's own floating combat text.
4. Type `/battletext`, click the minimap button, or open **Options → AddOns → BattleText** to return to the dashboard.

## Settings

- **General** controls default text size, scroll speed, critical hit pauses and the minimum damage and healing amount. In **Interface**, you can show the minimap shortcut, hide WoW's floating combat text or restore the settings BattleText changed. These choices apply across profiles.
- **Text Areas** controls visibility, movement, color and text size for each area. Use **Move text areas** to drag them into place, **Circle: On/Off** to switch the damage paths, and **Reset positions** to restore the default locations.
- **Profiles** saves individual layouts and lets each character select a profile. Several characters can use the same profile.
- **Help** reopens the welcome guide and changelog.

## Combat data

NPC target damage can include hits from pets and other players. The availability of amounts, critical hits and other outcomes depends on the combat events supplied by Forever.

Use `/battletext test` to show samples in enabled areas and `/battletext status` to check whether target damage events are reaching the addon.

## Changelog

### 1.0

Initial release for WoW: Forever. Includes customizable scrolling text, movable areas with optional circle paths, character profile selection, a minimap shortcut and a first-login guide with a choice to hide WoW's combat text.

## License

[MIT](LICENSE)
