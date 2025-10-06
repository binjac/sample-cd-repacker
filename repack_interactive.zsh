#!/usr/bin/env zsh
set -euo pipefail

# ────────────────────────────────────────────────
#  🎛️  Interactive input
# ────────────────────────────────────────────────
echo "Enter the full path of the sample pack you want to repack:"
read -r PACK_PATH
# strip optional quotes if user typed or pasted them
PACK_PATH="${PACK_PATH#\'}"
PACK_PATH="${PACK_PATH%\'}"
PACK_PATH="${PACK_PATH#\"}"
PACK_PATH="${PACK_PATH%\"}"
PACK_PATH="$(echo "$PACK_PATH" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"  # trim spaces

[[ -z "$PACK_PATH" ]] && { echo "❌ No path given."; exit 1; }
[[ ! -d "$PACK_PATH" ]] && { echo "❌ Folder not found: $PACK_PATH"; exit 1; }

PACK_PATH="$(realpath "$PACK_PATH")"
PACK_NAME="$(basename "$PACK_PATH")"
OUT_ROOT="${PACK_PATH%/}/REPACKED"
OUT_DIR="$OUT_ROOT/$PACK_NAME"

mkdir -p "$OUT_DIR"

# Ask for options
echo "Normalize audio? (y/n) [y]"
read -r norm_choice
[[ "${norm_choice:l}" != "n" ]] && NORMALIZE=true || NORMALIZE=false

echo "Trim silence? (y/n) [n]"
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
#  🧠  Helper functions
# ────────────────────────────────────────────────
sanitize_path() {
  # remove “Partition …” from relative paths
  local path="$1"
  local rel="${path#$PACK_PATH/}"
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
  echo "${(j:/:)out}"
}

# find immediate folder name (used for prefixing duplicates)
parent_folder_name() {
  local p="$1"
  echo "$(basename "$(dirname "$p")")"
}

# ────────────────────────────────────────────────
#  🔄  Process -L / -R stereo pairs
# ────────────────────────────────────────────────
typeset -A seen_names

while IFS= read -r -d '' L; do
  R="${L%-L.wav}-R.wav"
  if [[ ! -f "$R" ]]; then
    continue
  fi

  rel_clean="$(sanitize_path "$(dirname "$L")")"
  out_dir="$OUT_DIR/$rel_clean"
  mkdir -p "$out_dir"

  base="$(basename "$L")"
  stem="$(print -r -- "$base" | sed -E 's/[[:space:]]*-L\.wav$//')"
  name_no_ext="${stem%.*}"

  # handle duplicates
  if [[ -n "${seen_names[$name_no_ext]:-}" ]]; then
    prefix="$(parent_folder_name "$L")_"
  else
    prefix=""
    seen_names[$name_no_ext]=1
  fi

  out_file="$out_dir/${prefix}${name_no_ext}.wav"

  log "Stereo  :: ${L#$PACK_PATH/} + ${R#$PACK_PATH/} → ${out_file#$OUT_DIR/}"
  sox -V1 -G -M "$L" "$R" "$out_file" "${SOX_FX[@]}" || true
done < <(find "$PACK_PATH" -type f -name "*-L.wav" -print0)

# ────────────────────────────────────────────────
#  📦  Copy mono WAVs (no -L/-R)
# ────────────────────────────────────────────────
while IFS= read -r -d '' F; do
  [[ "$F" == *"-L.wav" || "$F" == *"-R.wav" ]] && continue

  rel_clean="$(sanitize_path "$F")"
  out_path="$OUT_DIR/$rel_clean"
  mkdir -p "$(dirname "$out_path")"

  base="$(basename "$F")"
  name_no_ext="${base%.*}"

  # handle duplicates again
  if [[ -n "${seen_names[$name_no_ext]:-}" ]]; then
    prefix="$(parent_folder_name "$F")_"
  else
    prefix=""
    seen_names[$name_no_ext]=1
  fi

  out_file="$(dirname "$out_path")/${prefix}${base}"

  log "Copy    :: ${F#$PACK_PATH/} → ${out_file#$OUT_DIR/}"
  sox -V1 -G "$F" "$out_file" "${SOX_FX[@]}" || cp -p "$F" "$out_file"
done < <(find "$PACK_PATH" -type f -name "*.wav" -print0)

# ────────────────────────────────────────────────
#  🗂️  CSV Index
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