# Cloudflare Pages Live Test

Use this when deploying Mi Academy web from GitHub for family testing.

## Recommended Pages Settings

- Framework preset: None
- Root directory: repository root
- Build command:

```sh
git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter && export PATH="$PATH:/tmp/flutter/bin" && flutter config --enable-web && cd apps/mobile && flutter pub get && flutter build web --release --pwa-strategy=none
```

- Build output directory:

```txt
apps/mobile/build/web
```

## Notes

- The checked-in `wrangler.toml` declares the same output directory for Wrangler/Pages-aware deploys.
- For a quick manual upload, use the local web zip in `dist/family` instead of rebuilding on Cloudflare.
- WebAssembly has been verified locally. For first live family testing, use the normal web build unless you specifically want to compare the Wasm build.
- Family live tests use `--pwa-strategy=none` so Chrome does not keep an older Flutter service worker during rapid test deploys.
