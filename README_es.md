# toricomi 📷

<p align="center">
  <a href="README.md">English</a> |
  <a href="README_ja.md">日本語</a> |
  <a href="README_zh.md">中文</a> |
  <a href="README_es.md">Español</a> |
  <a href="README_fr.md">Français</a>
</p>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-macOS-blue.svg)](https://www.apple.com/macos)
[![Bash](https://img.shields.io/badge/made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)

> Una herramienta rápida y sencilla de selección de fotos para tarjetas SD diseñada para fotógrafos

<p align="center">
  <img src="https://github.com/user-attachments/assets/dc831121-a91c-4a3f-8d13-7aa247bcb379" alt="toricomi Demo" width="720">
</p>

https://github.com/user-attachments/assets/6cc2a8b5-f5ac-441a-8ce1-3b20ac004181

## ✨ Características

- **Interfaz Sencilla** - Operación intuitiva en tu terminal
- **Vista Previa Rápida** - Experiencia de navegación fluida con precarga de imágenes en segundo plano
- **Ajuste de Exposición** - Ajusta el brillo de las imágenes al instante
- **Soporte RAW** - Etiquetado y procesamiento automático de archivos DNG (RAW)
- **Espacio de Color P3** - Visualización de colores mejorada en pantallas compatibles
- **Flujo de Trabajo Eficiente** - Selecciona rápidamente tus fotos favoritas con la función "Like"

## 🚀 Instalación

### Requisitos

- macOS
- [iTerm2](https://iterm2.com/)
- imgcat (comando de visualización de imágenes de iTerm2)

### Instalación Rápida

```bash
# Clonar el repositorio
git clone https://github.com/yahirrro/toricomi.git
cd toricomi

# Hacer el script ejecutable
chmod +x image_selector.sh

# Ejecutar el script
./image_selector.sh
```

### Instalación Recomendada (Versión Mejorada)

Para una mejor experiencia, recomendamos instalar las siguientes herramientas:

```bash
# Instalar ImageMagick para ajustes de exposición de alta calidad
brew install imagemagick

# Instalar una herramienta de procesamiento DNG (elige una)
brew install darktable   # recomendado
# o
brew install rawtherapee
# o
brew install dcraw
```

## 📖 Uso

1. Conecta tu tarjeta SD a tu Mac

2. Ejecuta el script

   ```bash
   # Ejecutar con el idioma predeterminado (japonés)
   ./image_selector.sh

   # Ejecutar con interfaz en inglés
   ./image_selector.sh -l en
   # o
   ./image_selector.sh --lang en
   ```

3. Sigue las instrucciones en pantalla
   - Selecciona la tarjeta SD
   - Elige una fecha (o "Todos")
   - Navega y selecciona fotos

### Controles de Teclado

| Tecla     | Función                                   |
| --------- | ----------------------------------------- |
| **↑/↓**   | Navegar a la foto anterior/siguiente      |
| **←/→**   | Ajustar exposición (más oscuro/brillante) |
| **Enter** | Marcar foto como "Like"                   |
| **q**     | Salir                                     |

## 🛠 Características Detalladas

### Soporte Multilingüe

El script admite varios idiomas:

- Japonés (predeterminado)
- Inglés

Puedes especificar el idioma usando la opción `-l` o `--lang`:

```bash
# Ejecutar con interfaz en inglés
./image_selector.sh -l en
```

El sistema carga automáticamente los archivos de idioma desde el directorio `lang/`.

### Ajuste de Exposición

Cuando las fotos están demasiado oscuras o brillantes, puedes ajustar la exposición usando las teclas ←/→. Se pueden lograr ajustes de mejor calidad si ImageMagick está instalado.

### Procesamiento de Archivos DNG (RAW)

Si existe un archivo DNG correspondiente a un archivo JPEG, será etiquetado automáticamente cuando marques el JPEG como "Like". Al final del script, puedes mover los archivos DNG etiquetados a una carpeta específica.

### Soporte para Espacio de Color P3

Si tienes una pantalla compatible con el espacio de color P3, puedes disfrutar de una visualización de colores más vibrante.

## ⚙️ Personalización

Puede personalizar los siguientes parámetros en el script:

```bash
# Configuración de visualización
TITLE_BAR_HEIGHT=30   # Altura de la barra de título en píxeles
LINE_HEIGHT_PX=18     # Altura de línea en píxeles
MAX_IMG_WIDTH=2000    # Ancho máximo de imagen en píxeles

# Escala de visualización
SIZE_FACTOR=2         # Factor de tamaño de visualización (1.0=original, 1.2=20% más grande)

# Configuración de ajuste de exposición
EXPOSURE_STEP=2       # Paso de ajuste de exposición
MAX_EXPOSURE=25       # Valor máximo de exposición
MIN_EXPOSURE=-25      # Valor mínimo de exposición

# Configuración de procesamiento DNG
USE_DNG_FOR_EXPOSURE=1 # Usar archivos DNG para ajuste de exposición (1=habilitado, 0=deshabilitado)
```

### Configuración de idioma

toricomi admite varios idiomas. Puede establecer su idioma preferido configurando la variable de entorno `TORICOMI_LANG`:

```bash
# Establecer idioma a inglés
export TORICOMI_LANG=en

# Establecer idioma a japonés
export TORICOMI_LANG=ja

# Establecer idioma a chino
export TORICOMI_LANG=zh

# Establecer idioma a español
export TORICOMI_LANG=es

# Establecer idioma a francés
export TORICOMI_LANG=fr
```

Si no se especifica ningún idioma, se utilizará el inglés como predeterminado.

## 🔍 Solución de Problemas

| Problema                                        | Solución                                                     |
| ----------------------------------------------- | ------------------------------------------------------------ |
| "iTerm2 o el comando imgcat no está disponible" | Asegúrese de que iTerm2 esté instalado y actualizado         |
| Las imágenes aparecen demasiado pequeñas        | Aumente el SIZE_FACTOR en el script                          |
| Los archivos DNG no se procesan                 | Instale darktable, rawtherapee o dcraw                       |
| Error de tamaño de terminal                     | Aumente el tamaño de la ventana de terminal (al menos 24x80) |

## 📝 TODO

- [ ] Modo biblioteca (ver fotos de múltiples tarjetas SD a la vez)
- [ ] Función de etiquetado con palabras clave
- [ ] Visualización extendida de metadatos (configuración de disparo, información de cámara, etc.)
- [ ] Soporte para múltiples pantallas

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! No dudes en enviar informes de errores, solicitudes de funciones o pull requests.

## 👤 Autor

- Yahiro Nakamoto ([@yahirrro](https://github.com/yahirrro))

## 📄 Licencia

Publicado bajo la Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.

---

<p align="center">
  Hecho con ❤️ para fotógrafos
</p>
