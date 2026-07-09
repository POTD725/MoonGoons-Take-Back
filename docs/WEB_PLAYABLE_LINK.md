# MoonGoons Take Back Browser Playable Link

Playable test link:

```text
https://potd725.github.io/MoonGoons-Take-Back/
```

## How it is published

The repository includes a GitHub Pages workflow at `.github/workflows/pages-playable.yml`.

When **Browser Playable Build** runs, it:

1. Downloads Godot 4.3 and export templates.
2. Imports the project and runs the smoke-test pipeline.
3. Exports the **Web Playable** preset to `builds/web/index.html`.
4. Uploads the exported browser build as a GitHub Pages artifact.
5. Deploys it to the playable link above.

## Manual run

1. Open the repository on GitHub.
2. Go to **Actions**.
3. Select **Browser Playable Build**.
4. Click **Run workflow**.
5. After the deployment finishes, open the playable link.

## Local preview

Windows:

```powershell
$env:GODOT_BIN="C:\Godot\godot.exe"
.\tools\build_web_playable.ps1
python -m http.server 8000 --directory .\builds\web
```

Linux/macOS:

```bash
chmod +x tools/build_web_playable.sh
GODOT_BIN=/path/to/godot ./tools/build_web_playable.sh
python -m http.server 8000 --directory builds/web
```

Then open:

```text
http://localhost:8000
```

## Browser test notes

- Use Chrome, Edge, or Firefox first.
- Desktop controls still work in the browser.
- Touch controls work on phones and tablets through the Android/browser command deck.
- This is still a debug/test deployment, not a final commercial web release.
