# 🙂 90s Sample CD Repacker 💿

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