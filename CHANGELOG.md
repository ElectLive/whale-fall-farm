# Changelog

All notable changes to Whale Fall Farm are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/); versions use semver.

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

[Unreleased]: https://github.com/ElectLive/whale-fall-farm/compare/v1.1.0...main
[v1.1.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v1.1.0
[v1.0.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v1.0.0
[v0.3.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v0.3.0
[v0.2.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v0.2.0
[v0.1.0]: https://github.com/ElectLive/whale-fall-farm/releases/tag/v0.1.0
