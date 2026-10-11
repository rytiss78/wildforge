# Wildforge 0.8.3 — Development Alpha

> Grow strange. Fight hard. Start again.

Pick a ridiculous hero, explore a bright world full of strange creatures and collect unpredictable upgrades until you become outrageously overpowered. Bring a duck, a loaf of bread, an angry granny or a florist who turns every escape route into a dangerous garden.

---

## Play

| Download | Build | Date |
| --- | --- | --- |
| [Windows (Build 2)](dist/Wildforge-0.8.2-Build-2-Windows.zip) | 0.8.2 | 2026-10-07 |

**Unzip** and run `Wildforge.exe`. Works on Steam Deck, Windows 10+, and macOS (native PC).

---

## Features

- **12 heroes** with unique perks, descriptions and starting weapons — Tank Potato, Wrench, Count Duck, Stone Granny, Tax Rat, Sir Loaf, Florist, Queen Tea, Captain Eight, Space Cadet, Warden Scout, Moon Rat
- **3 weapon slots** with 15+ weapon types (Gun, Saw, Boomerang, Disc, Harpoon, Gravity, Horn, Bubble, Meteor, Bomb, Flowers, Turret, Drone, Orbiter, Shield)
- **Co-op multi-player** — up to 4 players, LAN or VPN, each picks their own reward from shared chest pools
- **5 worlds** — Clover Woods, Sunlit Frontier, Moon Craters, Cloud City, Candy Hell, Starfall Space
- **108 local achievements** — locked/unlocked icons with stable IDs
- **Chest-reveal system** — 5 prizes revealed per chest, pick one to keep, banish 4 others
- **Vertical camera** — look up and down while exploring
- **Surface climbing** — walls, ceilings, ledges, configurable 45° slope gates
- **Eclipse corruption** — late-game visual threat that scales over time
- **Paranoia** — dark music for the Eclipse phase

---

## Screenshots

### Hero Selection

![Hero Selection](screenshots/ui-hero.png)

### In-Game HUD

![HUD](screenshots/ui-hud.png)

### Chest Opening

![Chest Opening](screenshots/ui-chest-opening.png)

### Level-Up Rewards

![Rewards](screenshots/ui-offers.png)

### Co-op Lobby

![Co-op](screenshots/ui-coop.png)

### Pause Menu

![Pause](screenshots/ui-pause.png)

---

## Build from source

1. Install **Godot 4.7** (Forward Plus renderer)
2. Clone this repo and open the `native/` folder
3. Export via Godot's built-in exporter — Windows PC target, `forward_plus` renderer, 1920×1080

Or use the helper: `node scripts/agent-workflow.mjs build`

---

## Planned

See [`plan.md`](../plan.md) for the active development plan.

---

*Wildforge is an unfinished alpha, growing with player feedback. No store account needed. Steam publication was cancelled by the owner on 5 October 2026.*
