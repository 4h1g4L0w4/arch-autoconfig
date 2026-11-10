#!/usr/bin/env bash
# Captura de pantalla: full | region | window
# Requiere: grim, slurp, swappy, wl-clipboard, dunst

mode="${1:-region}"
dir="$HOME/Pictures/Screenshots"
file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
mkdir -p "$dir"

case "$mode" in
    full)
        grim "$file"
        ;;
    region)
        area=$(slurp -d -b 00000080 -c cba6f7ff -s 00000000 2>/dev/null) || exit 1
        grim -g "$area" "$file"
        ;;
    window)
        # Captura la ventana enfocada (necesita hyprland)
        geo=$(hyprctl -j activewindow | jq -r '.at[0], .at[1], .size[0], .size[1]' | paste -sd ',' - 2>/dev/null)
        grim -g "$geo" "$file"
        ;;
    *)
        echo "Uso: screenshot.sh {full|region|window}"
        exit 1
        ;;
esac

# Copiar al portapapeles y notificar
wl-copy < "$file"
dunstify -i "$file" "Captura guardada" "$(basename "$file")"
