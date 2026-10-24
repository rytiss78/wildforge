# Wildforge 1.5.0 — Build 22

Build 22 is a Windows alpha. `build-info.json` beside the executable records the exact source commit and artifact hashes. Co-op uses protocol `wildforge-shared-world-14`, so **every player in a party needs Build 22**.

## New

- **Block Drop.** A small falling-blocks game in the pause menu (**▦ BLOCK DROP**). In co-op it also opens by itself while a friend is still choosing a reward. Your board is saved and continues at the next pause. It has its own chiptune take on the folk song "Korobeiniki" and blip sounds; the game music pauses while it is open.
  - Controls: arrows or WASD, Space hard drop, Z rotate back. On a controller: D-pad, A rotate, Y or D-pad up hard drop.
  - In co-op the party panel beside the board shows every player's cards and picks.
- **Short videos beside the board.** Real **TikTok** videos by default, with a button to switch to **YouTube Shorts** and back, and **VIDEOS: ON/OFF**.
  - Each video plays at most 7 seconds, never loops, and the next starts at once, at low volume.
  - TikTok picks from a set of hashtags (phonk, gymtok, meme, gravel, remco, techhouse, nature, run, rally, parrot, core, cuterat, punk, puppy, mindset, uptempo, rats). YouTube Shorts come from The Dodo, The Pet Collective, Good News Network and Animal Planet.
  - No cookie banners: both play through the sites' official embed players.
  - Needs Windows' built-in Edge WebView2 (included in Windows 10 and 11) and an internet connection.
- **Bigger Block Drop screen.** The board and video fill most of the screen.

## Fixes

- **Weapon damage numbers.** Gravity wells hit every frame for fractions of a point, which showed as a stream of "1"s. They now hit four times a second with the same total. Gravity, meteor and flower damage now show numbers. Rolling bombs hit tall enemies. Flowers, burn and poison grow with weapon rank. Hybrid infusions no longer hit for a flat 1.
- **Multi-shot weapons were too strong.** Variants with extra shots or meteors dealt 2–7 times their base weapon (Marble Rain 6.7x Meteor). A full volley now deals about 1.5 times.
- **Level-up with only one card.** In co-op, a full loadout hid every new weapon. All five cards now show, and a new weapon opens the swap screen.
- **Same drops for everyone.** Each co-op player now gets cards of their own for shared level-ups and chests.
- **Same weapons every run.** Weapons from your last runs sit out the first weapon offers.
- **Space picked a random card.** Space no longer picks reward cards. Enter and controller A wait a moment after the cards appear. Number keys and the mouse still pick at once.
- **Rejoining co-op.** Level-ups and chests shared while you were disconnected are offered when you return, including ones from an island the host has left.
- **Co-op in big fights.** The world now travels in packets that each fit one network packet (at most 1,200 bytes), so a lost packet costs a few enemies for a tenth of a second instead of the whole update.
- **Difficulty.** Islands 2 and 3 are tougher and the Baron has 25% more health.

## Known limits

- **Video content:** comes from public hashtags and channels. It is not vetted, and TikTok or YouTube can change their sites and stop it working. When that happens the panel only shows "Loading…".
- **Not yet tested on two machines:** the co-op fixes, the waiting overlay and the videos over a real internet connection.
- **Performance:** three max-rank spells in a 125-enemy crowd still run at about 30 fps.
- **Balance:** measured by bots only; their runs vary a lot. The Baron fight still needs people to play it.
- **Audio:** Block Drop's music and sounds are generated and have not been listened to.

## Verified

- The export from source commit `be50250` passes the startup smoke and reports 1.5.0 / Build 22. The browser plugin (`godot_wry.dll`) ships beside the executable.
- The video panel passes its review in an exported executable: TikTok, YouTube, auto-scroll and the switch button.
