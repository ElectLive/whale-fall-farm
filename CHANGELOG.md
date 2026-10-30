# Changelog

All notable changes to Whale Fall Farm are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/); versions use semver.

## v2.1.0 — 2026-10-30

### Added

- **Mouse-first world interaction**: left-click a farm tile to walk over and till / plant / water / harvest it; left-click ground to click-to-move.
- **Right-click scythe** aimed at the cursor (hold to keep attacking); keyboard space still works.
- **Mouse wheel** cycles the five seed slots.
- Hover tile highlight, contextual "左键 · …" tooltip, hand/cross cursor, and click destination ring.
- Clickable HUD pause button (Ⅱ) on desktop; seed slots and pause menus were already clickable.

### Changed

- Left click no longer swings the scythe; it is now movement/work. Attack moved to right click / space.
- Scythe automatically faces the mouse on desktop, including when using space.
- Desktop help, pause help and HUD hint text rewritten for mouse controls.
- `--shot=mouse` and `--shot=help` scenarios; selftest covers click target, click interact, wheel, and right-click attack.

## v2.0.0 — 2026-10-29（更新 17–20，完整版）

### Added

- **Pet leveling**: harvests grant pet XP (10 per level); level raises attack damage and shortens attack cooldown; HUD shows `小鲸鱼 LvN`.
- **Second biome 雾港 (Mist Harbor)**: after the first run, ~30% of runs start in a cooler, foggy harbor: crops grow 15% faster, nights add one slime, island/sea are tinted.
- Save version field (`save_version=2`) with safe defaults for older saves.
- Final title badge, 20-update table and full documentation.

### Changed

- Day length 75s → 80s for the final balance pass.
- FPS capped at 60; mobile halves firefly and rain particle counts.
- `OS.low_processor_usage_mode` enabled.
- README, design doc, devlog, changelog and release notes complete the 20-update plan.

## v1.6.0 — 2026-10-29

### Added

- **Daily challenge**: title button starts a date-seeded run (YYYYMMDD) with a local best-day record.
- **Pet whale 小鲸鱼**: follows the farmer, attacks nearby monsters every ~1.8s, can gain levels from harvests.
- **Accessibility/control settings** in pause: screen-shake toggle, reduced flash, auto-aim.
- Second pause settings row; daily button on title; pet sprite generated procedurally.

### Changed

- Pause menu accepts shake/flash/auto-aim state and persists all settings.
- Auto-aim picks the nearest monster within 90px for scythe swings.

## v1.5.0 — 2026-10-29

### Added

- **Farm codex**: title-screen screen listing discovered crops, monsters and relics; discovery is saved.
- **Lifetime stats page**: runs, best day/kills, total gold, crops harvested, enemies killed, golden harvests, achievements and codex progress.
- **Endless boss modifiers**: from day 10 the Pumpkin King rolls 狂暴 (+30% speed), 再生 (1 HP/s) or 召唤 (extra minions), shown in the boss bar.
- **Elite enemies**: 8% + day×0.5% chance to spawn with double HP, double gold and a larger golden sprite.
- Codex/stats buttons on the title screen; `--shot=codex` and `--shot=stats` dev scenarios.

### Changed

- Boss HUD name includes its modifier; summon count is 3 for the summoner modifier.
- Discovery hooks for planting, spawning and relic picks.

## v1.4.0 — 2026-10-29

### Added

- Four relics: 锐利镰刃 (20% crit), 丰收护符 (20% heal on harvest), 夜行者帽子 (+1 night damage), 点金手 (+10% golden chance).
- **铁甲虫 (beetle)** enemy: 9 HP, armor 1 (damage reduced by 1, minimum 1), joins waves from day 5.
- **Weather expansion**: fog and thunderstorm in addition to rain; storm lightning flashes and thunder SFX; fog overlay; both wet weathers auto-water.
- **Achievements**: 8 achievements with unlock banners and persistent storage; lifetime harvest/kill/golden counters.
- HUD weather text for rain/fog/storm; `--shot=storm` screenshot scenario.

### Changed

- Weather roll changed to 62% sunny / 20% rain / 10% fog / 8% storm from day 2.
- Boss night adds 2 beetles; normal waves add beetles from day 5.
- Enemy sprite scale now reads the data `scale` field.

## v1.3.0 — 2026-10-29

### Added

