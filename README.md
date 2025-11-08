Proxmox on Raspberry Pi 4 - Preconfiguration Script
Este proyecto contiene un script de preconfiguración para instalar Proxmox VE en una Raspberry Pi 4.

⚠️ Requisitos y Compatibilidad
Dispositivo: Raspberry Pi 4

Sistema Operativo: Raspberry Pi OS Lite (64-bit)

Versión específica: 2025-05-13

Fecha de validez de repositorios: 08/11/2025

Descarga del Sistema Operativo
Descarga la imagen oficial desde:

text
https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2025-05-13/2025-05-13-raspios-bookworm-arm64-lite.img.xz
🛠️ Configuración Inicial
Paso 1: Flashear la Imagen
Usa el software oficial de Raspberry Pi Imager para flashear la imagen

Durante el flasheo, configura los siguientes ajustes:

Cambiar hostname

Configurar ubicación y teclado

Establecer usuario y contraseña

Activar conexión SSH (usando contraseña)

Paso 2: Primera Conexión y Preparación
Conéctate a la Raspberry Pi via SSH con tus credenciales

Ejecuta los siguientes comandos:

bash
sudo apt update
sudo apt upgrade -y
sudo apt install curl -y
Paso 3: Configurar Usuario Root
bash
sudo passwd root
Establece una contraseña para el usuario root (necesario para acceder a Proxmox posteriormente).

Paso 4: Reiniciar
bash
sudo reboot
Espera a que se reinicie y vuelve a conectarte via SSH.

🚀 Ejecutar Script de Preconfiguración
Ejecuta el siguiente comando para aplicar los preajustes:

bash
curl -fsSL https://raw.githubusercontent.com/xodaaaa/proxmox-on-raspberry/refs/heads/main/pxvirtpreps.sh | bash
Paso 5: Reiniciar Después del Script
bash
sudo reboot
📦 Instalación de Proxmox VE
Después del reinicio, ejecuta:

bash
sudo apt update
sudo apt install proxmox-ve pve-manager qemu-server pve-cluster -y
