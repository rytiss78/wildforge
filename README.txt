Wildforge ENet diagnostic (read-only to the game)

Copy native/scripts/enet_probe.gd into G:\game\native\scripts\
Run ONE command in PowerShell, from G:\game:

& '.\tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path native --script res://scripts/enet_probe.gd

Expected: ENET_PROBE PASS: local ENet handshake and reliable packets work

If it passes, the bundled Godot engine and localhost ENet work independently of Wildforge.
Investigate the game's host/client startup sequence, 14-second connect/start deadline,
resource contention under two processes, port conflicts, and failing COOP_TEST assertions.

If host_create is nonzero, UDP port 29736 cannot be opened. Check any existing Wildforge
or Godot instance that owns the port; do not kill unrelated processes.

If client creation succeeds but the connection times out, capture the entire terminal output.

This script does not modify the game; it opens local UDP port 29736 briefly and closes it
when it exits. It does not test two independent Godot processes or the six-minute game run.
