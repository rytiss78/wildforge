# Play with friends

Give everyone the same complete Wildforge build folder. No store account or purchase is required. Up to four players join before the host starts a run.

On the same Wi-Fi/LAN:
1. Host: choose Play with friends, then Host Party.
2. Friends: select the host under Same-network parties. If discovery is blocked, enter the host's displayed address instead.
3. Everyone chooses a hero. The host returns to hero selection and starts.

For remote friends, use a shared VPN's host address, or forward UDP 29736 on the host's router to their PC and join using the host's public IP. Copy Host Address copies a local interface address; it does not find the public IP. Hosts with several adapters can select the appropriate address displayed in party status.

Allow Wildforge through the host firewall. Discovery uses UDP 29737. Guest networks may isolate devices; public-IP connections may be unavailable behind carrier-grade NAT, requiring a shared VPN. The game does not change router or firewall settings.

Running and full parties reject new guests. Choices pause the party together. If the host leaves, guests end the run and can create a new party. Achievements and scores save on each player's PC.

Surface-climbing builds use protocol `wildforge-0.8.2-direct-5`. All players must use the same build; enemy surface orientation is authoritative on the host and replicated to clients.
