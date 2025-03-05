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

> 为摄影师设计的快速简便的SD卡照片选择工具

<p align="center">
  <img src="https://github.com/user-attachments/assets/dc831121-a91c-4a3f-8d13-7aa247bcb379" alt="toricomi 演示" width="720">
</p>

https://github.com/user-attachments/assets/6cc2a8b5-f5ac-441a-8ce1-3b20ac004181

## ✨ 特点

- **简单界面** - 在终端上直观操作
- **快速预览** - 通过后台图像预加载实现流畅浏览体验
- **曝光调整** - 随时调整图像亮度
- **RAW支持** - 自动标记和处理DNG（RAW）文件
- **P3色彩空间** - 在支持的屏幕上增强色彩显示
- **高效工作流程** - 使用"Like"功能快速选择喜爱的照片

## 🚀 安装

### 要求

- macOS
- [iTerm2](https://iterm2.com/)
- imgcat（iTerm2的图像显示命令）

### 快速安装

```bash
# 克隆仓库
git clone https://github.com/yahirrro/toricomi.git
cd toricomi

# 使脚本可执行
chmod +x image_selector.sh

# 运行脚本
./image_selector.sh
```

### 推荐安装（增强版）

为了获得更好的体验，我们建议安装以下工具：

```bash
# 安装ImageMagick以进行高质量曝光调整
brew install imagemagick

# 安装DNG处理工具（选择一个）
brew install darktable   # 推荐
# 或
brew install rawtherapee
# 或
brew install dcraw
```

## 📖 使用方法

1. 将SD卡连接到Mac

2. 运行脚本

   ```bash
   # 使用默认语言（日语）运行
   ./image_selector.sh

   # 使用英语界面运行
   ./image_selector.sh -l en
   # 或
   ./image_selector.sh --lang en
   ```

3. 按照屏幕上的说明操作
   - 选择SD卡
   - 选择日期（或"全部"）
   - 浏览和选择照片

### 按键控制

| 按键      | 功能                    |
| --------- | ----------------------- |
| **↑/↓**   | 导航到上一张/下一张照片 |
| **←/→**   | 调整曝光（变暗/变亮）   |
| **Enter** | 将照片标记为"Like"      |
| **q**     | 退出                    |

## 🛠 详细功能

### 多语言支持

该脚本支持多种语言：

- 日语（默认）
- 英语

您可以使用 `-l` 或 `--lang` 选项指定语言：

```bash
# 使用英语界面运行
./image_selector.sh -l en
```

系统自动从 `lang/` 目录加载语言文件。

### 曝光调整

当照片太暗或太亮时，您可以使用←/→键调整曝光。如果安装了ImageMagick，可以获得更好的质量调整。

### DNG（RAW）文件处理

如果存在与JPEG文件对应的DNG文件，当您将JPEG标记为"Like"时，它将自动被标记。在脚本结束时，您可以将标记的DNG文件移动到指定文件夹。

### P3色彩空间支持

如果您有兼容P3色彩空间的显示器，您可以享受更生动的色彩显示。

## ⚙️ 自定义

您可以在脚本中自定义以下参数：

```bash
# 显示设置
TITLE_BAR_HEIGHT=30   # 标题栏高度（像素）
LINE_HEIGHT_PX=18     # 行高（像素）
MAX_IMG_WIDTH=2000    # 最大图像宽度（像素）

# 显示比例
SIZE_FACTOR=2         # 显示大小系数（1.0=原始大小，1.2=放大20%）

# 曝光调整设置
EXPOSURE_STEP=2       # 曝光调整步长
MAX_EXPOSURE=25       # 最大曝光值
MIN_EXPOSURE=-25      # 最小曝光值

# DNG处理设置
USE_DNG_FOR_EXPOSURE=1 # 使用DNG文件进行曝光调整（1=启用，0=禁用）
```

### 语言设置

toricomi支持多种语言。您可以通过设置`TORICOMI_LANG`环境变量来选择您喜欢的语言：

```bash
# 设置为英语
export TORICOMI_LANG=en

# 设置为日语
export TORICOMI_LANG=ja

# 设置为中文
export TORICOMI_LANG=zh

# 设置为西班牙语
export TORICOMI_LANG=es

# 设置为法语
export TORICOMI_LANG=fr
```

如果未指定语言，将默认使用英语。

## 🔍 故障排除

| 问题                       | 解决方案                          |
| -------------------------- | --------------------------------- |
| "iTerm2或imgcat命令不可用" | 确保已安装iTerm2并更新到最新版本  |
| 图像显示太小               | 增加脚本中的SIZE_FACTOR值         |
| DNG文件未被处理            | 安装darktable、rawtherapee或dcraw |
| 终端大小错误               | 增加终端窗口大小（至少24x80）     |

## 📝 待办事项

- [ ] 库模式（一次查看多个SD卡中的照片）
- [ ] 关键词标记功能
- [ ] 扩展元数据显示（拍摄设置、相机信息等）
- [ ] 多显示器支持

## 🤝 贡献

欢迎贡献！随时提交错误报告、功能请求或拉取请求。

## 👤 作者

- Yahiro Nakamoto ([@yahirrro](https://github.com/yahirrro))

## 📄 许可证

根据MIT许可证发布。有关详细信息，请参阅[LICENSE](LICENSE)文件。

---

<p align="center">
  为摄影师用❤️制作
</p>
