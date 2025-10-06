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

echo "Keep original subfolders (except 'Partition *')? (y = keep tree / n = flatten with parent prefix) [y]"
read -r org_choice
[[ "${org_choice:l}" != "n" ]] && KEEP_TREE=true || KEEP_TREE=false

# ────────────────────────────────────────────────
#  ⚙️  Sox setup
# ────────────────────────────────────────────────
command -v sox >/dev/null 2>&1 || { echo "❌ sox is required (brew install sox)"; exit 1; }

typeset -a SOX_FX
$NORMALIZE && SOX_FX+=("gain" "-n")
$TRIM && SOX_FX+=("silence" "1" "0.01" "0.5%" "reverse" "silence" "1" "0.01" "0.5%" "reverse")

log() { print -r -- "• $*"; }

# ────────────────────────────────────────────────
#  🧠  Helpers
# ────────────────────────────────────────────────
rel_to_pack() {
  local p_abs="$(realpath "$1")"
  local pack_abs="$PACK_PATH"
  if [[ "$p_abs" == "$pack_abs" ]]; then
    print -r -- ""
    return 0
  fi
  local with_slash="$pack_abs/"
  if [[ "$p_abs" == $with_slash* ]]; then
    print -r -- "${p_abs#$with_slash}"
  else
    print -r -- "$(basename "$p_abs")"
  fi
}

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

clean_rel_dir_from_absdir() {
  # returns a relative directory (may be ""), with Partition* removed
  local absdir="$1"
  local rel="$(rel_to_pack "$absdir")"
  local stripped="$(strip_partitions_from_rel "$rel")"
  print -r -- "$stripped"
}

parent_folder_name() { basename "$(dirname "$1")"; }

# Safe prefix for filenames (keep spaces, strip slashes)
safe_prefix() { print -r -- "$(echo "$1" | tr '/' '_' )"; }

# Decide output directory + filename prefixing strategy
decide_out_dir_and_prefix() {
  # args: src_file -> echoes "OUTDIR|PREFIX"
  local src="$1"
  local parent="$(parent_folder_name "$src")"
  local rel_dir="$(clean_rel_dir_from_absdir "$(dirname "$src")")"

  local outd prefix
  if $KEEP_TREE; then
    # keep subfolders (minus Partition*)
    if [[ -z "$rel_dir" || "$rel_dir" == "." ]]; then
      outd="$OUT_DIR"          # root of pack in REPACKED
    else
      outd="$OUT_DIR/$rel_dir" # preserved sub-tree
    fi
    prefix=""                  # no filename prefix needed
  else
    # flatten into OUT_DIR, but prefix with parent folder to keep grouping
    outd="$OUT_DIR"
    prefix="$(safe_prefix "$parent")_"
  fi

  print -r -- "$outd|$prefix"
}

# Only run sox if FX were requested; otherwise just copy (avoids hangs on quirky WAVs)
copy_or_process() {
  local in="$1" out="$2"
  if (( ${#SOX_FX[@]} )); then
    sox -V1 -G "$in" "$out" "${SOX_FX[@]}" || cp -p "$in" "$out"
  else
    cp -p "$in" "$out"
  fi
}

# ────────────────────────────────────────────────
#  🔄  Process -L / -R stereo pairs
# ────────────────────────────────────────────────
typeset -A seen_names

while IFS= read -r -d '' L; do
  R="${L%-L.wav}-R.wav"
  [[ -f "$R" ]] || continue

  IFS='|' read -r out_dir name_prefix <<<"$(decide_out_dir_and_prefix "$L")"
  mkdir -p "$out_dir"

  base="$(basename "$L")"
  stem="$(print -r -- "$base" | sed -E 's/[[:space:]]*-L\.wav$//')"
  name_no_ext="${stem%.*}"

  # handle duplicate base names across the whole run
  if [[ -n "${seen_names[$name_no_ext]:-}" ]]; then
    [[ -z "$name_prefix" ]] && name_prefix="$(safe_prefix "$(parent_folder_name "$L")")_"
  else
    seen_names[$name_no_ext]=1
  fi

  out_file="$out_dir/${name_prefix}${name_no_ext}.wav"

  log "Stereo  :: ${L#$PACK_PATH/} + ${R#$PACK_PATH/} → ${out_file#$OUT_DIR/}"
  if (( ${#SOX_FX[@]} )); then
    sox -V1 -G -M "$L" "$R" "$out_file" "${SOX_FX[@]}" || true
  else
    # no FX: just merge channels fast & safe
    sox -V1 -G -M "$L" "$R" "$out_file" || true
  fi
done < <(find "$PACK_PATH" -type f -name "*-L.wav" ! -path "*/REPACKED/*" -print0)

# ────────────────────────────────────────────────
#  📦  Copy mono WAVs
# ────────────────────────────────────────────────
while IFS= read -r -d '' F; do
  [[ "$F" == *"-L.wav" || "$F" == *"-R.wav" ]] && continue

  IFS='|' read -r out_dir name_prefix <<<"$(decide_out_dir_and_prefix "$F")"
  mkdir -p "$out_dir"

  base="$(basename "$F")"
  name_no_ext="${base%.*}"

  if [[ -n "${seen_names[$name_no_ext]:-}" ]]; then
    [[ -z "$name_prefix" ]] && name_prefix="$(safe_prefix "$(parent_folder_name "$F")")_"
  else
    seen_names[$name_no_ext]=1
  fi

  out_file="$out_dir/${name_prefix}${base}"

  log "Copy    :: ${F#$PACK_PATH/} → ${out_file#$OUT_DIR/}"
  copy_or_process "$F" "$out_file"
done < <(find "$PACK_PATH" -type f -name "*.wav" ! -path "*/REPACKED/*" -print0)

# ────────────────────────────────────────────────
#  🗂️  CSV Index (global at REPACKED root)
# ────────────────────────────────────────────────
INDEX="$OUT_ROOT/index.csv"
echo "pack_name,path,channels,samplerate,bitdepth,duration_sec,basename" > "$INDEX"

while IFS= read -r -d '' f; do
  ch=$(sox --i -c "$f" 2>/dev/null || echo "?")
  sr=$(sox --i -r "$f" 2>/dev/null || echo "?")
  bd=$(sox --i -b "$f" 2>/dev/null || echo "?")
  du=$(sox --i -D "$f" 2>/dev/null || echo "?")
  bn="$(basename "$f")"
  echo "$PACK_NAME,$f,$ch,$sr,$bd,$du,$bn" >> "$INDEX"
done < <(find "$OUT_DIR" -type f -name "*.wav" -print0)

# ────────────────────────────────────────────────
#  ✅  Done
# ────────────────────────────────────────────────
echo
echo "✅ Repacking complete!"
echo "📁 Output folder: $OUT_DIR"
echo "📄 Index file (global): $INDEX"
