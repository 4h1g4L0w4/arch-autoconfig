# Arch AutoConfig

Configuracion automatizada de entorno en Arch Linux, orientada a dejar un setup funcional y reproducible para escritorio basado en Hyprland.

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

---

## Que hace este proyecto

- Actualiza el sistema (`pacman -Syu`).
- Instala dependencias base y paquetes del entorno.
- Instala `yay` automaticamente si no existe.
- Habilita servicios esenciales (`bluetooth`, `NetworkManager`, `sddm`).
- Configura PipeWire/WirePlumber para el usuario real.
- Copia las carpetas de configuracion del repo a `~/.config`.
- Cambia shell por defecto a `fish` e instala Fisher + Tide.

---

## Estructura del repositorio

```text
.
├── autoinstall.sh
├── fish/
├── hypr/
├── kitty/
├── waybar/
└── assets/
    └── showcase/
```

---

## Instalacion rapida

```bash
git clone https://github.com/4h1g4L0w4/arch-autoconfig.git
cd arch-autoconfig
chmod +x autoinstall.sh
sudo ./autoinstall.sh
```

> Recomendado: ejecutar desde un usuario normal con `sudo`, no como root directo.

---

## Showcase

### Hyprland

![Hyprland Screenshot](assets/showcase/hyprland-main.png)

### Waybar

![Waybar Screenshot](assets/showcase/waybar.png)

### Terminal (Kitty + Fish/Tide)

![Terminal Screenshot](assets/showcase/terminal.png)

---

## Personalizacion

- Edita `hypr/hyprland.conf` para keybinds, layout y animaciones.
- Ajusta `waybar/` para modulos y estilo visual.
- Modifica `kitty/kitty.conf` para fuente/tema.
- Personaliza prompt con `tide configure`.

---

## Notas

- El script intenta ser idempotente, pero siempre revisa los cambios en tu entorno.
- Si usas dotfiles previos, haz backup de `~/.config` antes de correrlo.

---

## Roadmap

- [ ] Modo `--dry-run`.
- [ ] Separar instalacion por perfiles (minimal/full/dev).

---

## Licencia

MIT. Puedes usar, modificar y compartir este proyecto libremente.
