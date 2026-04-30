#!/bin/bash
# Script de automatización para la configuración post-instalación de Arch Linux
# Ejecutar como root (sudo).

set -e  # Detiene el script si algún comando falla

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Función para imprimir mensajes informativos
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    error "Este script debe ejecutarse como root (usa sudo)."
fi

# Obtener el nombre del usuario real (el que ejecutó sudo)
REAL_USER=${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}
if [ "$REAL_USER" = "root" ]; then
    error "Por favor, ejecuta este script con sudo desde un usuario normal, no directamente como root."
fi

# Resolver home y shell actuales del usuario real
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
USER_SHELL=$(getent passwd "$REAL_USER" | cut -d: -f7)
if [ -z "$USER_HOME" ] || [ -z "$USER_SHELL" ]; then
    error "No se pudo resolver home/shell del usuario $REAL_USER."
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info "Ejecutando para el usuario: $REAL_USER"

# --- 1. Actualizar el sistema ---
info "Actualizando el sistema..."
pacman -Syu --noconfirm

# --- 2. Instalar paquetes base (git, base-devel) si no están ---
info "Instalando git, base-devel y curl..."
pacman -S --needed --noconfirm git base-devel curl

# --- 3. Instalar yay (helper AUR) si no existe ---
if ! command -v yay &> /dev/null; then
    info "Instalando yay desde el AUR..."
    # Clonar y compilar como el usuario normal (no root) en dir temporal (idempotente)
    YAY_BUILD_DIR=$(mktemp -d /tmp/yay-build-XXXXXX)
    sudo -u "$REAL_USER" bash <<EOF
        cd "$YAY_BUILD_DIR"
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -s --noconfirm
EOF
    YAY_PKG=$(ls -1 "$YAY_BUILD_DIR"/yay/*.pkg.tar.* | head -n 1)
    if [ -z "$YAY_PKG" ]; then
        error "No se encontró el paquete compilado de yay."
    fi
    pacman -U --noconfirm "$YAY_PKG"
    rm -rf "$YAY_BUILD_DIR"
    info "yay instalado correctamente."
else
    info "yay ya está instalado, omitiendo."
fi

# --- 4. Lista de paquetes a instalar (oficiales y AUR) ---
# Paquetes oficiales (pacman)
PAC_PKGS=(
    hyprland
    sddm
    sddm-kcm
    waybar
    pipewire
    wireplumber
    kitty
    ttf-jetbrains-mono-nerd
    brightnessctl
    pamixer
    bluez-utils
    lm_sensors
    networkmanager
    pavucontrol-qt
    blueman
    fish
    fastfetch
    hyprlauncher
)

# Paquetes del AUR (se instalan con yay)
AUR_PKGS=(
    # (No hay ninguno específico en tu lista, pero puedes agregar aquí si es necesario)
)

# Instalar paquetes oficiales
info "Instalando paquetes del repositorio oficial..."
pacman -S --needed --noconfirm "${PAC_PKGS[@]}"

# Instalar paquetes del AUR (si hay)
if [ ${#AUR_PKGS[@]} -gt 0 ]; then
    info "Instalando paquetes del AUR..."
    sudo -u "$REAL_USER" yay -S --needed --noconfirm "${AUR_PKGS[@]}"
fi

# --- 5. Habilitar servicios del sistema ---
info "Habilitando servicios del sistema (bluetooth, NetworkManager, SDDM)..."
systemctl enable --now bluetooth
systemctl enable --now NetworkManager
systemctl enable sddm   # No se inicia ahora para no interrumpir, solo se habilita

# --- 6. Configurar PipeWire y WirePlumber (servicios por usuario) ---
info "Habilitando PipeWire y WirePlumber para el usuario..."
sudo -u "$REAL_USER" systemctl --user enable pipewire wireplumber || warn "No se pudieron habilitar servicios de usuario con systemd --user."
if loginctl enable-linger "$REAL_USER" 2>/dev/null; then
    sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" systemctl --user start pipewire wireplumber || warn "No se pudieron iniciar ahora PipeWire/WirePlumber; se iniciarán al próximo login."
else
    warn "No se pudo habilitar linger para $REAL_USER; PipeWire/WirePlumber iniciarán al próximo login."
fi

# --- 7. Copiar configuraciones del proyecto a ~/.config ---
info "Copiando carpetas del proyecto a $USER_HOME/.config..."
sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.config"
for dir in "$SCRIPT_DIR"/*/; do
    [ -d "$dir" ] || continue
    DIR_NAME=$(basename "$dir")
    TARGET_DIR="$USER_HOME/.config/$DIR_NAME"
    info "Copiando $DIR_NAME -> $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    cp -a "$dir/." "$TARGET_DIR/"
    chown -R "$REAL_USER:$REAL_USER" "$TARGET_DIR"
done

# Copiar configuración por defecto de Hyprland solo si no existe
if [ ! -f "$USER_HOME/.config/hypr/hyprland.conf" ]; then
    info "Copiando configuración por defecto de Hyprland..."
    cp /usr/share/hypr/hyprland.conf "$USER_HOME/.config/hypr/hyprland.conf"
    chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/hypr/hyprland.conf"
else
    warn "El archivo hyprland.conf ya existe, no se sobrescribe."
fi

# --- 8. Configurar Fish como shell por defecto ---
info "Cambiando el shell por defecto a fish para el usuario $REAL_USER..."
if [ "$USER_SHELL" != "/usr/bin/fish" ]; then
    chsh -s /usr/bin/fish "$REAL_USER"
    info "Shell cambiado. Para que surta efecto, cierra sesión y vuelve a iniciar."
else
    info "Fish ya es el shell por defecto."
fi

# --- 9. Instalar Fisher y Tide (plugin manager y tema para fish) ---
info "Instalando Fisher y Tide para fish..."
sudo -u "$REAL_USER" fish -c "
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
    fisher install IlanCosman/tide@v6
"
info "Configuración de Tide completada. Ejecuta 'tide configure' para personalizar el prompt."

# --- 10. Verificación final ---
info "¡Script completado exitosamente!"
echo "------------------------------------------------------------------------"
echo "Resumen de acciones realizadas:"
echo "- Sistema actualizado"
echo "- Paquetes instalados: ${#PAC_PKGS[@]} (oficiales) + ${#AUR_PKGS[@]} (AUR)"
echo "- Servicios habilitados: bluetooth, NetworkManager, sddm"
echo "- PipeWire/WirePlumber activado para el usuario"
echo "- Configuraciones del proyecto copiadas a ~/.config"
echo "- Shell cambiado a fish (requiere reinicio de sesión)"
echo "- Fisher y Tide instalados en fish"
echo "------------------------------------------------------------------------"
echo "Recomendaciones:"
echo "1. Reinicia el sistema para que todos los cambios surtan efecto (sudo reboot)."
echo "2. Después de reiniciar, ejecuta 'tide configure' para personalizar el prompt de fish."
echo "3. Personaliza el archivo ~/.config/hypr/hyprland.conf según tus necesidades."