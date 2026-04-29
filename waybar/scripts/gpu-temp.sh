#!/bin/bash
# Temperatura GPU AMD - ajusta la ruta si es necesario
# Busca automáticamente el sensor "edge" en la salida de 'sensors'
GPU_TEMP=$(sensors | grep -m1 'edge' | awk '{print $2}' | tr -d '+°C')
if [ -z "$GPU_TEMP" ]; then
    # Fallback: leer desde hwmon (puede variar el número)
    GPU_TEMP=$(cat /sys/class/hwmon/hwmon5/temp1_input 2>/dev/null)
    GPU_TEMP=$((GPU_TEMP / 1000))
fi
echo "GPU:${GPU_TEMP}°C"
