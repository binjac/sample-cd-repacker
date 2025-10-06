#!/usr/bin/env zsh
set -euo pipefail

# ────────────────────────────────────────────────
#  🎛️  Interactive input
# ────────────────────────────────────────────────
echo "Enter the full path of the sample pack you want to repack:"
read -r PACK_PATH

# Strip optional quotes / surrounding spaces (handles drag-and-drop too)
PACK_PATH="${PACK_PATH#\'}"; PACK_PATH="${PACK_PATH%\'}"
PACK_PATH="${PACK_PATH#\"}"; PACK_PATH="${PACK_PATH%\"}"
PACK_PATH="$(echo "$PACK_PATH" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

[[ -z "$PACK_PATH" ]] && { echo "❌ No path given."; exit 1; }
[[ ! -d "$PACK_PATH" ]] && { echo "❌ Folder not found: $PACK_PATH"; exit 1; }

# Resolve to absolute path and key paths
PACK_PATH="$(realpath "$PACK_PATH")"
PACK_NAME="$(basename "$PACK_PATH")"
OUT_ROOT="${PACK_PATH%/}/REPACKED"
OUT_DIR="$OUT_ROOT/$PACK_NAME"
mkdir -p "$OUT_DIR"

echo "Normalize audio (peak to 0 dBFS, no clipping)? (y/n) [y]"
read -r norm_choice
[[ "${norm_choice:l}" != "n" ]] && NORMALIZE=true || NORMALIZE=false

echo "Trim leading/trailing silence (soft)? (y/n) [n]"
read -r trim_choice
[[ "${trim_choice:l}" == "y" ]] && TRIM=true || TRIM=false

# ────────────────────────────────────────────────
#  ⚙️  Sox setup
# ────────────────────────────────────────────────
command -v sox >/dev/null 2>&1 || { echo "❌ sox is required (brew install sox)"; exit 1; }

typeset -a SOX_FX
$NORMALIZE && SOX_FX+=("gain" "-n")
$TRIM && SOX_FX+=("silence" "1" "0.01" "0.5%" "reverse" "silence" "1" "0.01" "0.5%" "reverse")

log() { print -r -- "• $*"; }

# ────────────────────────────────────────────────
#  🧠  Helper functions (robust rel-path & partition stripping)
# ────────────────────────────────────────────────

# Return a path relative to PACK_PATH ("" if equals PACK_PATH)
rel_to_pack() {
  local p_abs="$(realpath "$1")"
  local pack_abs="$PACK_PATH"
  # If it's exactly the pack dir
  if [[ "$p_abs" == "$pack_abs" ]]; then
    print -r -- ""
    return 0
  fi
  # Ensure trailing slash on prefix removal
  local with_slash="$pack_abs/"
  # If p_abs starts with pack_abs + '/', strip it; else, just return basename
  if [[ "$p_abs" == $with_slash* ]]; then
    print -r -- "${p_abs#$with_slash}"
  else
    # Fallback (shouldn't happen): return basename to avoid absolute leakage
    print -r -- "$(basename "$p_abs")"
  fi
}

# Remove any path components starting with "Partition " (case-insensitive)
strip_partitions_from_rel() {
  local rel="$1"
  local IFS='/'
  local -a parts out
  parts=(${rel})
  out=()
  for p in $parts; do
    if [[ "${p:l}" == partition\ * ]]; then
      continue
    fi
    out+=("$p")
  done
  print -r -- "${(j:/:)out}"
}

# Build a clean relative directory (never absolute; may be "")
clean_rel_dir_from_absdir() {
  local absdir="$1"
  local rel="$(rel_to_pack "$absdir")"          # may be ""
  local stripped="$(strip_partitions_from_rel "$rel")"
  # If empty (root of pack after stripping), return "" and caller will map to $PACK_NAME
  print -r -- "$stripped"
}

# For duplicate handling (prefix with immediate parent folder)
parent_folder_name() { basename "$(dirname "$1")"; }

# ────────────────────────────────────────────────
#  🔄  Process -L / -R stereo pairs
# ────────────────────────────────────────────────
typeset -A seen_names

