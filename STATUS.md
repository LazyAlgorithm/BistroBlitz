# BistroBlitz status — 2026-10-18

Project: `/home/zerker24/TesseraProjects/BistroBlitz`
Engine: `/home/zerker24/BeefProjects/Tessera`

## Implemented

- Kitchen stations: ingredient sources, counters, chopping, cooking/burning, combining, service and trash. Simulation and shared state belong to the server. Unmatched dishes are retained with feedback.
- Networked chef movement, carrying, procedural appearance/animation, interaction targeting, and prefab registration. Solo, Steam hosting/friends/invitations and direct connections; non-headless hosts get a chef.
- Three-minute service, timed tickets, delivery scoring/tips/combos, expiry penalties, results and complete round reset. Solo menus pause simulation; connected sessions continue.
- Menu, host, join, friends, settings, HUD and results documents/styles. Settings control audio, fullscreen and camera width. Pause controls and Steam presence are wired.
- Rebuilt bright kitchen with low walls, fixed overhead camera, centered/resized Kenney furniture, enlarged ingredient displays, light brown wood counters with grain, color coded station accents and a yellow interaction highlight. Floating station names were removed following user feedback; station names/actions appear in the bottom prompt. Only compact progress bars and customer number badges appear over the playfield. Stoves show enlarged food above pans, active orange burners, rising steam, distinct cooked sausage/patty appearances and dark burnt food/smoke. Plates and the plate source have been removed. The teal serving hatch and customer queue sit on the right. The two extra wood assembly counters sit at the bottom. Dishes are served directly.
- Food palette restored at `src/Models/Textures/colormap.png` and explicitly assigned to all food renderers. The original import omitted the external palette, causing white food. The palette source model matches the existing burger exactly; see `docs/ASSETS.md`.
- Visible customers arrive for numbered tickets, wait in the service queue, and depart happy after service or disappointed after expiry. They reset between rounds. These are customer NPCs; AI chef teammates were not requested.
- Linux standalone Release player and runtime ZIP in `Builds/`. The engine builder excludes TesseraEditor and packs assets into `game.tpak`.
- Private-source/public-runtime Windows/Linux GitHub Actions chain, packaging validators, provenance/checksums, and Hub catalog update script. Local Hub entry/preview/patch in `Distribution/Hub/`.

## Web build and mobile controls

- Added `src/Input.tinput` and mobile-only touch controls (move stick, Use, Chop, Run, Menu). Desktop browsers/native players keep keyboard/mouse without a touch overlay. Separate mobile menu/settings/results/HUD documents keep touch targets usable.
- Corrected the requested layout: only delivery and customers remain on the right; the two spare assembly counters are back at the bottom.
- `tools/build_web.sh --setup` and `.github/workflows/web-build.yml` prepare/build/validate a real WebAssembly player. See `docs/WEB.md`.
- The user completed toolchain setup and the web build. `Builds/BistroBlitz-Web/` and its ZIP pass package validation. The landing page in `docs/index.html` stages with the browser player under `play/`; the workflow publishes the repository Pages site. Browser/physical-device playtesting remains pending.
- Local touch tests cover simultaneous finger ownership and independent button release at landscape phone, portrait phone and tablet sizes. The desktop overlay stays hidden. Every desktop/mobile UI document parses.

## Validation

```bash
./run.sh --headless --self-test --frames 5
./run.sh --headless --frames 30
BISTRO_MUTE=1 ./run.sh --solo --windowed
```

The deterministic self-test exercises the loaded scene: crates, cooking, assembly, serving and score, chopping, burning, expiry, results, restart, customer arrival/service/departure, every UI document/stylesheet, camera framing, mobile controls and native decoding of the 512x512 food palette. Asset checks verify external GLB textures and UI callback paths. Linux Release packaging runs the same checks against the actual packed player before archiving.

Visual/audio playtesting remains pending: `xdpyinfo` works in the user's desktop terminal but fails inside this session; SDL cannot access X11 here. Offscreen SDL also cannot create a graphics device. The user reported visibility/text/white-model issues; these prompted the art, contextual prompt and missing-palette fixes, but a final screenshot has not been reviewed. Live networking could not be verified here: UDP hosting reports that it cannot open the port. Windows builds and cross-account Steam testing require CI/desktop environments.

## GitHub, Hub and site

Private source is published to `LazyAlgorithm/BistroBlitz`. The first Hub release workflow completed successfully: both Windows and Linux standalone packages passed checks and are published to `LazyAlgorithm/bistro-blitz-releases` under tag `bistro-blitz-2026.10.18-065644-ea0c500`. The live `LazyAlgorithm/tessera-hub` catalog contains BistroBlitz with both platform assets and launch paths.

The repository landing page and Pages deployment are in the web workflow. The initial web compile passed but Actions artifact quota blocked upload; deployment now publishes a runtime-only `gh-pages` branch. Expected page: `https://lazyalgorithm.github.io/BistroBlitz/`. The page links to the browser game and resolves current Windows/Linux release assets, including beta releases. Pages deployment must succeed before the browser link is considered live.

Hub artwork is published under `bistro-blitz-releases/artwork/` and linked in the live catalog. The local cached list was missing BistroBlitz; it is repaired, and the Hub’s catalog refresh now requests a fresh URL (Hub commit `3573deb`).

The shell still cannot resolve GitHub, but the connected GitHub tools can read/write the repositories. See `docs/WEB.md` and `docs/RELEASING.md`.

Browser multiplayer now explicitly selects WebRTC, accepts room codes or invitation links, automatically joins shared URLs, supports sharing from the pause menu, and reports connection timeouts. Steam friends remain desktop-only. Native integration and local WebAssembly packaging pass. Private-repository Pages was rejected by the account plan (HTTP 422); publication now targets the existing public runtime repository, preserving private source. Live two-browser multiplayer remains untested.

The user made BistroBlitz public; Pages deployment now targets BistroBlitz itself at the user’s request.
