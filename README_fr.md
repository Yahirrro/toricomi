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

> Un outil rapide et facile de sélection de photos sur carte SD conçu pour les photographes

<p align="center">
  <img src="https://i.imgur.com/placeholder-image.png" alt="toricomi Demo" width="720">
</p>

## ✨ Fonctionnalités

- **Interface Simple** - Opération intuitive dans votre terminal
- **Aperçu Rapide** - Expérience de navigation fluide avec préchargement d'images en arrière-plan
- **Ajustement d'Exposition** - Réglez instantanément la luminosité des images
- **Support RAW** - Étiquetage et traitement automatiques des fichiers DNG (RAW)
- **Espace Colorimétrique P3** - Affichage des couleurs amélioré sur les écrans compatibles
- **Flux de Travail Efficace** - Sélectionnez rapidement vos photos préférées avec la fonction "Like"

## 🚀 Installation

### Prérequis

- macOS
- [iTerm2](https://iterm2.com/)
- imgcat (commande d'affichage d'images iTerm2)

### Installation Rapide

```bash
# Cloner le dépôt
git clone https://github.com/yahirrro/toricomi.git
cd toricomi

# Rendre le script exécutable
chmod +x image_selector.sh

# Exécuter le script
./image_selector.sh
```

### Installation Recommandée (Version Améliorée)

Pour une meilleure expérience, nous vous recommandons d'installer les outils suivants :

```bash
# Installer ImageMagick pour des ajustements d'exposition de haute qualité
brew install imagemagick

# Installer un outil de traitement DNG (choisissez-en un)
brew install darktable   # recommandé
# ou
brew install rawtherapee
# ou
brew install dcraw
```

## 📖 Utilisation

1. Connectez votre carte SD à votre Mac

2. Exécutez le script

   ```bash
   # Exécuter avec la langue par défaut (japonais)
   ./image_selector.sh

   # Exécuter avec l'interface en anglais
   ./image_selector.sh -l en
   # ou
   ./image_selector.sh --lang en
   ```

3. Suivez les instructions à l'écran
   - Sélectionnez la carte SD
   - Choisissez une date (ou "Tout")
   - Parcourez et sélectionnez les photos

### Contrôles Clavier

| Touche     | Fonction                                    |
| ---------- | ------------------------------------------- |
| **↑/↓**    | Naviguer vers la photo précédente/suivante  |
| **←/→**    | Ajuster l'exposition (plus sombre/lumineux) |
| **Entrée** | Marquer la photo comme "Like"               |
| **q**      | Quitter                                     |

## 🛠 Fonctionnalités Détaillées

### Support Multilingue

Le script prend en charge plusieurs langues :

- Japonais (par défaut)
- Anglais

Vous pouvez spécifier la langue en utilisant l'option `-l` ou `--lang` :

```bash
# Exécuter avec l'interface en anglais
./image_selector.sh -l en
```

Le système charge automatiquement les fichiers de langue à partir du répertoire `lang/`.

### Ajustement d'Exposition

Lorsque les photos sont trop sombres ou trop lumineuses, vous pouvez ajuster l'exposition à l'aide des touches ←/→. Des ajustements de meilleure qualité peuvent être obtenus si ImageMagick est installé.

### Traitement des Fichiers DNG (RAW)

Si un fichier DNG correspond à un fichier JPEG, il sera automatiquement étiqueté lorsque vous marquerez le JPEG comme "Like". À la fin du script, vous pouvez déplacer les fichiers DNG étiquetés vers un dossier spécifique.

### Support de l'Espace Colorimétrique P3

Si vous disposez d'un écran compatible avec l'espace colorimétrique P3, vous pouvez profiter d'un affichage des couleurs plus vibrant.

## ⚙️ Personnalisation

Vous pouvez personnaliser les paramètres suivants dans le script :

```bash
# Paramètres d'affichage
TITLE_BAR_HEIGHT=30   # Hauteur de la barre de titre en pixels
LINE_HEIGHT_PX=18     # Hauteur de ligne en pixels
MAX_IMG_WIDTH=2000    # Largeur maximale d'image en pixels

# Échelle d'affichage
SIZE_FACTOR=2         # Facteur de taille d'affichage (1.0=original, 1.2=20% plus grand)

# Paramètres d'ajustement d'exposition
EXPOSURE_STEP=2       # Pas d'ajustement d'exposition
MAX_EXPOSURE=25       # Valeur maximale d'exposition
MIN_EXPOSURE=-25      # Valeur minimale d'exposition

# Paramètres de traitement DNG
USE_DNG_FOR_EXPOSURE=1 # Utiliser les fichiers DNG pour l'ajustement d'exposition (1=activé, 0=désactivé)
```

### Paramètres de langue

toricomi prend en charge plusieurs langues. Vous pouvez définir votre langue préférée en configurant la variable d'environnement `TORICOMI_LANG` :

```bash
# Définir la langue en anglais
export TORICOMI_LANG=en

# Définir la langue en japonais
export TORICOMI_LANG=ja

# Définir la langue en chinois
export TORICOMI_LANG=zh

# Définir la langue en espagnol
export TORICOMI_LANG=es

# Définir la langue en français
export TORICOMI_LANG=fr
```

Si aucune langue n'est spécifiée, l'anglais sera utilisé par défaut.

## 🔍 Dépannage

| Problème                                            | Solution                                                          |
| --------------------------------------------------- | ----------------------------------------------------------------- |
| "iTerm2 ou la commande imgcat n'est pas disponible" | Assurez-vous qu'iTerm2 est installé et à jour                     |
| Les images apparaissent trop petites                | Augmentez le SIZE_FACTOR dans le script                           |
| Les fichiers DNG ne sont pas traités                | Installez darktable, rawtherapee ou dcraw                         |
| Erreur de taille du terminal                        | Augmentez la taille de votre fenêtre de terminal (au moins 24x80) |

## 📝 TODO

- [ ] Mode bibliothèque (voir les photos de plusieurs cartes SD à la fois)
- [ ] Fonction d'étiquetage par mots-clés
- [ ] Affichage étendu des métadonnées (paramètres de prise de vue, informations sur l'appareil, etc.)
- [ ] Support multi-écrans

## 🤝 Contributions

Les contributions sont les bienvenues ! N'hésitez pas à soumettre des rapports de bugs, des demandes de fonctionnalités ou des pull requests.

## 👤 Auteur

- Yahiro Nakamoto ([@yahirrro](https://github.com/yahirrro))

## 📄 Licence

Publié sous la Licence MIT. Consultez le fichier [LICENSE](LICENSE) pour plus de détails.

---

<p align="center">
  Fait avec ❤️ pour les photographes
</p>