while IFS= read -r -d '' L; do
  # Compute companion R (keeps any spaces before -L/-R)
  local R="${L%-L.wav}-R.wav"
  [[ -f "$R" ]] || continue

  # Clean relative dir (based on directory of L)
  local rel_dir="$(clean_rel_dir_from_absdir "$(dirname "$L")")"
  # Ensure files always go under OUT_DIR/PACK_NAME if rel_dir is empty
  if [[ -z "$rel_dir" || "$rel_dir" == "." ]]; then
    rel_dir="$PACK_NAME"
  fi
  local out_dir="$OUT_DIR/$rel_dir"
  mkdir -p "$out_dir"

  local base="$(basename "$L")"
  # Stem without the "   -L.wav" (handles odd spaces)
  local stem="$(print -r -- "$base" | sed -E 's/[[:space:]]*-L\.wav$//')"
  local name_no_ext="${stem%.*}"

  # Handle duplicates across the whole run
  local prefix=""
  if [[ -n "${seen_names[$name_no_ext]:-}" ]]; then
    prefix="$(parent_folder_name "$L")_"
  else
    seen_names[$name_no_ext]=1
  fi

  local out_file="$out_dir/${prefix}${name_no_ext}.wav"

  log "Stereo  :: ${L#$PACK_PATH/} + ${R#$PACK_PATH/} → ${out_file#$OUT_DIR/}"
  if (( ${#SOX_FX[@]} )); then
    sox -V1 -G -M "$L" "$R" "$out_file" "${SOX_FX[@]}"
  else
    sox -V1 -G -M "$L" "$R" "$out_file"
  fi
done < <(find "$PACK_PATH" -type f -name "*-L.wav" -print0)

# ────────────────────────────────────────────────
#  📦  Copy mono WAVs (no -L/-R), preserving clean structure
# ────────────────────────────────────────────────
while IFS= read -r -d '' F; do
  [[ "$F" == *"-L.wav" || "$F" == *"-R.wav" ]] && continue

  # Use the directory of the file to compute a clean relative dir
  local rel_dir="$(clean_rel_dir_from_absdir "$(dirname "$F")")"
  if [[ -z "$rel_dir" || "$rel_dir" == "." ]]; then
    rel_dir="$PACK_NAME"
  fi
  local out_dir="$OUT_DIR/$rel_dir"
  mkdir -p "$out_dir"

  local base="$(basename "$F")"
  local name_no_ext="${base%.*}"

  local prefix=""
  if [[ -n "${seen_names[$name_no_ext]:-}" ]]; then
    prefix="$(parent_folder_name "$F")_"
  else
    seen_names[$name_no_ext]=1
  fi

  local out_file="$out_dir/${prefix}${base}"

  log "Copy    :: ${F#$PACK_PATH/} → ${out_file#$OUT_DIR/}"
  if (( ${#SOX_FX[@]} )); then
    # Process through sox to apply normalize/trim if requested
    sox -V1 -G "$F" "$out_file" "${SOX_FX[@]}"
  else
    cp -p "$F" "$out_file"
  fi
done < <(find "$PACK_PATH" -type f -name "*.wav" -print0)

# ────────────────────────────────────────────────
#  🗂️  CSV Index (for the cleaned tree only)
# ────────────────────────────────────────────────
INDEX="$OUT_DIR/index.csv"
echo "path,channels,samplerate,bitdepth,duration_sec,basename" > "$INDEX"
while IFS= read -r -d '' f; do
  ch=$(sox --i -c "$f" 2>/dev/null || echo "?")
  sr=$(sox --i -r "$f" 2>/dev/null || echo "?")
  bd=$(sox --i -b "$f" 2>/dev/null || echo "?")
  du=$(sox --i -D "$f" 2>/dev/null || echo "?")
  bn="$(basename "$f")"
  echo "$f,$ch,$sr,$bd,$du,$bn" >> "$INDEX"
done < <(find "$OUT_DIR" -type f -name "*.wav" -print0)

# ────────────────────────────────────────────────
#  ✅  Done
# ────────────────────────────────────────────────
echo
echo "✅ Repacking complete!"
echo "📁 Output: $OUT_DIR"
echo "📄 Index file: $INDEX"