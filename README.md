# Bistro Blitz

A Tessera cooperative kitchen beta. Cook and assemble burgers, hot dogs and salads, serve timed orders, and build combos during a three-minute service. Numbered customers arrive, wait for their tickets, and react to service.

Run `./run.sh` for the menu or `./run.sh --solo --windowed` to play locally. The kitchen has a fixed overhead camera, bright tiles, color coded stations, ingredient displays, small progress bars, customer badges and contextual interaction prompts. Use `--host --direct` or `--connect 127.0.0.1` for direct networking. Steam uses test App ID 480.

WASD/arrows move; Shift sprints; E picks up/places; hold F or Space to chop; Escape opens the menu. Combine ingredients on counters and deliver matching dishes to the serving hatch.

`./run.sh --headless --self-test --frames 5` compiles and checks kitchen gameplay and all UI documents. See [STATUS.md](STATUS.md) for validation limits and remaining work.

Source belongs in private `LazyAlgorithm/BistroBlitz`. The release workflow builds Windows/Linux using the pinned Tessera release, runs packaged checks, stages ZIPs privately, publishes runtime-only packages to `LazyAlgorithm/bistro-blitz-releases`, and updates Tessera Hub. See [release setup](docs/RELEASING.md).
