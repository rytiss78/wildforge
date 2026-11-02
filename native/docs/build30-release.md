# Wildforge 1.13.0 — Build 30

Build 30 is a Windows alpha. `build-info.json` beside the executable records the exact source commit and artifact hashes. **Every player in a party needs Build 30**: co-op refuses any other download (network protocol `wildforge-shared-world-20`). The main menu shows the build ID (bottom right) to compare.

**Install:** extract the whole ZIP into a folder and run `Wildforge.exe`. Keep `Wildforge.pck` and `godot_wry.dll` beside it. Archive `Wildforge-1.13.0-Windows.zip`, SHA-256 `44b0af1a8058a78925f8aa6cad89f46e1d2baa5340a931ac3d91ddc67ffd2166`.

## Chest reels: real slot machine

Opening a chest now feels like a slot machine, and the rarity shows in the opening animation, the reels, and the sounds.

### Opening a chest

- A light beam rises from the chest in the best prize's colour. It's taller and brighter the rarer the prize: blue, then purple, then gold. A legendary chest also adds a gold glow and a burst.
- Epic and legendary chests start with a rising whine.

### The chest reels

- Five reel windows spin with a blur, and lights along the edges of the machine chase while it spins.
- The reels stop one by one from left to right, each with a bounce and a clunk.
- A reel holding an epic or legendary prize slows right down first, with a rising whine, before it stops.
- When a rarer reel stops, it lights up in its colour with turning rays. A tag pops up over it: **RARE**, **EPIC!** or **LEGENDARY!!**.
- The stop sound gets bigger with rarity: a clunk, then a bell, then a sparkly run of notes, then a big chord with a cymbal.
- A legendary shakes the machine, flashes it gold, sparkles, and ends on a jackpot jingle.
- The "LEGENDARY" label at the bottom only appears once the reels have shown it — no more giving the result away before the spin.

### Level-up and reroll cards

- Each card starts as a spinning slot window and stops left to right, with the same rarity sound, flash, rays and tag.
- You can't pick a card while it's still spinning, so you can't grab one blind.
- Buttons: Reroll is green and Banish is red.

The sounds are newly made for this. Feedback welcome on volume, duration, and pacing.

## Fixes

- **Head-stomp test**: fixed another randomly failing build check caused by the same shielded-elite issue. Head-stomp now uses a plain (non-elite) monster for reliability.
