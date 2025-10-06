# 🧠 sample-cd-repacker

![Old Sample CDs Collage](https://www.musicradar.com/news/10-classic-sample-packs-changed-electronic-music-1)

A small command-line helper for repacking old 80s–90s sample CDs into clean, usable WAV folders.  
It automatically merges left/right stereo pairs (`-L.wav` / `-R.wav`), flattens weird “Partition A/B/C” folder structures,  
and creates a modern, normalized version of your collection.

---

## ✨ Features

- 🧩 Detects and merges stereo pairs into proper stereo WAVs  
- 🧍 Copies mono files as-is  
- 🧹 Removes “Partition A / Partition B …” folder levels  
- 🔊 Optional normalization and silence trimming (via `sox`)  
- 🧠 Handles duplicate filenames (prefixes with subfolder name if needed)  
- 🧾 Generates an `index.csv` with channels, sample rate, bit depth & duration  
- 🧺 Everything goes neatly into a `REPACKED/<Original Folder Name>/` folder

---

## 🧰 Requirements

- macOS / Linux with **zsh**
- [**SoX**](http://sox.sourceforge.net/) (install via `brew install sox` or your package manager)

---

## 🚀 Usage

```bash
# clone it
git clone https://github.com/<your-username>/sample-cd-repacker.git
cd sample-cd-repacker

# make the script executable
chmod +x repack_interactive.zsh

# run it (it will ask you for a folder path)
./repack_interactive.zsh
