# BistroBlitz status — 2026-10-18

Project: `/home/zerker24/TesseraProjects/BistroBlitz`
Engine: `/home/zerker24/BeefProjects/Tessera`

## Implemented

- Kitchen stations: ingredient sources, counters, chopping, cooking/burning, combining, service and trash. Simulation and shared state belong to the server. Unmatched dishes are retained with feedback.
- Networked chef movement, carrying, procedural appearance/animation, interaction targeting, and prefab registration. Solo, Steam hosting/friends/invitations and direct connections; non-headless hosts get a chef.
- Three-minute service, timed tickets, delivery scoring/tips/combos, expiry penalties, results and complete round reset. Solo menus pause simulation; connected sessions continue.
- Menu, host, join, friends, settings, HUD and results documents/styles. Settings control audio, fullscreen and camera width. Pause controls and Steam presence are wired.
- Rebuilt bright kitchen with low walls, fixed overhead camera, centered/resized Kenney furniture, enlarged ingredient displays, light brown wood counters with grain, color coded station accents and a yellow interaction highlight. Floating station names were removed following user feedback; station names/actions appear in the bottom prompt. Only compact progress bars and customer number badges appear over the playfield. Stoves show enlarged food above pans, active orange burners, rising steam, distinct cooked sausage/patty appearances and dark burnt food/smoke. Enlarged plates sit on blue mats against wood tops.
- Food palette restored at `src/Models/Textures/colormap.png` and explicitly assigned to all food renderers. The original import omitted the external palette, causing white food. The palette source model matches the existing burger exactly; see `docs/ASSETS.md`.
- Visible customers arrive for numbered tickets, wait in the service queue, and depart happy after service or disappointed after expiry. They reset between rounds. These are customer NPCs; AI chef teammates were not requested.
- Linux standalone Release player and runtime ZIP in `Builds/`. The engine builder excludes TesseraEditor and packs assets into `game.tpak`.
- Private-source/public-runtime Windows/Linux GitHub Actions chain, packaging validators, provenance/checksums, and Hub catalog update script. Local Hub entry/preview/patch in `Distribution/Hub/`.

## Validation

```bash
./run.sh --headless --self-test --frames 5
./run.sh --headless --frames 30
BISTRO_MUTE=1 ./run.sh --solo --windowed
```

The deterministic self-test exercises the loaded scene: crates, cooking, assembly, serving and score, chopping, burning, expiry, results, restart, customer arrival/service/departure, every UI document/stylesheet, camera framing and native decoding of the 512x512 food palette. Asset checks verify external GLB textures and UI callback paths. Linux Release packaging runs the same checks against the actual packed player before archiving.

Visual/audio playtesting remains pending: `xdpyinfo` works in the user's desktop terminal but fails inside this session; SDL cannot access X11 here. Offscreen SDL also cannot create a graphics device. The user reported visibility/text/white-model issues; these prompted the art, contextual prompt and missing-palette fixes, but a final screenshot has not been reviewed. Live networking could not be verified here: UDP hosting reports that it cannot open the port. Windows builds and cross-account Steam testing require CI/desktop environments.

## GitHub and Hub remaining

The shell cannot reach/authenticate to GitHub. `tools/setup_github.sh` stops at `gh auth status`. No remote repository or public release has been created by this session, and the live Hub catalog has not been changed. The connected GitHub app returned 404 for `LazyAlgorithm/BistroBlitz` and exposes no repository-creation action.

Run `tools/setup_github.sh` from an authenticated desktop shell to create private `LazyAlgorithm/BistroBlitz`, public runtime-only `LazyAlgorithm/bistro-blitz-releases`, configure `HUB_RELEASE_TOKEN`, and push. The workflow publishes only after Windows and Linux packaged checks pass, then updates the live Hub catalog and starts its self-update. See `docs/RELEASING.md`.
