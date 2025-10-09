<img width="128px" src="samplem_icon.png" alt="Samplem Logo" align="left" />

# Samplem

A Modern Audio Repacker & Classifier Toolkit

Samplem is a modular command-line and desktop toolkit for restoring, cleaning, and organizing vintage sample collections.
Originally built to repack 80s–90s sample CDs, it has evolved into a broader system for sample cleanup, normalization, tagging, and classification.

Bring order to your chaos of WAVs: merge, normalize, tag, and rediscover your archive with precision.

---

## Installation & Usage

### From source

```bash
git clone https://github.com/binjac/samplem.git
cd samplem
chmod +x install.sh
./install.sh
```

After that, you can run from anywhere:

```bash
samplem --help
samplem repack
```

### Requirements

* macOS or Linux with zsh
* [SoX](http://sox.sourceforge.net/) (`brew install sox` or `sudo apt install sox`)

### Desktop App (Tauri UI)

Samplem also includes a lightweight desktop app (`samplem-ui`) built with [Tauri](https://tauri.app/) and TypeScript.
It provides a drag-and-drop interface to process your sample folders.

#### Run in development

```bash
cd samplem/samplem-ui
npm install
npm run tauri dev
```

This opens a desktop window where you can:

* Drag & drop a folder of samples
* Toggle options (normalize, trim, layout)
* Run the repack process and see logs in real time

#### Build a standalone app (macOS)

```bash
npm run tauri build
```

You’ll find the compiled `.app` in:

```
samplem-ui/src-tauri/target/release/bundle/macos/
```

You can drag it into `/Applications` for easier access.

---

## Core Features

### Repack

Rebuild messy 80s–90s sample CDs into clean, modern folders.

* Detects and merges stereo pairs (`-L.wav` + `-R.wav`) into single stereo WAVs
* Copies mono files as-is
* Removes redundant “Partition A / Partition B …” subfolders
* Offers three organization modes:

  1. **Keep parent subfolders:** preserves folders like `120 BPM`, `Kicks`, or `Loops`
  2. **Flatten with parent prefix:** all files go into one folder, prefixed by their source (e.g. `120BPM_Loop1.wav`)
  3. **Flatten without prefix (default):** one clean, flat folder
* Optional normalization (peak to 0 dBFS) and silence trimming (via [SoX](http://sox.sourceforge.net/))
* Generates a global `index.csv` with: pack name, relative path, channel count, sample rate, bit depth, and duration

---

### Classify

Group and tag samples automatically using heuristics (and soon, ML-based models).

```bash
samplem classify <folder> --csv REPACKED/tags.csv --copy-into REPACKED/Classified
```

Or from source:

```bash
python3 classify.py <folder> --csv REPACKED/tags.csv --preview
```

Heuristics include:

* File name keywords (`kick`, `snr`, `hh`, `vox`, `pad`, `fx`, etc.)
* Duration analysis (short = percussive, long = ambient)
* Loudness / RMS ratio for intensity detection

Output example:

```
REPACKED/tags.csv
├── path,basename,category,confidence,duration,rms_peak_ratio
└── 909BD01.wav,909BD01.wav,Kick,0.98,0.42,0.85
```

Optionally, files are copied into:

```
REPACKED/Classified/
 ├── Kicks/
 ├── Snares/
 ├── HiHats/
 ├── FX/
 └── Unknown/
```

---

## Coming Soon

Samplem will evolve into a full modular audio toolkit:

* Pitch and tempo detection (via `librosa` / `aubio`)
* Loop detection and seamless trimming
* LUFS normalization for consistent loudness
* Spectral fingerprinting for similarity search
* SQLite index for fast queries across large libraries
* Terminal UI for browsing, tagging, and previewing samples interactively
* Desktop drag-and-drop app (via Tauri + Swift integration)

---

## 🗺️ Roadmap

| Phase | Focus                | Description                                                              |
| ----- | -------------------- | ------------------------------------------------------------------------ |
| v0.9  | Repack core          | Clean, merge, normalize legacy sample CDs                                |
| v1.0  | Desktop app          | Drag-and-drop UI for folder processing                                   |
| v1.1  | Divide sample chains | Divide sample chains by checking transients, zero crossings and silences |
| v1.2  | Classification       | Heuristic and ML-based sample tagging                                    |
| v1.3  | Pitch and tempo      | Auto-key and BPM detection                                               |
| v1.4  | Similarity           | Find and cluster similar samples                                         |
| v2.0  | UI and database      | Terminal UI and local sample index DB                                    |

---

## Vision

Samplem aims to become the go-to open-source toolkit for sound archivists and producers a precise, reliable environment to restore, tag, and explore vast sample libraries from 90s CDs to modern field recordings.
