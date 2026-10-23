# Play with friends

Everyone needs the same Wildforge build. No store account, VPN or extra app is required. Up to four players can play together.

## Over the internet

1. Host: choose **Play with friends**, then **Host Party**. Wildforge asks the host's router to open UDP 29736 automatically (UPnP) and shows an invite code such as `WF-…`. The code is copied to the clipboard; **Copy Invite Code** copies it again.
2. Friends: paste the invite code into **Join**.
3. Everyone chooses a hero. The host starts the run.

Friends can also join a run that is already in progress; they arrive next to the party.

If the party panel says internet hosting is unavailable, it names the step that failed:

- **No router answered:**
  - Check that UPnP is on in the router.
  - Check that Windows Firewall allows Wildforge: Windows Security → Firewall & network protection → Allow an app through firewall → tick Wildforge for Private and Public. The router's answer reaches the game only when it is allowed. Windows normally asks the first time you press Host Party, and cancelling that prompt blocks it.
- **The router refused:** the panel shows the router's own reason. If the main port is taken, the game tries outside ports 29746 and 29756 itself; a code from that still works.
- **Carrier-grade NAT:** the host's provider shares one public address between customers, so nobody can reach it from outside. Let a friend host.
- **Manual forwarding** works in every case except carrier-grade NAT:
  1. Forward UDP 29736 in the router to the host PC's local address, which the panel shows.
  2. Look up the host's public IP address, for example by searching "what is my IP".
  3. Friends type that address into Join instead of a code.

Every attempt is logged in `%APPDATA%/Godot/app_userdata/Wildforge/coop-upnp.log`. Send that file when reporting a port-opening problem.

The router mapping is removed when the host closes the party or quits.

## On the same network

Host a party as above. Friends pick it from the nearby-party list (discovery uses UDP 29737), or type the host's local address if discovery is blocked. Guest Wi-Fi networks may isolate devices from each other.

## Good to know

- Allow Wildforge through the host's firewall when Windows asks.
- Choices (level-ups, chests) pause the party together. Each player picks their own upgrades.
- If the host leaves, the run ends for everyone.
- Achievements and scores save on each player's own PC.
- All players must run the same build. The network protocol is `wildforge-shared-world-12`.
