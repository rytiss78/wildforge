# Wildforge 1.1.3 — Build 17

Build 17 is a Windows alpha release from source commit `2ccdb333d689d5e00f58bf49c38fe00c242e8b54`.

## Included

- A giant stylized Baron, Red Moon entrance, ten telegraphed arena eruptions, defeat transition, and eight Lithuanian phase-voice clips.
- Refreshed six-biome ground art and mist.
- Persistent weapon mastery, formations, biome collection, co-op pings/readiness/reconnects, teammate build inspection, and expanded run recaps.
- Eight nameplate cosmetics earned through achievements.

## Verification

- Windows export succeeded; the exported startup smoke passed 118 assertions and reported version 1.1.3, Build 17.
- The exported two-process route completed realms 0 → 1 → 2 → 3 → 0, including the Baron, rescue, hunt, guardian, and party transactions. Host assertions passed. The client reported `lobby_hero_ready_synced: false`; the remaining client route checks passed.
- Rendered exported Play With Friends and gameplay/nameplate captures were inspected at 1440×810.

## Known limits

- Real-fight Baron balance remains unverified. Stationary damage estimates do not establish fight duration, survival, or win rates.
- The client lobby-ready synchronization assertion failed in the exported route and needs follow-up.
- The originally reported early-game co-op desynchronization symptom was not described, so Build 17 does not claim that issue is fully resolved.

Unzip the download and keep `Wildforge.exe` and `Wildforge.pck` together. `build-info.json` inside the archive records the source commit and artifact hashes. See the [current plan](../../PLAN.md) and [Build 17 work log](build17-work.md).