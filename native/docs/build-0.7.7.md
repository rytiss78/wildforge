# Wildforge 0.7.7 — standalone co-op

Removed Steam runtime DLLs, callbacks, achievement sync, friend lobbies and overlay invitations. Existing achievements, scores, settings and local feedback survive the profile migration. There is one Windows build with no store account dependency.

Four-player ENet co-op remains, including host-authoritative enemies, guest attacks, personal loot, shared seeds/world transitions and party pauses. The menu discovers nearby parties, shows counts and running/full states, copies host addresses and accepts direct IP/hostname/VPN connections. Failed joins time out after 12 seconds.

UDP 29736 carries gameplay; UDP 29737 provides local discovery. Internet hosting requires a reachable host via port forwarding or a shared VPN. No hosted relay or matchmaking service is included. The game does not alter router/firewall settings.

See `coop.md` for player instructions. Verification uses the packaged host and rendered guest; public internet/router traversal and four separate physical machines are not verified here.

Validation passed: nearby-party discovery, both peers connected without the Steam singleton, replicated avatars/enemies, 14 guest attacks accepted by the host, 5 kills received by the guest, 148 guest snapshots, party pause and world transition. The rendered co-op menu fits 1920×1080. Three focused Node checks passed for achievement artwork/catalog preservation and manual feedback imports. Existing mesh UID warnings still fall back to valid texture paths; no multiplayer script errors occurred.
