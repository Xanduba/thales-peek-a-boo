# Thales Peek-a-boo

A calm, non-addictive photo + voice app for a toddler. Tap a photo to make it grow and hear the voice; tap outside or swipe down to put it back.

It is an installable web app (PWA): after the first visit it works **fully offline**.

## Install on a phone / tablet

1. Open the app URL (GitHub Pages: `https://xanduba.github.io/thales-peek-a-boo/`) once **while online**, and wait a few seconds so every photo and sound is downloaded.
2. Install it:
   - **Android (Chrome):** menu ⋮ → **Install app** / **Add to Home screen**.
   - **iPhone / iPad (Safari):** Share button → **Add to Home Screen**.
3. Open it from the home-screen icon. It now runs full-screen and offline.

Tip: on iPad, turn on **Guided Access** (Settings → Accessibility) to keep the child inside the app.

## Files

| File | Purpose |
|---|---|
| `index.html` | The app (HTML + vanilla JS) |
| `tailwind.css` | Pre-built Tailwind CSS (no internet needed at runtime) |
| `manifest.webmanifest` | Makes the app installable (name, icons, full-screen) |
| `sw.js` | Service worker: caches everything for offline use |
| `icons/` | App icons (generated from the photos) |
| `Assets/images`, `Assets/audio` | Photos and voices |
| `tools/` | Developer scripts (not needed by the app) |

## Changing photos, sounds or code

1. Replace files in `Assets/` (keep the same names, or update `PEOPLE` in `index.html` **and** `APP_FILES` in `sw.js`).
2. If you changed Tailwind classes in `index.html`: `powershell -ExecutionPolicy Bypass -File tools\build-css.ps1`
3. If you changed photos: `powershell -ExecutionPolicy Bypass -File tools\make-icons.ps1`
4. **Bump `CACHE_VERSION` in `sw.js`** (e.g. `v1` → `v2`) so installed devices pick up the changes.
5. Commit and push. Devices update the next time the app is opened online (fully applied on the following launch).

## Test locally

```powershell
powershell -ExecutionPolicy Bypass -File tools\serve.ps1
```

Then open http://localhost:8080/. Offline support only works over `http://localhost` or `https://`, not by double-clicking `index.html`.
