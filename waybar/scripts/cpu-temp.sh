#!/bin/bash
# Obtiene la temperatura del paquete de la CPU
# Intenta usar sensors, si no, busca en /sys/class/hwmon

TEMP=$(sensors | grep -m1 'Package id 0' | awk '{print $4}' | tr -d '+°C')
if [ -z "$TEMP" ]; then
    # Alternativa para algunos sistemas (AMD, etc.)
    TEMP=$(sensors | grep -m1 'Tctl' | awk '{print $2}' | tr -d '+°C')
fi
if [ -z "$TEMP" ]; then
    # Último recurso: leer desde hwmon (puede variar el número)
    for i in /sys/class/hwmon/hwmon*/temp1_input; do
        [ -e "$i" ] && TEMP=$(( $(cat "$i") / 1000 )) && break
    done
fi

echo "CPU:${TEMP:-N/A}°C"
