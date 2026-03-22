# Build And Release

## Local packaging

This project includes a local export script:

```bash
chmod +x scripts/export_release.sh
GODOT_BIN=/path/to/godot ./scripts/export_release.sh
```

Requirements:

- Godot `4.6.1` installed locally
- Matching export templates installed locally
- `zip` and `ditto` available

Artifacts are written to `dist/`.

## GitHub Actions release flow

The workflow file is:

- `.github/workflows/release.yml`

Behavior:

- Push a tag like `v1.0.0`
- GitHub Actions exports:
  - `Linux/X11`
  - `Windows Desktop`
  - `macOS`
- It packages the exports into `.zip` files
- It publishes the zip files to a GitHub Release with the same tag

You can also run it manually from `Actions` with `workflow_dispatch`.

## Notes

- macOS export is configured as unsigned for CI release builds.
- `export_presets.cfg` now includes concrete export paths for Linux, Windows, and macOS.
- If you want notarized or signed macOS builds later, add signing credentials and update `export_presets.cfg`.
