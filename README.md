# Photon Requirement Calculator

A browser-based tool that inverts the usual SNR calculation. You provide target SNR values, and the app solves for the total detected photons required to reach each target in two scenarios:

- a diffraction-limited injection scenario where all flux falls in one spaxel
- a seeing-limited IFU scenario where the same total flux is spread across many spaxels and then summed

The site runs entirely client-side using **Pyodide** (Python + NumPy + Matplotlib compiled to WebAssembly), so it works on GitHub Pages without a backend.

## Features

- Solves for required photons instead of forward-calculating SNR
- Compares diffraction-limited injection and seeing-limited IFU scenarios on the same plot
- Shows the photon penalty of extracting many detector pixels
- Builds a table with total photons, per-spaxel photons, and extended/compact ratio
- Supports browser autosave plus version-controlled default presets from `.github/prompts/`

## Noise model

The calculator assumes one read per frame, gain $= 1$, and stacks $N$ frames.

$$\mathrm{SNR} = \frac{S}{\sqrt{S + B}}, \qquad B = N\,n_{\mathrm{pix}}\left(\sigma_{\mathrm{RON}}^2 + I_{\mathrm{dark}}\,t\right)$$

Solving for the required total detected photons $S$ gives:

$$S_{\mathrm{req}} = \frac{1}{2}\left[\mathrm{SNR}^2 + \sqrt{\mathrm{SNR}^4 + 4\,\mathrm{SNR}^2\,B}\right]$$

| Symbol | Meaning |
|--------|---------|
| `S` | Total detected photons across the full stack |
| `N` | Number of stacked frames |
| `t` | Exposure time per frame (s) |
| `n_pix` | Total extracted detector pixels in the scenario |
| `σ_RON` | Readout noise (e⁻/pix/read) |
| `I_dark` | Dark current (e⁻/s/pix) |

For the two scenarios used in the page:

- Diffraction-limited injection case: `n_pix = compact_extract`
- Seeing-limited IFU case: `n_pix = extended_spaxels × extended_extract`

## Default parameters

- Exposure time per frame: `600` s
- Number of stacked frames: `12`
- Seeing-limited IFU spaxels: `30`
- Seeing-limited extraction width: `3` pixels per spaxel
- Diffraction-limited extraction width: `3` pixels
- Dark current: `0.01 e⁻/s/pix`
- Readout noise: `6 e⁻/pix/read`
- Number of reads per frame: fixed to `1`

## Presets

Default presets live in `.github/prompts/` and are fetched by the page at runtime. This keeps a versioned memory of commonly used parameter sets in the repository, while still allowing each browser to save its own local presets.

- Repo presets: `.github/prompts/*.json`
- Browser presets: `localStorage`
- Autosave: current form values are restored between sessions in the same browser

## Live site

Once deployed, your site will be at:  
`https://<your-github-username>.github.io/<repo-name>/`

## Personal page hosting
 
This tool can also be hosted as a subpage of the personal site repository at:

- `/Users/eartigau/GitHubProjects/page_perso/tools/andes_fibre_snr`

Use `./sync_andes_fibre_snr.sh` from this repository to:

1. Copy or update the hosted tool into the personal-page repo
2. Commit and push only that hosted tool path in the personal-page repo
3. Commit and push this tool workspace to its own GitHub repo

Helpful modes:

- `./sync_andes_fibre_snr.sh --copy-only` refreshes the hosted copy without any git commit or push
- `./sync_andes_fibre_snr.sh --skip-push` creates local commits in both repos without pushing

The hosted copy uses a public `prompts/` folder so it works inside the personal page without requiring root-level GitHub Pages changes.

## Deploy to GitHub Pages

### Automatic (recommended)

1. Push this repository to GitHub  
2. Go to **Settings → Pages**  
3. Under *Source*, select **GitHub Actions**  
4. The workflow in [.github/workflows/deploy.yml](.github/workflows/deploy.yml) will automatically deploy on every push to `main`

### Manual (branch deploy)

1. Go to **Settings → Pages**  
2. Under *Source*, select **Deploy from a branch**  
3. Choose `main` branch, `/ (root)` folder  
4. Save — the site will be live in ~1 minute

## Run locally

Just open `index.html` in any modern browser — no build step, no server needed:

```bash
open index.html          # macOS
xdg-open index.html      # Linux
start index.html         # Windows
```

Or serve it with Python for a proper local server:

```bash
python -m http.server 8080
# then open http://localhost:8080
```

> **Note:** The first page load downloads the Pyodide runtime (~10 MB) and scientific packages. Subsequent loads use the browser cache and are much faster.
