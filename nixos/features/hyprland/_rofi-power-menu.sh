#!/usr/bin/env bash

set -eu

all=(shutdown reboot suspend hibernate logout lockscreen)
show=("${all[@]}")

declare -A texts
texts[lockscreen]="lock screen"
texts[switchuser]="switch user"
texts[logout]="log out"
texts[suspend]="suspend"
texts[hibernate]="hibernate"
texts[reboot]="reboot"
texts[shutdown]="shut down"

declare -A icons
icons[lockscreen]="\Uf033e"
icons[switchuser]="\Uf0019"
icons[logout]="\Uf0343"
icons[suspend]="\Uf04b2"
icons[hibernate]="\Uf02ca"
icons[reboot]="\Uf0709"
icons[shutdown]="\Uf0425"
icons[cancel]="\Uf0156"

declare -A actions
actions[lockscreen]="loginctl lock-session ${XDG_SESSION_ID-}"
actions[logout]="uwsm stop"
actions[suspend]="systemctl suspend"
actions[hibernate]="systemctl hibernate"
actions[reboot]="systemctl reboot"
actions[shutdown]="systemctl poweroff"

confirmations=(reboot shutdown logout)
dryrun=false
showsymbols=true
showtext=true

check_valid() (
    option="$1"
    shift
    for entry in "$@"; do
        if [ -z "${actions[$entry]+x}" ]; then
            echo "Invalid choice in ${option}: ${entry}" >&2
            exit 1
        fi
    done
)

parsed=$(getopt --options=h --longoptions=help,dry-run,confirm:,choices:,choose:,symbols,no-symbols,text,no-text,symbols-font: --name "$0" -- "$@") || { echo 'Terminating...' >&2; exit 1; }
eval set -- "$parsed"
while true; do
    case "$1" in
        "-h"|"--help")
            echo "rofi-power-menu - a power menu mode for Rofi"
            exit 0
            ;;
        "--dry-run") dryrun=true; shift ;;
        "--confirm")
            IFS='/' read -ra confirmations <<< "$2"
            check_valid "$1" "${confirmations[@]}"
            shift 2 ;;
        "--choices")
            IFS='/' read -ra show <<< "$2"
            check_valid "$1" "${show[@]}"
            shift 2 ;;
        "--choose")
            check_valid "$1" "$2"
            selectionID="$2"
            shift 2 ;;
        "--symbols") showsymbols=true; shift ;;
        "--no-symbols") showsymbols=false; shift ;;
        "--text") showtext=true; shift ;;
        "--no-text") showtext=false; shift ;;
        "--symbols-font") symbols_font="$2"; shift 2 ;;
        "--") shift; break ;;
        *) echo "Internal error" >&2; exit 1 ;;
    esac
done

if [ "$showsymbols" = "false" ] && [ "$showtext" = "false" ]; then
    echo "Invalid options: cannot have --no-symbols and --no-text enabled at the same time." >&2
    exit 1
fi

write_message() {
    local icon text
    if [ -z "${symbols_font+x}" ]; then
        icon="<span font_size=\"medium\">$1</span>"
    else
        icon="<span font=\"${symbols_font}\" font_size=\"medium\">$1</span>"
    fi
    text="<span font_size=\"medium\">$2</span>"
    if [ "$showsymbols" = "true" ]; then
        if [ "$showtext" = "true" ]; then
            echo -n "\u200e${icon} \u2068${text}\u2069"
        else
            echo -n "\u200e${icon}"
        fi
    else
        echo -n "$text"
    fi
}

print_selection() { echo -e "$1"; }

declare -A messages
declare -A confirmationMessages
for entry in "${all[@]}"; do
    messages[$entry]=$(write_message "${icons[$entry]}" "${texts[$entry]^}")
done
for entry in "${all[@]}"; do
    confirmationMessages[$entry]=$(write_message "${icons[$entry]}" "Yes, ${texts[$entry]}")
done
confirmationMessages[cancel]=$(write_message "${icons[cancel]}" "No, cancel")

if [ "$#" -gt 0 ]; then
    selection="${*}"
elif [ -n "${selectionID+x}" ]; then
    selection="${messages[$selectionID]}"
fi

echo -e "\0no-custom\x1ftrue"
echo -e "\0markup-rows\x1ftrue"

if [ -z "${selection+x}" ]; then
    echo -e "\0prompt\x1fPower menu"
    for entry in "${show[@]}"; do
        echo -e "${messages[$entry]}\0icon\x1f${icons[$entry]}"
    done
else
    for entry in "${show[@]}"; do
        if [ "$selection" = "$(print_selection "${messages[$entry]}")" ]; then
            for confirmation in "${confirmations[@]}"; do
                if [ "$entry" = "$confirmation" ]; then
                    echo -e "\0prompt\x1fAre you sure"
                    echo -e "${confirmationMessages[$entry]}\0icon\x1f${icons[$entry]}"
                    echo -e "${confirmationMessages[cancel]}\0icon\x1f${icons[cancel]}"
                    exit 0
                fi
            done
            selection=$(print_selection "${confirmationMessages[$entry]}")
        fi
        if [ "$selection" = "$(print_selection "${confirmationMessages[$entry]}")" ]; then
            if [ "$dryrun" = "true" ]; then
                echo "Selected: $entry" >&2
            else
                ${actions[$entry]}
            fi
            exit 0
        fi
        if [ "$selection" = "$(print_selection "${confirmationMessages[cancel]}")" ]; then
            exit 0
        fi
    done
    echo "Invalid selection: $selection" >&2
    exit 1
fi
