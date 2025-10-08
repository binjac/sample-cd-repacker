# 90s Sample CD Repacker

![Project Cover](cover.jpg)

A command-line helper for repacking old 80s–90s sample CDs into clean, modern WAV folders.  
It merges stereo pairs (`-L.wav` / `-R.wav`), cleans up “Partition A/B/C” folder structures,  
and optionally normalizes audio so your legacy collections are instantly usable in any DAW or sampler.

---

## Features

- Detects and merges stereo pairs into proper stereo WAVs  
- Copies mono files as-is  
- Removes “Partition A / Partition B …” folder levels automatically  
- Offers two organization modes:
  - **Keep folder structure:** preserves subfolders like “120 BPM” or “Kick Loops”  
  - **Flatten:** everything goes into one folder, prefixed with the parent name (e.g., `140_BPM_Loop1.wav`)
- Optional normalization and silence trimming (via [**SoX**](http://sox.sourceforge.net/))  
- Generates a global `index.csv` (at `REPACKED/index.csv`) listing:
  - sample path, channel count, sample rate, bit depth, duration  
  - automatically adds the pack name for multi-pack management  
- Output is always cleanly organized under `REPACKED/<Pack Name>/`

---

## Requirements

- macOS or Linux with **zsh**
- [**SoX**](http://sox.sourceforge.net/)  
Install via:
```bash
brew install sox
# or
sudo apt install sox
```

## Usage
```bash
# Clone the repo
git clone https://github.com/<your-username>/sample-cd-repacker.git
cd sample-cd-repacker

# Make the script executable
chmod +x repack_interactive.zsh

# Run it (it will guide you interactively)
./repack_interactive.zsh
```

### Install via Homebrew (tap)

Once you publish a tag and create a tap `binjac/homebrew-audio-tools` with the included formula, users can:

```bash
brew tap binjac/audio-tools
brew install sample-cd-repacker
sample-cd-repacker --help
```

### Classification helper

Classify your existing samples by simple heuristics (name + duration + RMS/peak ratio) and write a `tags.csv`.

```bash
# From source
python3 classify.py <folder> --csv REPACKED/tags.csv --preview --copy-into REPACKED/Classified

# If installed via brew (wrapper script name)
sample-cd-classify <folder> --csv REPACKED/tags.csv --copy-into REPACKED/Classified
 
# Or via pipx (recommended)
pipx install .
sample-cd-classify <folder> --csv REPACKED/tags.csv --copy-into REPACKED/Classified
```

This will:
- create a `REPACKED/tags.csv` with columns: `path, basename, category, confidence, duration, rms_peak_ratio`
- optionally copy files into `REPACKED/Classified/<Category>/`

Roadmap includes better spectral features (librosa/torchaudio), loop detection, pitch detection, and similarity search.