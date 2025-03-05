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

> A fast and simple SD card photo selection tool for photographers

<p align="center">
  <img src="https://github.com/user-attachments/assets/dc831121-a91c-4a3f-8d13-7aa247bcb379" alt="toricomi Demo" width="720">
</p>

https://github.com/user-attachments/assets/6cc2a8b5-f5ac-441a-8ce1-3b20ac004181

## ✨ Features

- **Simple Interface** - Intuitive operation in your terminal
- **Fast Preview** - Smooth browsing experience with background image preloading
- **Exposure Adjustment** - Adjust image brightness on the fly
- **RAW Support** - Automatic tagging and processing of DNG (RAW) files
- **P3 Color Space** - Enhanced color display on supported screens
- **Efficient Workflow** - Quickly select favorite photos with the "Like" feature

## 🚀 Installation

### Requirements

- macOS
- [iTerm2](https://iterm2.com/)
- imgcat (iTerm2's image display command)

### Quick Install

```bash
# Clone the repository
git clone https://github.com/yahirrro/toricomi.git
cd toricomi

# Make the script executable
chmod +x image_selector.sh

# Run the script
./image_selector.sh
```

### Recommended Installation (Enhanced Version)

For a better experience, we recommend installing the following tools:

```bash
# Install ImageMagick for high-quality exposure adjustments
brew install imagemagick

# Install a DNG processing tool (choose one)
brew install darktable   # recommended
# or
brew install rawtherapee
# or
brew install dcraw
```

## 📖 Usage

1. Connect your SD card to your Mac

2. Run the script

   ```bash
   # Run with default language (Japanese)
   ./image_selector.sh

   # Run with English interface
   ./image_selector.sh -l en
   # or
   ./image_selector.sh --lang en
   ```

3. Follow the on-screen instructions
   - Select your SD card
   - Choose a date (or "All")
   - Browse and select photos

### Key Controls

| Key       | Function                          |
| --------- | --------------------------------- |
| **↑/↓**   | Navigate to previous/next photo   |
| **←/→**   | Adjust exposure (darker/brighter) |
| **Enter** | Mark photo as "Like"              |
| **q**     | Quit                              |

## 🛠 Detailed Features

### Multilingual Support

The script supports multiple languages:

- Japanese (default)
- English

You can specify the language using the `-l` or `--lang` option:

```bash
# Run with English interface
./image_selector.sh -l en
```

The system automatically loads language files from the `lang/` directory.

### Exposure Adjustment

When photos are too dark or too bright, you can adjust the exposure using the ←/→ keys. Better quality adjustments are available if ImageMagick is installed.

### DNG (RAW) File Processing

If a DNG file exists corresponding to a JPEG file, it will automatically be tagged when you mark the JPEG as "Like". At the end of the script, you can move tagged DNG files to a specified folder.

### P3 Color Space Support

If you have a P3 color space compatible display, you can enjoy more vibrant color display.

## ⚙️ Customization

You can customize the following parameters in the script:

```bash
# Display settings
TITLE_BAR_HEIGHT=30   # Title bar height in pixels
LINE_HEIGHT_PX=18     # Line height in pixels
MAX_IMG_WIDTH=2000    # Maximum image width in pixels

# Display scale
SIZE_FACTOR=2         # Display size factor (1.0=original, 1.2=20% larger)

# Exposure adjustment settings
EXPOSURE_STEP=2       # Exposure adjustment step
MAX_EXPOSURE=25       # Maximum exposure value
MIN_EXPOSURE=-25      # Minimum exposure value

# DNG processing settings
USE_DNG_FOR_EXPOSURE=1 # Use DNG files for exposure adjustment (1=enabled, 0=disabled)
```

### Language Settings

toricomi supports multiple languages. You can set your preferred language by setting the `TORICOMI_LANG` environment variable:

```bash
# Set language to English
export TORICOMI_LANG=en

# Set language to Japanese
export TORICOMI_LANG=ja

# Set language to Chinese
export TORICOMI_LANG=zh

# Set language to Spanish
export TORICOMI_LANG=es

# Set language to French
export TORICOMI_LANG=fr
```

If no language is specified, English will be used as the default.

## 🔍 Troubleshooting

| Issue                                       | Solution                                            |
| ------------------------------------------- | --------------------------------------------------- |
| "iTerm2 or imgcat command is not available" | Make sure iTerm2 is installed and up to date        |
| Images appear too small                     | Increase the SIZE_FACTOR in the script              |
| DNG files are not processed                 | Install darktable, rawtherapee, or dcraw            |
| Terminal size error                         | Increase your terminal window size (at least 24x80) |

## 📝 TODO

- [ ] Library mode (view photos from multiple SD cards at once)
- [ ] Keyword tagging feature
- [ ] Extended metadata display (shooting settings, camera information, etc.)
- [ ] Multiple display support

## 🤝 Contributing

Contributions are welcome! Feel free to submit bug reports, feature requests, or pull requests.

## 👤 Author

- Yahiro Nakamoto ([@yahirrro](https://github.com/yahirrro))

## 📄 License

Released under the MIT License. See the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ for photographers
</p>
