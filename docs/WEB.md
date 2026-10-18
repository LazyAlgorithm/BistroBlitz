# Web player and mobile controls

Build from a network-enabled desktop terminal:

```bash
cd /home/zerker24/TesseraProjects/BistroBlitz
./tools/build_web.sh --setup
```

The first setup downloads Emscripten 4.0.23, builds Beef's matching WebAssembly runtime and Tessera's native web libraries, and compiles WebGL shaders. Later builds can use `./tools/build_web.sh` without `--setup`. Set `TESSERA_ENGINE` if the engine lives elsewhere. `EMSDK` can select an existing Emscripten SDK.

A successful build produces `Builds/BistroBlitz-Web/` and `Builds/BistroBlitz-Web.zip`. The validator requires a real WebAssembly module, JavaScript loader, packed assets and mobile manifest; no placeholder web page is accepted as a build.

Serve the build over HTTP, rather than opening the HTML directly:

```bash
python3 -m http.server 8080 --directory Builds/BistroBlitz-Web
```

Open `http://localhost:8080/` on the desktop. For a phone/tablet on the same network, open the computer's LAN address on port 8080. Landscape gives the largest view. The repository page is deployed by the web workflow at `https://lazyalgorithm.github.io/bistro-blitz-releases/`; its Play button opens the packaged game in `play/`.

Desktop browsers use WASD/arrows, E, F/Space and Escape, with no touch overlay. Only mobile browser versions show the movement stick, USE, CHOP, RUN and MENU buttons. USE picks up, places, combines or delivers; hold CHOP to prepare food; hold RUN while moving to sprint. Mobile menus and HUD use separate UI documents. Menu taps do not trigger gameplay actions, and synthetic touch mouse presses do not accidentally pick up food when chopping.

The `web-build.yml` GitHub Actions workflow builds and validates the `BistroBlitz-Web` player using the same toolchain setup as Polystrike. It stages `docs/index.html` as the landing page and the validated player under `play/`, then commits that runtime-only site to the repository’s `gh-pages` branch and enables branch-based GitHub Pages. This avoids GitHub Actions artifact storage, whose account quota blocked the first deployment. Source stays in the private repository. The workflow runs on game/build/page changes on main and supports manual dispatch. The existing Hub workflow still publishes the standalone Windows/Linux players and updates the Hub only after their packaged checks pass.

## Current validation

Native compilation and deterministic tests pass, including real touch-control finger ownership, simultaneous move/use/chop, independent release, and three phone/tablet viewport shapes. Desktop and mobile UI documents load through Tessera's parser. The desktop overlay is verified hidden.

The user completed toolchain setup and built the WebAssembly player in `Builds/BistroBlitz-Web/`. Its loader, WebAssembly header, packed assets and manifest passed validation, and the complete Pages site stages successfully. Browser runtime and physical-device touch testing remain pending. The new Pages workflow deployment is tracked in GitHub Actions.

Browser-local saving is supported by Tessera's IndexedDB filesystem, but BistroBlitz currently does not persist gameplay or settings.
