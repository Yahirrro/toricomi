# toricomi 📷

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-macOS-blue.svg)](https://www.apple.com/macos)
[![Bash](https://img.shields.io/badge/made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)

> 写真家のためのシンプルで高速なSDカード選別ツール

<p align="center">
  <img src="https://i.imgur.com/placeholder-image.png" alt="toricomi Demo" width="720">
</p>

## ✨ 特徴

- **シンプルなインターフェース** - ターミナル上で直感的に操作
- **高速プレビュー** - バックグラウンドでの画像プリロードによる快適な閲覧体験
- **露出調整** - その場で写真の明るさを調整
- **RAWサポート** - DNG（RAW）ファイルへの自動タグ付けと処理
- **P3色域対応** - より鮮やかな色表示（対応ディスプレイの場合）
- **効率的なワークフロー** - 「Like」機能でお気に入り写真を素早く選別

## 🚀 インストール

### 必須環境

- macOS
- [iTerm2](https://iterm2.com/)
- imgcat（iTerm2の画像表示コマンド）

### クイックインストール

```bash
# リポジトリをクローン
git clone https://github.com/yahirrro/toricomi.git
cd toricomi

# スクリプトに実行権限を付与
chmod +x image_selector.sh

# スクリプトを実行
./image_selector.sh
```

### 推奨インストール（高機能版）

より良い体験のために、以下のツールのインストールを推奨します：

```bash
# ImageMagickのインストール（高品質な露出調整用）
brew install imagemagick

# DNGファイル処理用ツール（いずれか一つ）
brew install darktable   # 推奨
# または
brew install rawtherapee
# または
brew install dcraw
```

## 📖 使い方

1. SDカードをMacに接続

2. スクリプトを実行

   ```bash
   ./image_selector.sh
   ```

3. 表示される指示に従って操作
   - SDカードを選択
   - 日付を選択（または「すべて」を選択）
   - 写真を閲覧・選別

### キー操作

| キー      | 機能                       |
| --------- | -------------------------- |
| **↑/↓**   | 前/次の写真に移動          |
| **←/→**   | 露出調整（暗く/明るく）    |
| **Enter** | 写真を「Like」としてマーク |
| **q**     | 終了                       |

## 🛠 機能詳細

### 露出調整

写真が暗すぎる/明るすぎる場合、←/→キーで露出を調整できます。ImageMagickがインストールされていると、より高品質な調整が可能です。

### DNG（RAW）ファイル処理

JPEGファイルに対応するDNGファイルが存在する場合、「Like」マークを付けると自動的にDNGファイルにもタグ付けされます。スクリプト終了時に、タグ付けされたDNGファイルを指定フォルダに移動することもできます。

### P3色域対応

P3色域対応ディスプレイをお使いの場合、より鮮やかな色表示が可能です。

## ⚙️ カスタマイズ

スクリプト内の以下の設定を変更することで、動作をカスタマイズできます：

```bash
# 表示設定
TITLE_BAR_HEIGHT=30   # タイトルバー等のピクセル高
LINE_HEIGHT_PX=18     # 1行あたりの高さ（ピクセル）
MAX_IMG_WIDTH=2000    # 画像の最大幅（ピクセル）

# 表示倍率調整
SIZE_FACTOR=2         # 表示サイズ倍率（1.0=そのまま、1.2=20%拡大）

# 露出調整設定
EXPOSURE_STEP=2       # 露出調整のステップ
MAX_EXPOSURE=25       # 最大露出値
MIN_EXPOSURE=-25      # 最小露出値

# DNG処理関連設定
USE_DNG_FOR_EXPOSURE=1 # DNGファイルを使用した露出調整（1=有効、0=無効）
```

## 🔍 トラブルシューティング

| 問題                                                  | 解決策                                                                                          |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| 「iTerm2 か imgcat コマンドが使えません」と表示される | iTerm2がインストールされていることを確認し、最新バージョンに更新してください                    |
| 画像が表示されない                                    | ターミナルサイズが小さすぎないか確認してください（24x80以上推奨）                               |
| DNG処理ができない                                     | 推奨ツール（darktable, rawtherapee, dcraw）のいずれかがインストールされているか確認してください |
| 画像表示が遅い                                        | `SIZE_FACTOR`の値を小さくして試してください                                                     |

## 📝 TODO

- [ ] ライブラリモード（複数のSDカードからの写真を一度に閲覧）
- [ ] キーワードタグ付け機能
- [ ] メタデータ表示の拡張（撮影設定、カメラ情報など）
- [ ] 複数ディスプレイのサポート

## 🤝 貢献

貢献は大歓迎です！バグ報告、機能リクエスト、プルリクエストなど、どんな形でも構いません。

## 👤 作者

- Yahiro Nakamoto ([@yahirrro](https://github.com/yahirrro))

## 📄 ライセンス

MITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルをご覧ください。

---

<p align="center">
  Made with ❤️ for photographers
</p>
