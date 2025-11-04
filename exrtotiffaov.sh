#!/bin/bash
# EXR (multi-subimage) → per-AOV files with correct layer names.
# Beauty keeps unassociated A. Non-beauty: NEVER unpremult (avoids black RGB when A=0).
set -o pipefail
shopt -s nullglob

is_color_name() {
  local n="${1,,}"
  [[ "$n" =~ ^(beauty|rgba|rgb|color|albedo|basecolor|diffuse|specular|spec|coat|sheen|emission|emissive|combinedemission|directemission|indirectemission|glossy|glossyreflection|combinedglossyreflection|directglossyreflection|indirectglossyreflection|transmission|glossytransmission|lighting|combined|direct|indirect|shaded|visiblelights)$ ]]
}

order_components() {
  local comps="${1//[[:space:]]/}"; IFS=',' read -r -a arr <<< "$comps"
  declare -A seen=(); for c in "${arr[@]}"; do seen["${c^^}"]=1; done
  if [[ ${seen[R]+x} || ${seen[G]+x} || ${seen[B]+x} ]]; then
    local o=(); [[ ${seen[R]+x} ]]&&o+=(R); [[ ${seen[G]+x} ]]&&o+=(G); [[ ${seen[B]+x} ]]&&o+=(B); [[ ${seen[A]+x} ]]&&o+=(A)
    printf "%s\n" "$(IFS=,; echo "${o[*]}")"; return
  fi
  if [[ ${seen[X]+x} || ${seen[Y]+x} || ${seen[Z]+x} ]]; then
    local o=(); [[ ${seen[X]+x} ]]&&o+=(X); [[ ${seen[Y]+x} ]]&&o+=(Y); [[ ${seen[Z]+x} ]]&&o+=(Z)
    printf "%s\n" "$(IFS=,; echo "${o[*]}")"; return
  fi
  printf "%s\n" "$comps"
}

build_idx2name() {
  local in="$1"; declare -gA IDX2NAME=(); local i=0
  while IFS= read -r line; do
    first="${line%%,*}"
    if [[ "$first" == *.* ]]; then name="${first%%.*}"; else name="beauty"; fi
    name="${name//\//_}"; IDX2NAME["$i"]="$name"; ((i++))
  done < <(oiiotool --info -v -a "$in" | sed -n 's/.*channel list:[[:space:]]*//p')
  [[ ${#IDX2NAME[@]} -eq 0 ]] && IDX2NAME["0"]="beauty"
}

# Collect input files
if [ $# -eq 0 ]; then FILES=(*.exr); else FILES=("$@"); fi
(( ${#FILES[@]} == 0 )) && { echo "No .exr files found."; exit 0; }

for INPUT in "${FILES[@]}"; do
  [[ -f "$INPUT" && "$INPUT" == *.exr ]] || { echo "Skipping '$INPUT'"; continue; }
  base="${INPUT%.exr}"; outdir="${base}_aov"; mkdir -p "$outdir"
  echo "Processing: $INPUT → $outdir/"

  build_idx2name "$INPUT"
  nsi=$(oiiotool --info -v -a "$INPUT" | awk 'BEGIN{n=0} /channel list:/ {n++} END{print n}')
  [[ -z "$nsi" || "$nsi" -eq 0 ]] && nsi=1

  for ((si=0; si<nsi; si++)); do
    layer="${IDX2NAME[$si]:-part${si}}"; safe_layer="${layer// /_}"
    chline=$(oiiotool --info -v --subimage "$si" "$INPUT" | sed -n 's/.*channel list:[[:space:]]*//p' | head -n1)
    [[ -z "$chline" ]] && { echo "  (s$si) No channels — skip"; continue; }
    comps="$(order_components "$chline")"

    IFS=',' read -r -a arr <<< "$comps"; hasA=0; rgb=""
    for c in "${arr[@]}"; do
      cu="${c^^}"
      [[ "$cu" == "A" ]] && hasA=1
      [[ "$cu" == "R" || "$cu" == "G" || "$cu" == "B" ]] && rgb="${rgb:+$rgb,}$cu"
    done
    echo "  → [s$si] ${layer}  (${chline})"

    out="$outdir/${base##*/}_${safe_layer}.tiff"

    if is_color_name "$layer" || [[ "$rgb" == "R,G,B" ]]; then
      # COLOR PASSES
      if [[ "$layer" == "beauty" && -n "$rgb" && "$hasA" -eq 1 ]]; then
        # Beauty: unpremult and keep A (unassociated)
        oiiotool --no-autopremult \
          "$INPUT" --subimage "$si" --ch "$rgb" --unpremult \
          --colorconvert "role_scene_linear" "out_srgb" \
          "$INPUT" --subimage "$si" --ch A \
          --chappend --attrib "oiio:UnassociatedAlpha" 1 \
          -o "$out" || echo "     ! failed color convert (beauty)"
      else
        # NON-BEAUTY COLOR: DO NOT unpremult; drop alpha to avoid invisible RGB
        oiiotool --no-autopremult \
          "$INPUT" --subimage "$si" --ch "$rgb" \
          --colorconvert "role_scene_linear" "out_srgb" \
          --ch R,G,B \
          -o "$out" || echo "     ! failed color convert (s$si:$layer)"
      fi
    else
      # DATA/UTILITY PASSES (Z, P, N, Cryptomatte, IDs, etc.) — keep float data, no colorconvert/unpremult
      oiiotool --no-autopremult \
        "$INPUT" --subimage "$si" --ch "$comps" \
        --setcolorspace "linear" --dataformat float \
        -o "$out" || echo "     ! failed data write (s$si:$layer)"
    fi
  done
done

