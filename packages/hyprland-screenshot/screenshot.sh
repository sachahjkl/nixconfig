#!/usr/bin/env bash
set -uo pipefail

outdir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$outdir" || exit 1
out="$outdir/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

# Read window boxes from visible workspaces for click selection.
ws_ids=$(hyprctl monitors -j | jq -c '
    [.[] | .activeWorkspace.id, .specialWorkspace.id]
    | map(select(. != null and . != 0))') || exit 1
boxes=$(hyprctl clients -j | jq -r --argjson ids "$ws_ids" '
    .[]
    | select(.mapped and (.hidden | not))
    | select(.workspace.id as $w | $ids | index($w))
    | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"') || exit 1

freeze_pid=""
cleanup() {
    if [ -n "$freeze_pid" ]; then
        kill "$freeze_pid" 2>/dev/null || true
        wait "$freeze_pid" 2>/dev/null || true
        freeze_pid=""
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

hyprpicker -r -z >/dev/null 2>&1 &
freeze_pid=$!
sleep 0.2

# Piped stdin enables window selection. Dragging selects an arbitrary region.
geom=$(printf '%s\n' "$boxes" | slurp -d 2>/dev/null) || exit 0
[ -n "$geom" ] || exit 0

# Save the selection monitor before launching the annotation window.
cursor=$(hyprctl cursorpos | tr -d ' ') || exit 1
satty_mon=""
satty_ws=""
read -r satty_mon satty_ws < <(hyprctl monitors -j | jq -r \
    --argjson x "${cursor%,*}" --argjson y "${cursor#*,}" '
    [ .[] | select(.x <= $x and $x < (.x + .width / .scale))
          | select(.y <= $y and $y < (.y + .height / .scale)) ][0]
    | select(. != null) | "\(.name) \(.activeWorkspace.name)"') || true

# Resolve point selections to the smallest window box containing the point.
read -r pos size <<<"$geom"
sw="${size%x*}"
sh="${size#*x}"
if [ "$sw" -le 2 ] 2>/dev/null && [ "$sh" -le 2 ] 2>/dev/null; then
    px="${pos%,*}"
    py="${pos#*,}"
    resolved=$(printf '%s\n' "$boxes" | awk -v px="$px" -v py="$py" '
        NF >= 2 {
            split($1, p, ","); split($2, s, "x")
            if (px >= p[1] && px < p[1] + s[1] && py >= p[2] && py < p[2] + s[2]) {
                area = s[1] * s[2]
                if (best == 0 || area < best) { best = area; line = $0 }
            }
        }
        END { if (best > 0) print line }')
    if [ -n "$resolved" ]; then
        geom="$resolved"
    fi
fi

# Capture the frozen frame, then remove the freeze overlay.
grim -g "$geom" "$out" || exit 1
cleanup
wl-copy --type image/png < "$out" || exit 1

# Both monitor and workspace are needed to place satty on the selection monitor.
if [ -n "$satty_mon" ]; then
    placement=$(jq -crn --arg monitor "$satty_mon" --arg workspace "$satty_ws" '
        "monitor = " + ($monitor | tojson)
        + (if $workspace == "" then "" else ", workspace = " + ($workspace | tojson) end)')
    hyprctl eval "hl.window_rule({ name = \"satty-monitor-$$\", match = { class = \"com.gabm.satty\" }, $placement })" >/dev/null || exit 1
fi

before=$(hyprctl clients -j | jq -r '.[]|select(.class=="com.gabm.satty")|.address')
satty -f "$out" -o "$out" --copy-command=wl-copy --resize smart &
satty_pid=$!
new=""
for _ in $(seq 1 150); do
    new=$(hyprctl clients -j | jq -r --arg before "$before" '
        ([.[]|select(.class=="com.gabm.satty")|.address])
        - ($before|split("\n")) | .[0] // empty')
    [ -n "$new" ] && break
    sleep 0.03
done
if [ -n "$new" ]; then
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$new\" })" >/dev/null
fi
wait "$satty_pid"
