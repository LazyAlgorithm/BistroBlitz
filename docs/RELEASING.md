# Release setup

Run `tools/setup_github.sh` from an authenticated desktop shell with GitHub access and a configured Git author. It creates **private** `LazyAlgorithm/BistroBlitz`, public `LazyAlgorithm/bistro-blitz-releases` for runtime ZIPs only, sets `HUB_RELEASE_TOKEN` using the authenticated gh account without printing it, and pushes the source. The account needs permission to create repositories, push source and workflows, manage the source repo's Actions secrets, publish releases, and update `LazyAlgorithm/tessera-hub`.

`.github/workflows/hub-release.yml` follows Zombie Tag's existing Windows/Linux release chain. It downloads checksum-verified Tessera `build-20261016-3d0fcc7` and compiler `toolchain-2`, builds standalone Release players, validates the actual packed games with `--headless --self-test`, stages packages in a private draft, and publishes only after both platforms pass. Public packages include checksums and build provenance. `tools/start_hub_update.py` then merges the entry in `Distribution/Hub/catalog-entry.json` into the live Hub catalog and triggers its existing self-update workflow. Source, loose models, and development files are not published in the player ZIPs.

The initial Hub entry uses the Hub's existing Tessera banner/icon. Replace these with game artwork when available. The catalog is updated after a successful player release so that it does not offer a nonexistent download.

Local packaging:

```bash
python3 /home/zerker24/BeefProjects/Tessera/tools/build_player.py . --platform linux --config Release --output Builds/BistroBlitz-Linux --fullscreen --replace
python3 tools/package_release.py --platform linux --package Builds/BistroBlitz-Linux
python3 tools/package_release.py --platform linux --package Builds/BistroBlitz-Linux --archive-only
```

Steam uses development App ID 480. Included runtime libraries match those used by the other local games. Live Steam, audio playback, visual testing, and Windows testing need their respective desktop/CI environments.

The setup script also dispatches `web-build.yml`, which retains a web player ZIP as an Actions artifact. It does not publish a web site. See [WEB.md](WEB.md) for local build/setup and mobile controls.
