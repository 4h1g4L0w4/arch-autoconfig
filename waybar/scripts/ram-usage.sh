#!/bin/bash
# Calcula el porcentaje de uso de RAM
# Usa /proc/meminfo para obtener los valores

MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_AVAILABLE=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
if [ -z "$MEM_TOTAL" ] || [ -z "$MEM_AVAILABLE" ]; then
    echo "N/A"
    exit 1
fi
USED=$((MEM_TOTAL - MEM_AVAILABLE))
PERCENT=$(( 100 * USED / MEM_TOTAL ))
echo "RAM:${PERCENT}%"