- Fifth crop **辣椒 (chili)**: 11g seeds, 11s growth, 30g sale, joins the shop rotation.
- Five-slot seed belt with clickable slots, `1`–`5` hotkeys and auto-switch when a stack runs out.
- **Golden crops**: 5% (+luck) chance on planting, 3× sale value, +15% seed return, golden glow.
- Mobile haptics on hurt / kill / harvest / boss death, with a persisted vibration toggle.
- Auto-pause when the app loses focus on mobile.
- Harvest prompt now shows the exact gold value (and golden tag).

### Changed

- HUD seed panel widened for five slots; hint text updated to `1-5`.
- `current_action` no-seed and plant labels are clearer.

## v1.2.0 — 2026-10-29

### Added

- **Android support and APK** (`WhaleFallFarm-v1.2.0-android.apk`, min SDK 24, arm64, landscape).
- `MobileControls`: virtual joystick, hold-to-attack scythe button, interact button, pause button.
- Seed belt slots are now tappable buttons with a highlighted selected slot.
- Android system back button opens/resumes the pause menu instead of quitting.
- Seed icons show touch hints on mobile; title help and pause help switch to touch instructions.
- Android saves go to `user://`; Windows portable builds still save next to the executable.

### Changed

- Pause screen hides the fullscreen toggle on mobile.
- Project version 1.2.0, Android versionCode 3.
- Texture import enables ETC2/ASTC for Android export.

## v1.1.0 — 2026-10-29

### Added

- Fourth crop **月光麦 (moonwheat)**: only advances growth at night, pauses during the day.
- Four-slot seed belt (`1`–`4`), wider HUD, new moonwheat seed shop offer.
- New enemy **沼泽蛙 (bog frog)**: charges up and leaps at the player, joins the night waves from day 4.
- **Rain weather** from day 2 (30% chance): auto-waters every crop including new plantings, with rain particles and an 8-second rain ambience loop.
- Rain ambience channel (`play_ambience` / `stop_ambience`), HUD shows `白天 · 雨`, rain ends at night.
- New art: 4 moonwheat stages, frog sheet, moon seed icon, rain streak (76 sprites total).

### Changed

- Crop seed drops can now include moonwheat.
- Night 7 boss wave adds 3 frogs.

## v1.0.0 — 2026-10-29

### Added

- **Endless mode**: after defeating the Pumpkin King on night 7, continue from day 8 and fight a stronger boss every 3rd day (10, 13, 16…).
- Endless best-day/kill records update without double-counting runs.
- `--shot=endless` developer screenshot scenario.

### Changed

- HUD shows `白天 · 无尽 / 夜晚 · 无尽` in endless mode.
- Project version set to 1.0.0 in `project.godot` and the title screen.

### Fixed

- Run is recorded exactly once when a victory continues into endless mode.

## v0.3.0 — 2026-10-29

### Added

- Pause menu with music / SFX / fullscreen toggles, persisted to `save_data.cfg`.
- `M` hotkey to toggle music.
- Two relics: 潮雾提灯 (−12% night monster speed) and 绿拇指 (+15% growth on watering).
- Boss BGM (140 BPM loop), victory and game-over stings.
- Night fireflies, low-health red frame, crop stage pop animation.

### Changed

- Pause layout centers its content; blessing list stays readable with more relics.

## v0.2.0 — 2026-10-29

### Added

- **Tide Shop** at dawn: 3 random offers (seed packs, heal, max HP), one purchase each.
- **Corrupted Pumpkin King** boss on night 7: seed projectiles, summons at 66% / 33% HP, boss HP bar.
- Boss death sequence, banners, screen shake, spawn particles, footsteps.
- Boss roar / explosion / seed-shot SFX.

### Changed

- Night 7 wave rebalanced around the boss; boss nights never end by timeout.

## v0.1.0 — 2026-10-29

### Added

- Core loop: title → day farming (75s) → night survival → dawn blessing → 7-day victory.
- 15×8 farm grid, till/plant/water/harvest, 3 crops with 4 growth stages.
- 3 monsters (slime, crop-eating crow, vine), 12 relics, gold economy, local records.
- Fully procedural pixel art (Pillow), chiptune music and SFX (numpy), Cubic 11 font.
- Headless self-test (`--selftest`), real-time smoke test (`--smoke`), screenshot tooling.

[Unreleased]: https://github.com/ElectLive/whale-fall-farm/compare/v2.1.0...main
[v2.1.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v2.1.0
[v2.0.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v2.0.0
[v1.6.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v1.6.0
[v1.5.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v1.5.0
[v1.4.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v1.4.0
[v1.3.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v1.3.0
[v1.2.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v1.2.0
[v1.1.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v1.1.0
[v1.0.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v1.0.0
[v0.3.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v0.3.0
[v0.2.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v0.2.0
[v0.1.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v0.1.0
