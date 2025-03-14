#!/usr/bin/env bash

##################################################
# 1) 前準備・共通関数
##################################################

# デバッグモード（1=有効、0=無効）
DEBUG=0

# likesフォルダ内のDNGファイルのベース名を保存する配列
declare -a LIKES_DNG_FILES

# likesフォルダ内のDNGファイルを検索し、配列に保存する関数
scan_likes_folder() {
  local sdcard="$1"
  LIKES_DNG_FILES=()
  
  if [ -d "$sdcard/likes" ]; then
    local likes_dir="$sdcard/likes"
    [ "$DEBUG" -eq 1 ] && echo "likesフォルダをスキャン中: $likes_dir"
    
    # likesフォルダ内のDNGファイルを検索
    while IFS= read -r dng_file; do
      if [ -f "$dng_file" ]; then
        # DNGファイルの拡張子を除いたベース名を取得
        local base_name=$(basename "${dng_file%.*}")
        LIKES_DNG_FILES+=("$base_name")
        [ "$DEBUG" -eq 1 ] && echo "likes内のDNGを検出: $base_name"
      fi
    done < <(find "$likes_dir" -type f \( -iname "*.dng" -o -iname "*.DNG" \) 2>/dev/null)
    
    [ "$DEBUG" -eq 1 ] && echo "likes内のDNG検出数: ${#LIKES_DNG_FILES[@]}"
  fi
}

# JPEGのベース名に対応するDNGがlikesフォルダ内にあるかチェックする関数
is_dng_in_likes() {
  local jpeg_base_name="$1"
  
  for likes_dng in "${LIKES_DNG_FILES[@]}"; do
    if [[ "$jpeg_base_name" == "$likes_dng" ]]; then
      return 0 # 見つかった場合は0を返す（成功）
    fi
  done
  
  return 1 # 見つからなかった場合は1を返す（失敗）
}

##################################################
# 多言語対応（国際化）設定
##################################################

# 言語設定 ("ja"=日本語, "en"=英語)
LANG_CODE=""

# コマンドライン引数の解析
parse_arguments() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -l|--lang)
        if [ -n "$2" ]; then
          LANG_CODE="$2"
          shift 2
        else
          echo "Error: Language code required after $1 option"
          exit 1
        fi
        ;;
      -d|--debug)
        DEBUG=1
        shift
        ;;
      *)
        shift
        ;;
    esac
  done
}

# システムの言語設定を自動検出
detect_system_language() {
  local sys_lang=""
  # システム言語設定の取得を試みる
  if [ -n "$LANG" ]; then
    sys_lang="${LANG%%_*}"
    sys_lang="${sys_lang%%.*}"
  fi

  # 対応している言語かチェック
  case "$sys_lang" in
    "ja") LANG_CODE="ja" ;;
    "en") LANG_CODE="en" ;;
    *) LANG_CODE="en" ;;  # デフォルトは英語
  esac

  [ "$DEBUG" -eq 1 ] && echo "システム言語: $sys_lang, 設定言語: $LANG_CODE"
}

# 言語設定を適用
apply_language_settings() {
  # 言語が未設定の場合、自動検出
  if [ -z "$LANG_CODE" ]; then
    detect_system_language
  fi

  # 言語ファイルのパス
  local lang_file="${script_dir}/lang/${LANG_CODE}.sh"
  
  # 言語ファイルが存在するか確認
  if [ -f "$lang_file" ]; then
    source "$lang_file"
  else
    # 言語ファイルがない場合、デフォルト（英語）を使用
    LANG_CODE="en"
    [ -f "${script_dir}/lang/en.sh" ] && source "${script_dir}/lang/en.sh"
  fi
  
  # どの言語ファイルも読み込めなかった場合は、インラインで定義されたメッセージを使用
  if [ -z "$MSG_TITLE" ]; then
    define_default_messages
  fi
}

# デフォルトメッセージ定義（言語ファイルが読み込めない場合のフォールバック）
define_default_messages() {
  # 日本語をデフォルトとして定義
  MSG_TITLE="画像選択ツール"
  MSG_SEARCHING="検索中"
  MSG_FILES_FOUND="ファイルが見つかりました"
  MSG_SELECT_SDCARD="SDカードを選択 (↑/↓, Enter)"
  MSG_SELECTED_SDCARD="選択されたSDカード"
  MSG_SEARCHING_JPEGS="JPEGファイルを検索中..."
  MSG_SEARCH_FILES="検索ファイル数"
  MSG_NO_JPEG_FILES="JPEGファイルがありません"
  MSG_TOTAL_JPEGS="合計 %d 個のJPEGファイル"
  MSG_COLLECTING_DATES="日付を集計中"
  MSG_DATES_FOUND="以下の日付が見つかりました (↑/↓, Enter):"
  MSG_SELECTED_DATE="選択された日付"
  MSG_ALL_DATES="すべて"
  MSG_SORTING_FILES="ファイル名でソート中..."
  MSG_FILTERED_FILES="絞り込まれたファイル数"
  MSG_PRESS_ANY_KEY="続行するにはキーを押してください..."
  MSG_EXPOSURE="露出"
  MSG_DNG="DNG"
  MSG_DNG_NONE="なし"
  MSG_DNG_TOOL_UNAVAILABLE="ツール不可"
  MSG_DNG_NO_TOOL="ツールなし"
  MSG_P3_SUPPORT="P3対応"
  MSG_PROGRESS="進捗"
  MSG_LIKE="Like"
  MSG_EXPOSURE_ADJ="露出調整"
  MSG_PREV_NEXT="前/次"
  MSG_EXIT="終了"
  MSG_SELECTION_RESULTS="選別結果:"
  MSG_LIKED_JPEGS="LikeされたJPEG: %d 個"
  MSG_TAGGED_DNGS="タグ付与済みDNG: %d 個"
  MSG_TAGGED_DNG_FILES="タグ付けされたDNGファイル: %d 個"
  MSG_SELECT_ACTION="選択してください (↑/↓, Enter):"
  MSG_MOVE_DNGS="DNGファイルを移動する"
  MSG_DONT_MOVE="移動しない"
  MSG_SELECT_DEST="移動先フォルダを選択してください (↑/↓, Enter):"
  MSG_CHECKED_FOLDER="チェック済みフォルダ"
  MSG_SELECTED_PHOTOS="選択写真"
  MSG_ENTER_NEW_FOLDER="新しいフォルダ名を入力"
  MSG_INPUT_FOLDER_NAME="新しいフォルダ名を入力してください："
  MSG_MOVING_FILES="DNGファイルを移動しています..."
  MSG_MOVED_FILES="%d 個のDNGファイルを「%s」に移動しました。"
  MSG_DNG_TAGGED="DNGにタグ付与: %s"
  MSG_NO_CORRESPONDING_DNG="対応DNGなしですが Like しました"
  MSG_IMG_NOT_FOUND="画像ファイルが見つかりません: %s"
  
  # ImageMagick関連
  MSG_IMAGEMAGICK_DETECTED="ImageMagick を検出しました。露出調整に使用します。"
  MSG_IMAGEMAGICK_NOT_FOUND="ImageMagick が見つかりません。sips を使用します。"
  MSG_IMAGEMAGICK_RECOMMEND="より良い露出調整のために ImageMagick のインストールをお勧めします。"
  MSG_IMAGEMAGICK_INSTALL="インストール方法: brew install imagemagick"
  
  # DNG処理関連
  MSG_DARKTABLE_DETECTED="darktable-cli を検出しました。DNG処理に使用します。"
  MSG_RAWTHERAPEE_DETECTED="rawtherapee-cli を検出しました。DNG処理に使用します。"
  MSG_DCRAW_DETECTED="dcraw を検出しました。DNG処理に使用します。"
  MSG_DCRAW_WORKING="dcrawは正常に動作しています。"
  MSG_DCRAW_NOT_WORKING="警告: dcrawが正常に動作しないようです。他のツールを使用します。"
  MSG_DNG_TOOL_NOT_FOUND="DNG処理ツールが見つかりません。JPEGを使用した露出調整に戻します。"
  MSG_DNG_TOOL_RECOMMEND="より高品質な処理のために darktable または rawtherapee のインストールをお勧めします。"
  MSG_DNG_TOOL_INSTALL="インストール方法: brew install darktable"
  
  # エラーメッセージ
  MSG_ERROR="エラー"
  MSG_WARNING="警告"
  MSG_TERMINAL_SIZE_ERROR="エラー: ターミナルサイズが小さすぎます(24x80以上推奨)"
  MSG_SEARCHING_SDCARD="利用可能なSDカードを探しています..."
  MSG_NO_VOLUMES_DIR="/Volumes ディレクトリがありません"
  MSG_NO_VOLUMES="利用可能なボリュームがありません"
  MSG_NO_SDCARD="SDカードが見つかりません"
  MSG_ITERM_ERROR="エラー: iTerm2 か imgcat コマンドが使えません。"

  # Like関連
  MSG_LIKES_FOUND="この日付のDNGがlikesフォルダで見つかりました"
  MSG_CONTINUE_FROM_LAST="最後にlikeした写真から続けますか？"
  MSG_YES="はい"
  MSG_NO="いいえ"
  MSG_START_FROM_BEGINNING="最初から始める"
}

# 表示設定 (必要に応じて環境に合わせて調整)
TITLE_BAR_HEIGHT=30   # タイトルバー等のピクセル高（小さくして実質的な表示領域を広げる）
LINE_HEIGHT_PX=18     # 1行あたりの高さ（ピクセル）（小さくして実質的な行数を増やす）
MAX_IMG_WIDTH=2000    # 画像の最大幅（ピクセル）

# 表示倍率調整（大きくすると画像が大きく表示される）
SIZE_FACTOR=2       # 表示サイズ倍率（1.0=そのまま、1.2=20%拡大）

# 露出調整設定
EXPOSURE_STEP=2       # 露出調整のステップ（大きくすると一度の調整幅が大きくなる）
MAX_EXPOSURE=25       # 最大露出値
MIN_EXPOSURE=-25      # 最小露出値
current_exposure=0    # 現在の露出値

# DNG処理関連設定
USE_DNG_FOR_EXPOSURE=1   # DNGファイルを使用した露出調整（1=有効、0=無効）
DNG_PROCESSOR=""         # 使用するDNG処理ツール ("darktable", "rawtherapee", "dcraw")

# ImageMagick関連
USE_IMAGEMAGICK=1     # ImageMagickを使用するか（1=有効、0=無効）
IMAGEMAGICK_CHECKED=0 # ImageMagickのチェック済みフラグ

# 露出調整済み画像保存用ディレクトリ
exposure_dir=""

# P3色域対応設定
USE_P3_COLORSPACE=1   # P3色域対応（1=有効、0=無効）
P3_PROFILE="/System/Library/ColorSync/Profiles/Display P3.icc"  # P3プロファイルのパス

# スクリプトのディレクトリパスを設定
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
temp_dir="${script_dir}/temp_images"
mkdir -p "$temp_dir"
mkdir -p "${script_dir}/lang"

# バックグラウンドプリロード用PID配列
declare -a bg_pids=()

cleanup_bg_processes() {
  for pid in "${bg_pids[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null
    fi
  done
  bg_pids=()
}

cleanup() {
  cleanup_bg_processes
  rm -rf "$temp_dir"
  tput cnorm
}
trap cleanup EXIT
trap 'cleanup; exit 130' SIGINT SIGTERM

# ImageMagickのインストール確認
check_imagemagick() {
  if [ $IMAGEMAGICK_CHECKED -eq 1 ]; then
    return $USE_IMAGEMAGICK
  fi
  
  IMAGEMAGICK_CHECKED=1
  
  if command -v convert >/dev/null 2>&1; then
    echo -e "${MSG_IMAGEMAGICK_DETECTED}"
    USE_IMAGEMAGICK=1
    return 0
  else
    echo -e "${MSG_IMAGEMAGICK_NOT_FOUND}"
    echo -e "${MSG_IMAGEMAGICK_RECOMMEND}"
    echo -e "${MSG_IMAGEMAGICK_INSTALL}"
    USE_IMAGEMAGICK=0
    return 1
  fi
}

# DNG処理ツールの確認
check_dng_processor() {
  if [ -n "$DNG_PROCESSOR" ] && [ "$DNG_PROCESSOR" != "none" ]; then
    return 0
  fi
  
  # darktableのチェック
  if command -v darktable-cli >/dev/null 2>&1; then
    echo -e "${MSG_DARKTABLE_DETECTED}"
    DNG_PROCESSOR="darktable"
    return 0
  fi
  
  # rawtherapeeのチェック
  if command -v rawtherapee-cli >/dev/null 2>&1; then
    echo -e "${MSG_RAWTHERAPEE_DETECTED}"
    DNG_PROCESSOR="rawtherapee"
    return 0
  fi
  
  # dcrawのチェック
  if command -v dcraw >/dev/null 2>&1; then
    echo -e "${MSG_DCRAW_DETECTED}"
    
    # dcrawが正常に動作するか簡易テスト
    if timeout 5 dcraw -v >/dev/null 2>&1; then
      echo -e "${MSG_DCRAW_WORKING}"
      DNG_PROCESSOR="dcraw"
      return 0
    else
      echo -e "${MSG_DCRAW_NOT_WORKING}"
    fi
  fi
  
  echo -e "${MSG_DNG_TOOL_NOT_FOUND}"
  echo -e "${MSG_DNG_TOOL_RECOMMEND}"
  echo -e "${MSG_DNG_TOOL_INSTALL}"
  DNG_PROCESSOR="none"
  return 1
}

# ANSIカラー
PINK='\033[1;38;5;213m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
RESET='\033[0m'
HIGHLIGHT='\033[7m'

# 2つの方法でウィンドウサイズを取得（より信頼性を高めるため）
get_iterm_window_size() {
  local bounds=""
  local method1_success=0
  
  # 方法1: AppleScriptでiTerm2のウィンドウサイズを取得
  bounds=$(osascript <<EOF
tell application "iTerm2"
  set win to current window
  set {l, t, r, b} to bounds of win
  return (r - l) & "," & (b - t)
end tell
EOF
)

  # デバッグ: 生の出力を確認
  [ "$DEBUG" -eq 1 ] && echo "AppleScript出力: 「$bounds」"

  # 「幅,高さ」形式をパース
  window_width_px="${bounds%%,*}"
  window_height_px=$(echo "${bounds##*,}" | tr -d '[:space:]')
  
  # 値が有効かチェック
  if [ -n "$window_width_px" ] && [ "$window_width_px" -gt 100 ] && \
     [ -n "$window_height_px" ] && [ "$window_height_px" -gt 100 ]; then
    method1_success=1
    [ "$DEBUG" -eq 1 ] && echo "方法1: ウィンドウサイズ: ${window_width_px}x${window_height_px}px (成功)"
  else
    [ "$DEBUG" -eq 1 ] && echo "方法1: サイズ取得に失敗"
  fi
  
  # 方法2: ターミナルの文字数とサイズから計算
  if [ $method1_success -eq 0 ]; then
    local cols=$(tput cols)
    local lines=$(tput lines)
    local char_width=8  # 平均的な文字幅（ピクセル）
    local char_height=$LINE_HEIGHT_PX
    
    window_width_px=$((cols * char_width))
    window_height_px=$((lines * char_height))
    
    [ "$DEBUG" -eq 1 ] && echo "方法2: ターミナルサイズ ${cols}x${lines} 文字 から計算"
    [ "$DEBUG" -eq 1 ] && echo "方法2: ウィンドウサイズ: ${window_width_px}x${window_height_px}px"
  fi
  
  # 最終確認と調整
  if [ -z "$window_width_px" ] || [ "$window_width_px" -lt 100 ]; then
    [ "$DEBUG" -eq 1 ] && echo "警告: 幅の取得に失敗したためデフォルト値を使用します"
    window_width_px=800
  fi
  
  if [ -z "$window_height_px" ] || [ "$window_height_px" -lt 100 ]; then
    [ "$DEBUG" -eq 1 ] && echo "警告: 高さの取得に失敗したためデフォルト値を使用します"
    window_height_px=600
  fi
}


##################################################
# 2) プリロード関連
##################################################

# P3プロファイルが存在するか確認
check_p3_profile() {
  if [ "$USE_P3_COLORSPACE" -eq 1 ] && [ ! -f "$P3_PROFILE" ]; then
    [ "$DEBUG" -eq 1 ] && echo "警告: 指定されたP3プロファイル「$P3_PROFILE」が見つかりません、代替を試みます"
    # 代替プロファイルのパスを確認
    local alt_profiles=(
      "/System/Library/ColorSync/Profiles/Display P3.icc"
      "/System/Library/ColorSync/Profiles/Apple Display P3.icc"
      "/Library/ColorSync/Profiles/Display P3.icc"
    )
    
    for profile in "${alt_profiles[@]}"; do
      if [ -f "$profile" ]; then
        P3_PROFILE="$profile"
        [ "$DEBUG" -eq 1 ] && echo "代替P3プロファイルを使用: $P3_PROFILE"
        return 0
      fi
    done
    
    # プロファイルが見つからない場合は無効化
    [ "$DEBUG" -eq 1 ] && echo "有効なP3プロファイルが見つからないため、P3色域処理を無効化します"
    USE_P3_COLORSPACE=0
  fi
}

# 画像リサイズと色域変換を行う
preload_image() {
  local file="$1"
  local output="$2"
  local bg="$3"

  if [ ! -f "$file" ]; then
    return 1
  fi

  # 既にリサイズ済みがあればスキップ
  if [ -f "$output" ]; then
    return 0
  fi

  # P3プロファイルの確認
  check_p3_profile

  # バックグラウンド処理
  if [ "$bg" = "bg" ]; then
    {
      local tmp_out="${output}.tmp"
      if cp "$file" "$tmp_out" 2>/dev/null; then
        # リサイズとP3色域変換
        if [ "$USE_P3_COLORSPACE" -eq 1 ] && [ -f "$P3_PROFILE" ]; then
          # sipsで画像リサイズとプロファイル適用を行う
          if sips -Z 1200 "$tmp_out" &>/dev/null && \
             sips --matchTo "$P3_PROFILE" "$tmp_out" &>/dev/null; then
            [ "$DEBUG" -eq 1 ] && echo "P3色域変換成功: $(basename "$tmp_out")"
          else
            [ "$DEBUG" -eq 1 ] && echo "P3色域変換失敗: $(basename "$tmp_out") - 通常リサイズのみ実行"
            sips -Z 1200 "$tmp_out" &>/dev/null
          fi
        else
          # 従来のリサイズのみ
          sips -Z 1200 "$tmp_out" &>/dev/null
        fi
        mv "$tmp_out" "$output" 2>/dev/null
        rm -f "$tmp_out" 2>/dev/null
      fi
    } &
    bg_pids+=($!)
    return 0
  fi

  # フォアグラウンド処理
  if ! cp "$file" "$output"; then
    echo "エラー: コピー失敗: $(basename "$file")" >&2
    return 1
  fi

  # リサイズとP3色域変換（フォアグラウンド）
  if [ "$USE_P3_COLORSPACE" -eq 1 ] && [ -f "$P3_PROFILE" ]; then
    # サイズ変更
    if ! sips -Z 1200 "$output" &>/dev/null; then
      [ "$DEBUG" -eq 1 ] && echo "警告: リサイズ失敗: $(basename "$output")"
    fi
    
    # P3プロファイル適用
    if ! sips --matchTo "$P3_PROFILE" "$output" &>/dev/null; then
      [ "$DEBUG" -eq 1 ] && echo "警告: P3色域変換失敗: $(basename "$output")"
    else
      [ "$DEBUG" -eq 1 ] && echo "P3色域変換成功: $(basename "$output")"
    fi
  else
    # 従来のリサイズのみ
    sips -Z 1200 "$output" &>/dev/null || true
  fi
}

# 周辺画像をバックグラウンドでプリロード
manage_preload_queue() {
  local current="$1"
  local total="$2"
  cleanup_bg_processes
  for offset in {-3..3}; do
    local idx=$((current + offset))
    if [ $idx -ge 0 ] && [ $idx -lt $total ] && [ $idx != $current ]; then
      local jpeg="${sorted_files[$idx]}"
      local resized="${temp_dir}/$(basename "$jpeg")"
      [ ! -f "$resized" ] && preload_image "$jpeg" "$resized" "bg"
    fi
  done
}

# 露出調整した画像を作成する関数
adjust_exposure() {
  local input="$1"
  local output="$2"
  local exposure="$3"
  local bg="$4"
  
  if [ ! -f "$input" ]; then
    return 1
  fi
  
  # 露出値が0の場合は元の画像をそのまま使用
  if [ "$exposure" -eq 0 ]; then
    if [ ! -f "$output" ]; then
      cp "$input" "$output" 2>/dev/null
    fi
    return 0
  fi
  
  # 既に調整済みの画像があればスキップ
  if [ -f "$output" ]; then
    return 0
  fi
  
  # ImageMagickが利用可能か確認
  check_imagemagick
  
  # バックグラウンド処理
  if [ "$bg" = "bg" ]; then
    {
      local tmp_out="${output}.tmp"
      
      if [ $USE_IMAGEMAGICK -eq 1 ]; then
        # ImageMagickを使用した露出調整
        # 露出値を-100〜100の範囲でスケーリング（明るさ調整用）
        local brightness=$(echo "scale=2; $exposure * 3" | bc)
        
        # contrast値も少し調整して画像をより鮮明に
        local contrast=0
        if [ "$exposure" -gt 0 ]; then
          # 明るくする場合はコントラストも少し上げる
          contrast=$(echo "scale=2; $exposure * 1.5" | bc)
        else
          # 暗くする場合はコントラストをより上げる
          contrast=$(echo "scale=2; ${exposure#-} * 2" | bc)
        fi
        
        if cp "$input" "$tmp_out" 2>/dev/null; then
          # -brightness-contrast: 明るさとコントラストを調整
          # 明るさの変化を強調するため、モジュレーションも追加
          if [ "$exposure" -gt 0 ]; then
            # 明るくする場合
            convert "$tmp_out" -brightness-contrast ${brightness}x${contrast} \
              -modulate $(echo "100 + $exposure * 2" | bc),100,100 "$tmp_out" 2>/dev/null
          else
            # 暗くする場合
            convert "$tmp_out" -brightness-contrast ${brightness}x${contrast} \
              -modulate $(echo "100 + $exposure * 2" | bc),100,100 "$tmp_out" 2>/dev/null
          fi
          mv "$tmp_out" "$output" 2>/dev/null
          rm -f "$tmp_out" 2>/dev/null
          [ "$DEBUG" -eq 1 ] && echo "ImageMagick露出調整成功（${brightness}）: $(basename "$output")"
        fi
      else
        # ImageMagickがない場合はsipsを使用
        local exp_value=$(echo "scale=2; $exposure / 100" | bc)
        if cp "$input" "$tmp_out" 2>/dev/null; then
          sips --setProperty brightness "$exp_value" "$tmp_out" &>/dev/null
          mv "$tmp_out" "$output" 2>/dev/null
          rm -f "$tmp_out" 2>/dev/null
          [ "$DEBUG" -eq 1 ] && echo "sips露出調整成功（$exp_value）: $(basename "$output")"
        fi
      fi
    } &
    bg_pids+=($!)
    return 0
  fi
  
  # フォアグラウンド処理
  local tmp_out="${output}.tmp"
  
  if [ $USE_IMAGEMAGICK -eq 1 ]; then
    # ImageMagickを使用した露出調整
    local brightness=$(echo "scale=2; $exposure * 3" | bc)
    
    # contrast値も少し調整して画像をより鮮明に
    local contrast=0
    if [ "$exposure" -gt 0 ]; then
      # 明るくする場合はコントラストも少し上げる
      contrast=$(echo "scale=2; $exposure * 1.5" | bc)
    else
      # 暗くする場合はコントラストをより上げる
      contrast=$(echo "scale=2; ${exposure#-} * 2" | bc)
    fi
    
    if cp "$input" "$tmp_out" 2>/dev/null; then
      if [ "$exposure" -gt 0 ]; then
        # 明るくする場合
        convert "$tmp_out" -brightness-contrast ${brightness}x${contrast} \
          -modulate $(echo "100 + $exposure * 2" | bc),100,100 "$tmp_out" 2>/dev/null
      else
        # 暗くする場合
        convert "$tmp_out" -brightness-contrast ${brightness}x${contrast} \
          -modulate $(echo "100 + $exposure * 2" | bc),100,100 "$tmp_out" 2>/dev/null
      fi
      mv "$tmp_out" "$output" 2>/dev/null
      rm -f "$tmp_out" 2>/dev/null
      [ "$DEBUG" -eq 1 ] && echo "ImageMagick露出調整成功（${brightness}）: $(basename "$output")"
    fi
  else
    # ImageMagickがない場合はsipsを使用
    local exp_value=$(echo "scale=2; $exposure / 100" | bc)
    if cp "$input" "$tmp_out" 2>/dev/null; then
      sips --setProperty brightness "$exp_value" "$tmp_out" &>/dev/null
      mv "$tmp_out" "$output" 2>/dev/null
      rm -f "$tmp_out" 2>/dev/null
      [ "$DEBUG" -eq 1 ] && echo "sips露出調整成功（$exp_value）: $(basename "$output")"
    fi
  fi
}

# 現在の画像に露出調整を適用
apply_exposure_to_current() {
  local jpeg="${sorted_files[$current_index]}"
  local base_name="$(basename "$jpeg")"
  local resized_jpeg="${temp_dir}/$base_name"
  
  # 露出調整用ディレクトリがなければ作成
  if [ -z "$exposure_dir" ]; then
    exposure_dir="${temp_dir}/exposure"
    mkdir -p "$exposure_dir"
  fi
  
  # まずリサイズ済み画像があることを確認
  if [ ! -f "$resized_jpeg" ]; then
    preload_image "$jpeg" "$resized_jpeg"
  fi
  
  # 露出調整した画像のパス
  local exposed_jpeg="${exposure_dir}/${current_exposure}_${base_name}"
  
  # 対応するDNGファイルを探す
  local dng_file=""
  if [ $USE_DNG_FOR_EXPOSURE -eq 1 ] && [ "$DNG_PROCESSOR" != "none" ]; then
    dng_file=$(find_corresponding_dng "$jpeg")
  fi
  
  # 既に調整済み画像があればそれを使用
  if [ -f "$exposed_jpeg" ]; then
    # 次の露出値も事前に計算してバックグラウンドで準備
    prepare_next_exposure_values
    echo "$exposed_jpeg"
    return 0
  fi
  
  # DNG処理
  if [ $USE_DNG_FOR_EXPOSURE -eq 1 ] && [ -n "$dng_file" ] && [ "$DNG_PROCESSOR" != "none" ]; then
    [ "$DEBUG" -eq 1 ] && echo "DNG処理を試みます: $(basename "$dng_file")"
    
    # 露出値が0の場合は元の画像をそのまま使用
    if [ "$current_exposure" -eq 0 ]; then
      cp "$resized_jpeg" "$exposed_jpeg" 2>/dev/null
    else
      # DNG処理
      process_dng_with_exposure "$dng_file" "$exposed_jpeg" "$current_exposure"
      
      # DNG処理が失敗した場合はJPEGで処理
      if [ ! -f "$exposed_jpeg" ]; then
        [ "$DEBUG" -eq 1 ] && echo "DNG処理失敗、JPEGで代替処理します"
        adjust_exposure "$resized_jpeg" "$exposed_jpeg" "$current_exposure"
      fi
    fi
  else
    # DNGがない場合やDNG処理無効の場合はJPEGで処理
    [ "$DEBUG" -eq 1 ] && echo "JPEG処理を使用します"
    adjust_exposure "$resized_jpeg" "$exposed_jpeg" "$current_exposure"
  fi
  
  # 次の露出値も事前に計算してバックグラウンドで準備
  prepare_next_exposure_values
  
  # 露出調整済み画像のパスを返す
  echo "$exposed_jpeg"
}

# 次の露出値を事前に準備
prepare_next_exposure_values() {
  local jpeg="${sorted_files[$current_index]}"
  local base_name="$(basename "$jpeg")"
  local resized_jpeg="${temp_dir}/$base_name"
  local next_exposure_plus=$((current_exposure + EXPOSURE_STEP))
  local next_exposure_minus=$((current_exposure - EXPOSURE_STEP))
  
  # 対応するDNGファイルを探す
  local dng_file=""
  if [ $USE_DNG_FOR_EXPOSURE -eq 1 ] && [ "$DNG_PROCESSOR" != "none" ]; then
    dng_file=$(find_corresponding_dng "$jpeg")
  fi
  
  if [ $next_exposure_plus -le $MAX_EXPOSURE ]; then
    local next_plus="${exposure_dir}/${next_exposure_plus}_${base_name}"
    if [ ! -f "$next_plus" ]; then
      if [ $USE_DNG_FOR_EXPOSURE -eq 1 ] && [ -n "$dng_file" ] && [ "$DNG_PROCESSOR" != "none" ]; then
        process_dng_with_exposure "$dng_file" "$next_plus" "$next_exposure_plus" "bg"
      else
        adjust_exposure "$resized_jpeg" "$next_plus" "$next_exposure_plus" "bg"
      fi
    fi
  fi
  
  if [ $next_exposure_minus -ge $MIN_EXPOSURE ]; then
    local next_minus="${exposure_dir}/${next_exposure_minus}_${base_name}"
    if [ ! -f "$next_minus" ]; then
      if [ $USE_DNG_FOR_EXPOSURE -eq 1 ] && [ -n "$dng_file" ] && [ "$DNG_PROCESSOR" != "none" ]; then
        process_dng_with_exposure "$dng_file" "$next_minus" "$next_exposure_minus" "bg"
      else
        adjust_exposure "$resized_jpeg" "$next_minus" "$next_exposure_minus" "bg"
      fi
    fi
  fi
}

##################################################
# 3) 画像表示 (行数換算ロジックの修正)
##################################################
display_image() {
  cleanup_bg_processes

  local jpeg="${sorted_files[$current_index]}"
  local base_name="$(basename "$jpeg")"
  local resized_jpeg="${temp_dir}/$base_name"

  # clearの代わりに、画面全体をクリアして、カーソルを画面の最上部に移動
  tput clear
  tput cup 0 0

  # --- (A) ヘッダーを「6行」出力 ---
  # 現在の写真がLIKE済みかどうかをチェック
  local is_liked=0
  for liked_file in "${LIKED_FILES[@]}"; do
    if [[ "$liked_file" == "$jpeg" ]]; then
      is_liked=1
      break
    fi
  done

  # likesフォルダ内のDNGを表示した場合、自動的にLIKE状態にする
  if [ $is_liked -eq 0 ]; then
    # 現在表示しているJPEGのファイル名（拡張子なし）
    local base_name=$(basename "${jpeg%.*}")
    
    # 特定のファイル名の場合
    if [ "$base_name" = "L1031363" ]; then
      [ "$DEBUG" -eq 1 ] && echo "特定ファイル検出: L1031363.JPG"
      # likesフォルダ内に対応するDNGがあるかチェック
      if is_dng_in_likes "$base_name"; then
        [ "$DEBUG" -eq 1 ] && echo "L1031363.DNGがlikesフォルダ内に存在します"
        is_liked=1
      fi
    else
      # その他の一般的なファイルの場合
      if is_dng_in_likes "$base_name"; then
        [ "$DEBUG" -eq 1 ] && echo "${base_name}.DNGがlikesフォルダ内に存在します"
        is_liked=1
      fi
    fi
  fi

  # --- 新しいヘッダー表示（コンパクト版） ---
  # 1行目：基本情報（ファイル名、インデックス、日付）
  local like_mark=""
  local file_name_display="${base_name}"
  if [[ $is_liked -eq 1 ]]; then
    like_mark="${PINK}💕 ${RESET}"
    file_name_display="${PINK}\033[1m${base_name}${RESET}"
  fi
  local date_str=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$jpeg")
  echo -e "${YELLOW}📷${RESET} ${like_mark}${file_name_display} ${YELLOW}🔢 $((current_index + 1))/${total_files}${RESET} ${YELLOW}📅${RESET} ${date_str}"

  # 2行目：露出調整とDNG処理情報
  local exposure_str="${MSG_EXPOSURE}:0"
  if [ $current_exposure -gt 0 ]; then
    exposure_str="${GREEN}${MSG_EXPOSURE}:+${current_exposure}${RESET}"
  elif [ $current_exposure -lt 0 ]; then
    exposure_str="${PINK}${MSG_EXPOSURE}:${current_exposure}${RESET}"
  else
    exposure_str="${MSG_EXPOSURE}:0"
  fi

  # DNG処理状態
  local dng_str=""
  if [ $USE_DNG_FOR_EXPOSURE -eq 1 ]; then
    if [ -n "$DNG_PROCESSOR" ] && [ "$DNG_PROCESSOR" != "none" ]; then
      local dng_file=$(find_corresponding_dng "$jpeg")
      if [ -n "$dng_file" ]; then
        dng_str="${GREEN}🖼️ ${MSG_DNG}:$DNG_PROCESSOR${RESET}"
      else
        dng_str="${PINK}🖼️ ${MSG_DNG}:${MSG_DNG_NONE}${RESET}"
      fi
    elif [ "$DNG_PROCESSOR" = "none" ]; then
      dng_str="${PINK}🖼️ ${MSG_DNG}:${MSG_DNG_TOOL_UNAVAILABLE}${RESET}"
    else
      dng_str="${PINK}🖼️ ${MSG_DNG}:${MSG_DNG_NO_TOOL}${RESET}"
    fi
  fi

  # P3色域情報
  local p3_str=""
  [ "$USE_P3_COLORSPACE" -eq 1 ] && [ -f "$P3_PROFILE" ] && p3_str="${GREEN}🌈 ${MSG_P3_SUPPORT}${RESET}"

  # 2行目を表示
  echo -e "${exposure_str}  ${dng_str}  ${p3_str}"

  # ヘッダーの区切り線
  echo -e "${YELLOW}$(printf '%*s' "$term_cols" | tr ' ' '=')${RESET}"

  local header_lines=3  # ヘッダー行数が3行になった

  # --- 事前にリサイズ済みでなければ作る ---
  if [ ! -f "$resized_jpeg" ]; then
    preload_image "$jpeg" "$resized_jpeg"
  fi

  if [ ! -f "$resized_jpeg" ]; then
    echo "画像ファイルが見つかりません: ${base_name}"
  else
    # 露出調整した画像を取得
    local display_jpeg="$resized_jpeg"
    if [ $current_exposure -ne 0 ]; then
      display_jpeg=$(apply_exposure_to_current)
    fi
    
    # 画像の元ピクセルサイズ
    local iw ih
    iw=$(sips -g pixelWidth  "$display_jpeg" | awk '/pixelWidth:/{print $2}')
    ih=$(sips -g pixelHeight "$display_jpeg" | awk '/pixelHeight:/{print $2}')
    [ -z "$iw" ] && iw=100
    [ -z "$ih" ] && ih=100

    # --- (B) iTerm2のウィンドウサイズ(px)を取得 ---
    get_iterm_window_size
    # window_width_px / window_height_px が得られる

    # タイトルバー等を差し引き
    local usable_window_height=$(( window_height_px - TITLE_BAR_HEIGHT ))
    ((usable_window_height<1)) && usable_window_height=1

    # ヘッダー行 + フッター行を差し引いて画像に使える行数
    local footer_lines=3
    local total_lines=$(( usable_window_height / LINE_HEIGHT_PX ))
    local available_lines=$(( total_lines - header_lines - footer_lines ))
    if [ $available_lines -lt 1 ]; then
      available_lines=1
    fi

    # 画像に使える最大高さ(px)
    local max_h=$(( available_lines * LINE_HEIGHT_PX ))
    ((max_h<1)) && max_h=1

    # 横方向はウィンドウ幅いっぱいに使えると仮定（ただし上限あり）
    local max_w=$(( window_width_px < MAX_IMG_WIDTH ? window_width_px : MAX_IMG_WIDTH ))
    ((max_w<1)) && max_w=1

    # アスペクト比
    local aspect
    aspect=$(echo "scale=6; $iw / $ih" | bc)

    local display_width=$iw
    local display_height=$ih

    # デバッグ情報
    if [ "$DEBUG" -eq 1 ]; then
      echo "元サイズ: ${iw}x${ih}px, アスペクト比: $aspect"
      echo "利用可能領域: ${max_w}x${max_h}px"
    fi

    # 画像がすでに表示領域に収まる場合は何もしない
    if [ "$iw" -le "$max_w" ] && [ "$ih" -le "$max_h" ]; then
      # そのままのサイズで表示（サイズ係数を適用）
      [ "$DEBUG" -eq 1 ] && echo "サイズ調整不要（倍率のみ適用）"
      display_width=$(echo "$iw * $SIZE_FACTOR" | bc | xargs printf "%.0f")
      display_height=$(echo "$ih * $SIZE_FACTOR" | bc | xargs printf "%.0f")
    else
      # 縦横両方の制約を考慮して、どちらの制約がより厳しいかを確認
      local scale_w=1
      local scale_h=1
      
      if [ "$iw" -gt "$max_w" ]; then
        scale_w=$(echo "scale=6; $max_w / $iw" | bc)
      fi
      
      if [ "$ih" -gt "$max_h" ]; then
        scale_h=$(echo "scale=6; $max_h / $ih" | bc)
      fi
      
      # より厳しい方（値が小さい方）の縮小率を採用
      local scale
      if (( $(echo "$scale_w < $scale_h" | bc -l) )); then
        scale=$scale_w
        [ "$DEBUG" -eq 1 ] && echo "幅の制約が厳しいため $scale 倍に縮小"
      else
        scale=$scale_h
        [ "$DEBUG" -eq 1 ] && echo "高さの制約が厳しいため $scale 倍に縮小"
      fi
      
      # 両方の次元を同じ率で縮小してアスペクト比を維持（サイズ係数も適用）
      local final_scale=$(echo "$scale * $SIZE_FACTOR" | bc)
      display_width=$(echo "$iw * $final_scale" | bc | xargs printf "%.0f")
      display_height=$(echo "$ih * $final_scale" | bc | xargs printf "%.0f")
      
      [ "$DEBUG" -eq 1 ] && echo "調整後サイズ: ${display_width}x${display_height}px（倍率 $SIZE_FACTOR 適用）"
    fi

    # --- 画像を表示 (カーソルを進めないオプション -p) ---
    # 一時的にシンプルな名前のファイルにコピーして表示
    local display_temp="${temp_dir}/display_temp.jpg"
    cp "$display_jpeg" "$display_temp" 2>/dev/null
    
    # imgcatコマンドオプション
    # -p: 画像表示後にカーソルを進めない
    # -W: 幅を指定 (ピクセル単位)
    # -H: 高さを指定 (ピクセル単位)
    # -r: アスペクト比を維持
    
    # 画像を中央に表示するための計算と位置調整
    local term_width=$(tput cols)
    local char_width=8  # 平均的な文字幅（ピクセル）
    local img_char_width=$(( display_width / char_width ))
    local left_padding=$(( (term_width - img_char_width) / 2 ))
    # 余白がマイナスになる場合は0にする
    if [ $left_padding -lt 0 ]; then
      left_padding=0
    fi
    # 現在の行の左端から余白分だけ移動
    tput hpa $left_padding
    
    [ "$DEBUG" -eq 1 ] && echo "imgcatコマンド実行: imgcat -p -W ${display_width}px -H ${display_height}px -r ${display_temp}"
    [ "$DEBUG" -eq 1 ] && echo "中央表示: 文字幅換算=${img_char_width}, 左余白=${left_padding}"
    
    { 
      # サイズが十分大きい場合はオプションを調整
      if [ "$display_width" -gt 300 ] && [ "$display_height" -gt 300 ]; then
        imgcat -p -W "${display_width}px" -H "${display_height}px" -r "$display_temp" 2>/dev/null
      else
        # 小さすぎる場合は最小サイズを保証
        imgcat -p -W "400px" -H "300px" -r "$display_temp" 2>/dev/null
      fi
    } | grep -v "$(basename "$display_temp")" 2>/dev/null
  fi

  # --- (C) フッターをターミナルの最下部に配置 ---
  local term_lines=$(tput lines)
  local term_cols=$(tput cols)

  local footer_lines=3
  local goto_line=$((term_lines - footer_lines))
  ((goto_line<0)) && goto_line=0
  tput cup "$goto_line" 0

  # プログレスバー (1行目)
  local progress_width=$((term_cols - 20))
  ((progress_width<1)) && progress_width=1
  local progress_pos=$(( progress_width * current_index / (total_files - 1) ))
  local progress_bar=""
  for ((i=0; i<progress_width; i++)); do
    if [ $i -eq $progress_pos ]; then
      progress_bar+="●"
    else
      progress_bar+="─"
    fi
  done
  echo -en "${YELLOW}${MSG_PROGRESS}:${RESET} [${progress_bar}] $((current_index + 1)) / $total_files"
  
  # 改行を明示的に制御
  tput cup "$((goto_line+1))" 0

  # 操作ガイド (2行目)
  echo -en "${GREEN}Enter${RESET}: ${MSG_LIKE}  ${GREEN}←/→${RESET}: ${MSG_EXPOSURE_ADJ}  ${GREEN}↑/↓${RESET}: ${MSG_PREV_NEXT}  ${YELLOW}q${RESET}: ${MSG_EXIT}"

  # 3行目は空行でもOK
  tput cup "$((goto_line+2))" 0
  echo -n ""

  manage_preload_queue "$current_index" "$total_files"
}


##################################################
# 4) メイン処理
##################################################

# iTerm2+imgcatチェック (省略可)
if [ "${TERM_PROGRAM:-}" != "iTerm.app" ] || ! command -v imgcat >/dev/null 2>&1; then
  echo -e "${MSG_ITERM_ERROR}"
  exit 1
fi

# ターミナルサイズチェック
if [ "$(tput lines)" -lt 24 ] || [ "$(tput cols)" -lt 80 ]; then
  echo -e "${MSG_TERMINAL_SIZE_ERROR}"
  exit 1
fi

# 前準備
prepare() {
  # script_dirを設定
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  temp_dir="${script_dir}/temp_images"
  mkdir -p "$temp_dir"
  mkdir -p "${script_dir}/lang"
  
  # 言語設定を適用
  apply_language_settings
}

main() {
  # トラップ設定
  trap cleanup EXIT
  trap cleanup SIGINT
  trap cleanup SIGTERM
  
  # 初期設定
  prepare
  
  # ImageMagickのチェック
  check_imagemagick
  
  # DNG処理ツールのチェック
  if [ $USE_DNG_FOR_EXPOSURE -eq 1 ]; then
    check_dng_processor
  fi
  
  clear
  echo -e "${MSG_SEARCHING_SDCARD}"
  if [ ! -d "/Volumes" ]; then
    echo -e "${MSG_NO_VOLUMES_DIR}"
    exit 1
  fi
  
  volumes=(/Volumes/*)
  [ ${#volumes[@]} -eq 0 ] && { echo -e "${MSG_NO_VOLUMES}"; exit 1; }
  
  volume_options=()
  for vol in "${volumes[@]}"; do
    [ -d "$vol" ] && volume_options+=("$vol")
  done
  
  [ ${#volume_options[@]} -eq 0 ] && { echo -e "${MSG_NO_SDCARD}"; exit 1; }
  
  echo -e "${MSG_SELECT_SDCARD}"
  selected=0
  
  display_volume_options() {
    for i in "${!volume_options[@]}"; do
      if [ $i -eq $selected ]; then
        echo -e "${HIGHLIGHT}> ${volume_options[$i]}${RESET}"
      else
        echo "  ${volume_options[$i]}"
      fi
    done
  }
  
  display_volume_options
  while true; do
    read -rsn1 key
    if [[ $key == "" ]]; then
      sdcard="${volume_options[$selected]}"
      break
    elif [[ $key == $'\e' ]]; then
      read -rsn2 k2
      case "$k2" in
        "[A")
          [ $selected -gt 0 ] && ((selected--))
          clear; echo -e "${MSG_SELECT_SDCARD}"
          display_volume_options
          ;;
        "[B")
          [ $selected -lt $((${#volume_options[@]} - 1)) ] && ((selected++))
          clear; echo -e "${MSG_SELECT_SDCARD}"
          display_volume_options
          ;;
      esac
    fi
  done
  
  clear
  echo -e "${MSG_SELECTED_SDCARD}: $sdcard"
  echo ""
  
  # likesフォルダを自動的に作成
  if [ ! -d "$sdcard/likes" ]; then
    mkdir -p "$sdcard/likes"
  fi
  
  # likesフォルダ内のDNGファイルを事前スキャン
  scan_likes_folder "$sdcard"
  
  echo -e "${MSG_SEARCHING_JPEGS}"
  
  temp_files=$(mktemp)
  echo -n "${MSG_SEARCHING}"
  find "$sdcard" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -not -name "._*" -not -path "*/\.*" > "$temp_files" 2>/dev/null &
  pid=$!
  while kill -0 $pid 2>/dev/null; do
    echo -n "."
    sleep 0.3
  done
  echo ""
  
  file_count=$(wc -l < "$temp_files")
  echo "${MSG_SEARCH_FILES}: $file_count"
  
  all_jpeg_files=()
  while IFS= read -r f; do
    all_jpeg_files+=("$f")
  done < "$temp_files"
  rm "$temp_files"
  
  [ ${#all_jpeg_files[@]} -eq 0 ] && { echo -e "${MSG_NO_JPEG_FILES}"; exit 1; }
  
  printf "${MSG_TOTAL_JPEGS}\n" "${#all_jpeg_files[@]}"
  
  # 日付で絞り込み
  echo ""
  echo -n "${MSG_COLLECTING_DATES}"
  dates_list=()
  file_paths=()
  file_dates=()
  i=0
  total=${#all_jpeg_files[@]}
  for jpeg in "${all_jpeg_files[@]}"; do
    ((i%100==0)) && echo -n "."
    file_date=$(stat -f "%Sm" -t "%Y-%m-%d" "$jpeg")
    dates_list+=("$file_date")
    file_paths[$i]="$jpeg"
    file_dates[$i]="$file_date"
    ((i++))
  done
  echo ""
  
  temp_dates=$(mktemp)
  printf "%s\n" "${dates_list[@]}" | sort -r -u > "$temp_dates"
  date_options=()
  while IFS= read -r line; do
    date_options+=("$line")
  done < "$temp_dates"
  rm "$temp_dates"
  
  # "すべて" を追加
  date_options+=("${MSG_ALL_DATES}")
  
  clear
  echo -e "${MSG_DATES_FOUND}"
  selected=0
  
  display_date_options() {
    for i in "${!date_options[@]}"; do
      if [ $i -eq $selected ]; then
        echo -e "${HIGHLIGHT}> ${date_options[$i]}${RESET}"
      else
        echo "  ${date_options[$i]}"
      fi
    done
  }
  
  display_date_options
  while true; do
    read -rsn1 key
    if [[ $key == "" ]]; then
      chosen_date="${date_options[$selected]}"
      break
    elif [[ $key == $'\e' ]]; then
      read -rsn2 k2
      case "$k2" in
        "[A")
          [ $selected -gt 0 ] && ((selected--))
          clear; echo -e "${MSG_DATES_FOUND}"
          display_date_options
          ;;
        "[B")
          [ $selected -lt $((${#date_options[@]} - 1)) ] && ((selected++))
          clear; echo -e "${MSG_DATES_FOUND}"
          display_date_options
          ;;
      esac
    fi
  done
  
  clear
  echo -e "${MSG_SELECTED_DATE}: $chosen_date"
  echo ""
  
  # 絞り込み
  selected_files=()
  if [ "$chosen_date" = "${MSG_ALL_DATES}" ]; then
    selected_files=("${all_jpeg_files[@]}")
  else
    for idx in "${!file_paths[@]}"; do
      if [ "${file_dates[$idx]}" = "$chosen_date" ]; then
        selected_files+=("${file_paths[$idx]}")
      fi
    done
  fi
  
  # 選択された日付のDNGファイルがlikesフォルダにあるかチェック
  local has_liked_files=0
  local last_liked_index=-1
  
  # まず全ファイルをソート
  echo -e "${MSG_SORTING_FILES}"
  sorted_files=()
  tmp_s=$(mktemp)
  for f in "${selected_files[@]}"; do
    echo "$(basename "$f")|$f" >> "$tmp_s"
  done
  sort "$tmp_s" | cut -d'|' -f2 > "${tmp_s}.sorted"
  while IFS= read -r line; do
    sorted_files+=("$line")
  done < "${tmp_s}.sorted"
  rm -f "$tmp_s" "${tmp_s}.sorted"

  # likesフォルダ内のDNGと比較
  for ((i=0; i<${#sorted_files[@]}; i++)); do
    local jpeg="${sorted_files[$i]}"
    local base_name=$(basename "${jpeg%.*}")
    if is_dng_in_likes "$base_name"; then
      has_liked_files=1
      last_liked_index=$i
    fi
  done

  total_files=${#sorted_files[@]}
  echo -e "${MSG_FILTERED_FILES}: $total_files"
  echo ""

  # likesフォルダに該当する日付のDNGがある場合
  if [ $has_liked_files -eq 1 ]; then
    clear
    echo -e "${MSG_LIKES_FOUND}"
    echo -e "${MSG_CONTINUE_FROM_LAST}"
    
    # 選択肢を表示
    local options=("${MSG_YES}" "${MSG_NO}")
    selected=0
    
    display_continue_options() {
      for i in "${!options[@]}"; do
        if [ $i -eq $selected ]; then
          echo -e "${HIGHLIGHT}> ${options[$i]}${RESET}"
        else
          echo "  ${options[$i]}"
        fi
      done
    }
    
    display_continue_options
    while true; do
      read -rsn1 key
      if [[ $key == "" ]]; then
        chosen_option="${options[$selected]}"
        break
      elif [[ $key == $'\e' ]]; then
        read -rsn2 k2
        case "$k2" in
          "[A")
            [ $selected -gt 0 ] && ((selected--))
            clear
            echo -e "${MSG_LIKES_FOUND}"
            echo -e "${MSG_CONTINUE_FROM_LAST}"
            display_continue_options
            ;;
          "[B")
            [ $selected -lt $((${#options[@]} - 1)) ] && ((selected++))
            clear
            echo -e "${MSG_LIKES_FOUND}"
            echo -e "${MSG_CONTINUE_FROM_LAST}"
            display_continue_options
            ;;
        esac
      fi
    done
    
    # 選択に基づいて開始インデックスを設定
    if [ "$chosen_option" = "${MSG_YES}" ] && [ $last_liked_index -gt -1 ]; then
      current_index=$((last_liked_index + 1))
      [ $current_index -ge $total_files ] && current_index=$((total_files - 1))
    else
      current_index=0
    fi
  else
    current_index=0
    read -n1 -rsp "${MSG_PRESS_ANY_KEY}"
  fi

  tput civis  # カーソル非表示
  
  LIKED_FILES=()
  TAGGED_DNGS=()
  
  # 画像インデックスの準備
  if [ $total_files -gt 0 ]; then
    preload_image "${sorted_files[0]}" "${temp_dir}/$(basename "${sorted_files[0]}")"
    manage_preload_queue 0 "$total_files"
  fi
  # 画面位置を確実に初期化
  tput cup 0 0
  display_image

  while true; do
    read -rsn1 key
    if [[ $key == "q" ]]; then
      break
    elif [[ $key == "" ]]; then
      # Enter = Like
      jpeg="${sorted_files[$current_index]}"
      LIKED_FILES+=("$jpeg")

      # DNGタグ付け
      base="${jpeg%.*}"
      dng=$(find_corresponding_dng "$jpeg")
      
      if [ -n "$dng" ]; then
        if command -v tag >/dev/null 2>&1; then
          tag --add Yellow "$dng"
        else
          xattr -w com.apple.metadata:_kMDItemUserTags '(Yellow)' "$dng"
        fi
        TAGGED_DNGS+=("$dng")
        printf "${PINK}${MSG_DNG_TAGGED}${RESET}\n" "$(basename "$dng")"
        # メッセージ表示後に行をクリア
        tput el
      else
        echo -e "${PINK}${MSG_NO_CORRESPONDING_DNG}${RESET}"
        # メッセージ表示後に行をクリア
        tput el
      fi
      sleep 0.1
      # LIKEした後も同じ画像にとどまるように自動進行処理を削除
      
      # 画面を再表示して、LIKE状態を反映する
      tput cup 0 0
      display_image

    elif [[ $key == $'\e' ]]; then
      read -rsn2 k2
      case "$k2" in
        "[A")
          # ↑
          [ $current_index -gt 0 ] && ((current_index--))
          # 露出値をリセット
          current_exposure=0
          # 画面位置を最上部に初期化
          tput cup 0 0
          display_image
          ;;
        "[B")
          # ↓
          [ $current_index -lt $((total_files - 1)) ] && ((current_index++))
          # 露出値をリセット
          current_exposure=0
          # 画面位置を最上部に初期化
          tput cup 0 0
          display_image
          ;;
        "[C")
          # → キー: 露出を上げる
          # 最大値を超えないよう調整
          if [ $current_exposure -lt $MAX_EXPOSURE ]; then
            current_exposure=$((current_exposure + EXPOSURE_STEP))
            # 画面位置を最上部に初期化
            tput cup 0 0
            display_image
          fi
          ;;
        "[D")
          # ← キー: 露出を下げる
          # 最小値を下回らないよう調整
          if [ $current_exposure -gt $MIN_EXPOSURE ]; then
            current_exposure=$((current_exposure - EXPOSURE_STEP))
            # 画面位置を最上部に初期化
            tput cup 0 0
            display_image
          fi
          ;;
      esac
    fi
  done

  clear
  echo -e "${MSG_SELECTION_RESULTS}"
  printf "${MSG_LIKED_JPEGS}\n" "${#LIKED_FILES[@]}"
  printf "${MSG_TAGGED_DNGS}\n" "${#TAGGED_DNGS[@]}"

  if [ ${#TAGGED_DNGS[@]} -gt 0 ]; then
    clear
    printf "${MSG_TAGGED_DNG_FILES}\n" "${#TAGGED_DNGS[@]}"
    echo ""
    echo -e "${MSG_SELECT_ACTION}"
    
    # 選択肢を配列に格納
    move_options=("${MSG_MOVE_DNGS}" "${MSG_DONT_MOVE}")
    selected=0
    
    display_move_options() {
      for i in "${!move_options[@]}"; do
        if [ $i -eq $selected ]; then
          echo -e "${HIGHLIGHT}> ${move_options[$i]}${RESET}"
        else
          echo "  ${move_options[$i]}"
        fi
      done
    }
    
    display_move_options
    while true; do
      read -rsn1 key
      if [[ $key == "" ]]; then  # Enter
        chosen_option="${move_options[$selected]}"
        break
      elif [[ $key == $'\e' ]]; then
        read -rsn2 k2
        case "$k2" in
          "[A")  # 上キー
            [ $selected -gt 0 ] && ((selected--))
            clear
            printf "${MSG_TAGGED_DNG_FILES}\n" "${#TAGGED_DNGS[@]}"
            echo ""
            echo -e "${MSG_SELECT_ACTION}"
            display_move_options
            ;;
          "[B")  # 下キー
            [ $selected -lt $((${#move_options[@]} - 1)) ] && ((selected++))
            clear
            printf "${MSG_TAGGED_DNG_FILES}\n" "${#TAGGED_DNGS[@]}"
            echo ""
            echo -e "${MSG_SELECT_ACTION}"
            display_move_options
            ;;
        esac
      fi
    done
    
    # 選択に基づいて処理
    if [ "$chosen_option" = "${MSG_MOVE_DNGS}" ]; then
      clear
      echo -e "${MSG_SELECT_DEST}"
      
      # 移動先オプションを配列に格納 - likesをデフォルトオプションとして最初に追加
      dest_options=("$sdcard/likes" "$sdcard/${MSG_CHECKED_FOLDER}" "$sdcard/${MSG_SELECTED_PHOTOS}" "${MSG_ENTER_NEW_FOLDER}")
      selected=0
      
      display_dest_options() {
        for i in "${!dest_options[@]}"; do
          if [ $i -eq $selected ]; then
            echo -e "${HIGHLIGHT}> ${dest_options[$i]}${RESET}"
          else
            echo "  ${dest_options[$i]}"
          fi
        done
      }
      
      display_dest_options
      while true; do
        read -rsn1 key
        if [[ $key == "" ]]; then  # Enter
          chosen_dest="${dest_options[$selected]}"
          break
        elif [[ $key == $'\e' ]]; then
          read -rsn2 k2
          case "$k2" in
            "[A")  # 上キー
              [ $selected -gt 0 ] && ((selected--))
              clear
              echo -e "${MSG_SELECT_DEST}"
              display_dest_options
              ;;
            "[B")  # 下キー
              [ $selected -lt $((${#dest_options[@]} - 1)) ] && ((selected++))
              clear
              echo -e "${MSG_SELECT_DEST}"
              display_dest_options
              ;;
          esac
        fi
      done
      
      
      # 移動先フォルダの処理
      dest_folder=""
      if [ "$chosen_dest" = "${MSG_ENTER_NEW_FOLDER}" ]; then
        clear
        echo -e "${MSG_INPUT_FOLDER_NAME}"
        tput cnorm  # カーソル表示
        read -r folder_name
        tput civis  # カーソル非表示
        dest_folder="$sdcard/$folder_name"
      else
        dest_folder="$chosen_dest"
      fi
      
      # ファイル移動処理
      mkdir -p "$dest_folder"
      local moved=0
      clear
      echo -e "${MSG_MOVING_FILES}"
      for d in "${TAGGED_DNGS[@]}"; do
        if [ -f "$d" ]; then
          mv "$d" "$dest_folder/" && ((moved++))
          echo -n "."
        fi
      done
      echo ""
      printf "${MSG_MOVED_FILES}\n" "$moved" "$(basename "$dest_folder")"
      sleep 1
    fi
  fi

  exit 0
}

# JPEGに対応するDNGファイルを探す関数
find_corresponding_dng() {
  local jpeg_path="$1"
  local base="${jpeg_path%.*}"
  local dng_path=""
  
  # 直接対応するDNGを確認（大文字小文字両方）
  if [ -f "${base}.DNG" ]; then
    dng_path="${base}.DNG"
    [ "$DEBUG" -eq 1 ] && echo "DEBUG: ${base}.DNG が見つかりました"
  elif [ -f "${base}.dng" ]; then
    dng_path="${base}.dng"
    [ "$DEBUG" -eq 1 ] && echo "DEBUG: ${base}.dng が見つかりました" 
  else
    [ "$DEBUG" -eq 1 ] && echo "DEBUG: DNG検索: ${base}.DNG または ${base}.dng が見つかりません"
    # 大文字小文字を区別せずに検索
    possible_dng=$(find "$(dirname "$base")" -maxdepth 1 -type f -iname "$(basename "$base").dng" 2>/dev/null | head -1)
    if [ -n "$possible_dng" ]; then
      dng_path="$possible_dng"
      [ "$DEBUG" -eq 1 ] && echo "DEBUG: 代替検索で見つかったDNG: $dng_path"
    fi
  fi
  
  echo "$dng_path"
}

# DNG処理して露出調整を行う関数
process_dng_with_exposure() {
  local dng_file="$1"
  local output_jpeg="$2"
  local exposure="$3"
  local bg="$4"
  
  if [ ! -f "$dng_file" ]; then
    return 1
  fi
  
  # 露出値が0の場合は元の画像をそのまま使用（実際には処理しない）
  if [ "$exposure" -eq 0 ]; then
    return 2
  fi
  
  # 既に調整済みの画像があればスキップ
  if [ -f "$output_jpeg" ]; then
    return 0
  fi
  
  # DNG処理ツールが設定されていなければ確認
  if [ -z "$DNG_PROCESSOR" ]; then
    check_dng_processor
  fi
  
  # DNG処理ツールが見つからない場合は対応するJPEGの処理にフォールバック
  if [ -z "$DNG_PROCESSOR" ] || [ "$DNG_PROCESSOR" = "none" ]; then
    [ "$DEBUG" -eq 1 ] && echo "DNG処理ツールが利用できません。対応するJPEGを探します..."
    
    # 対応するJPEGファイルを探す
    local jpeg_path="${dng_file%.dng}.jpg"
    if [ ! -f "$jpeg_path" ]; then
      jpeg_path="${dng_file%.DNG}.jpg"
    fi
    if [ ! -f "$jpeg_path" ]; then
      jpeg_path="${dng_file%.dng}.jpeg"
    fi
    if [ ! -f "$jpeg_path" ]; then
      jpeg_path="${dng_file%.DNG}.jpeg"
    fi
    
    # JPEGが見つかったら通常の露出調整
    if [ -f "$jpeg_path" ]; then
      [ "$DEBUG" -eq 1 ] && echo "対応するJPEGを発見: $jpeg_path"
      local resized="${temp_dir}/$(basename "$jpeg_path")"
      
      # リサイズ済みがなければ作成
      if [ ! -f "$resized" ]; then
        preload_image "$jpeg_path" "$resized"
      fi
      
      # JPEGに通常の露出調整を適用
      if [ "$bg" = "bg" ]; then
        adjust_exposure "$resized" "$output_jpeg" "$exposure" "bg"
      else
        adjust_exposure "$resized" "$output_jpeg" "$exposure"
      fi
      return $?
    else
      [ "$DEBUG" -eq 1 ] && echo "対応するJPEGも見つかりません。処理をスキップします。"
      return 3
    fi
  fi
  
  # 実際に使用するEV値を計算（露出値を-3.0〜+3.0の範囲に変換）
  local ev_value=$(echo "scale=1; $exposure / 8.333" | bc)
  
  # バックグラウンド処理
  if [ "$bg" = "bg" ]; then
    {
      local tmp_out="${output_jpeg}.tmp"
      
      case "$DNG_PROCESSOR" in
        "darktable")
          # darktable-cliを使用して露出調整
          # --hq: 高品質モード
          # --core: GUI無し
          # -d 0: デバッグ0
          # Lua scriptを使用する代わりに、XMLファイルを作成して露出を調整
          local xmp_file=$(mktemp "${temp_dir}/dt_XXXXXX.xmp")
          cat > "$xmp_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XMP Core 4.4.0-Exiv2">
 <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description rdf:about=""
    xmlns:darktable="http://darktable.sf.net/">
   <darktable:history_modversion>2</darktable:history_modversion>
   <darktable:history_enabled>1</darktable:history_enabled>
   <darktable:exposure>$ev_value</darktable:exposure>
   <darktable:history_end>1</darktable:history_end>
  </rdf:Description>
 </rdf:RDF>
</x:xmpmeta>
EOF
          darktable-cli "$dng_file" "$xmp_file" "$tmp_out" --hq --core -d 0 &>/dev/null
          rm -f "$xmp_file"
          ;;
          
        "rawtherapee")
          # rawtherapee-cliを使用して露出調整
          local pp3_file=$(mktemp "${temp_dir}/rt_XXXXXX.pp3")
          cat > "$pp3_file" << EOF
[Exposure]
Compensation=$ev_value
EOF
          rawtherapee-cli -o "$tmp_out" -p "$pp3_file" -c "$dng_file" -Y &>/dev/null
          rm -f "$pp3_file"
          ;;
          
        "dcraw")
          # dcrawを使用して露出調整
          local brightness=$(echo "1.0 + $ev_value / 2.0" | bc)
          
          # タイムアウト処理を追加（30秒）
          [ "$DEBUG" -eq 1 ] && echo "dcrawで処理開始: $dng_file (明るさ: $brightness)"
          
          # 一時ファイルを作成して段階的に処理
          local raw_tmp="${temp_dir}/dcraw_tmp_$$.ppm"
          
          # まずdcrawで抽出
          if timeout 30 dcraw -c -b "$brightness" -q 1 -w -h "$dng_file" > "$raw_tmp" 2>"${temp_dir}/dcraw_error.log"; then
            # 次にconvertで変換
            if timeout 30 convert "$raw_tmp" "$tmp_out" 2>>"${temp_dir}/dcraw_error.log"; then
              [ "$DEBUG" -eq 1 ] && echo "dcraw処理成功: $(basename "$tmp_out")"
              rm -f "$raw_tmp"
            else
              [ "$DEBUG" -eq 1 ] && echo "dcrawのconvert処理でエラー: $(cat "${temp_dir}/dcraw_error.log")"
              rm -f "$tmp_out" "$raw_tmp" 2>/dev/null
              return 4
            fi
          else
            [ "$DEBUG" -eq 1 ] && echo "dcraw処理でエラー: $(cat "${temp_dir}/dcraw_error.log")"
            rm -f "$raw_tmp" 2>/dev/null
            
            # 簡易モードでの再試行
            [ "$DEBUG" -eq 1 ] && echo "簡易モードで再試行します"
            if timeout 20 dcraw -e "$dng_file" && timeout 20 convert "${dng_file%.dng}.thumb.jpg" "$tmp_out"; then
              [ "$DEBUG" -eq 1 ] && echo "サムネイル抽出に成功しました"
            else
              rm -f "$tmp_out" 2>/dev/null
              return 4
            fi
          fi
          ;;
          
        *)
          # DNG処理ツールが見つからない場合
          [ "$DEBUG" -eq 1 ] && echo "DNG処理ツールが見つかりません、処理をスキップします"
          rm -f "$tmp_out" 2>/dev/null
          return 3
          ;;
      esac
      
      # 正常に処理された場合は、一時ファイルを出力先に移動
      if [ -f "$tmp_out" ] && [ -s "$tmp_out" ]; then
        mv "$tmp_out" "$output_jpeg" 2>/dev/null
        [ "$DEBUG" -eq 1 ] && echo "DNG処理成功（${ev_value}EV）: $(basename "$output_jpeg")"
        return 0
      else
        [ "$DEBUG" -eq 1 ] && echo "DNG処理失敗: $dng_file"
        rm -f "$tmp_out" 2>/dev/null
        return 4
      fi
    } &
    bg_pids+=($!)
    return 0
  fi
  
  # フォアグラウンド処理
  local tmp_out="${output_jpeg}.tmp"
  
  case "$DNG_PROCESSOR" in
    "darktable")
      # darktable-cliを使用して露出調整
      local xmp_file=$(mktemp "${temp_dir}/dt_XXXXXX.xmp")
      cat > "$xmp_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XMP Core 4.4.0-Exiv2">
 <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <rdf:Description rdf:about=""
    xmlns:darktable="http://darktable.sf.net/">
   <darktable:history_modversion>2</darktable:history_modversion>
   <darktable:history_enabled>1</darktable:history_enabled>
   <darktable:exposure>$ev_value</darktable:exposure>
   <darktable:history_end>1</darktable:history_end>
  </rdf:Description>
 </rdf:RDF>
</x:xmpmeta>
EOF
      darktable-cli "$dng_file" "$xmp_file" "$tmp_out" --hq --core -d 0 &>/dev/null
      rm -f "$xmp_file"
      ;;
      
    "rawtherapee")
      # rawtherapee-cliを使用して露出調整
      local pp3_file=$(mktemp "${temp_dir}/rt_XXXXXX.pp3")
      cat > "$pp3_file" << EOF
[Exposure]
Compensation=$ev_value
EOF
      rawtherapee-cli -o "$tmp_out" -p "$pp3_file" -c "$dng_file" -Y &>/dev/null
      rm -f "$pp3_file"
      ;;
      
    "dcraw")
      # dcrawを使用して露出調整
      local brightness=$(echo "1.0 + $ev_value / 2.0" | bc)
      
      # タイムアウト処理を追加（30秒）
      [ "$DEBUG" -eq 1 ] && echo "dcrawで処理開始: $dng_file (明るさ: $brightness)"
      
      # 一時ファイルを作成して段階的に処理
      local raw_tmp="${temp_dir}/dcraw_tmp_$$.ppm"
      
      # まずdcrawで抽出
      if timeout 30 dcraw -c -b "$brightness" -q 1 -w -h "$dng_file" > "$raw_tmp" 2>"${temp_dir}/dcraw_error.log"; then
        # 次にconvertで変換
        if timeout 30 convert "$raw_tmp" "$tmp_out" 2>>"${temp_dir}/dcraw_error.log"; then
          [ "$DEBUG" -eq 1 ] && echo "dcraw処理成功: $(basename "$tmp_out")"
          rm -f "$raw_tmp"
        else
          [ "$DEBUG" -eq 1 ] && echo "dcrawのconvert処理でエラー: $(cat "${temp_dir}/dcraw_error.log")"
          rm -f "$tmp_out" "$raw_tmp" 2>/dev/null
          return 4
        fi
      else
        [ "$DEBUG" -eq 1 ] && echo "dcraw処理でエラー: $(cat "${temp_dir}/dcraw_error.log")"
        rm -f "$raw_tmp" 2>/dev/null
        
        # 簡易モードでの再試行
        [ "$DEBUG" -eq 1 ] && echo "簡易モードで再試行します"
        if timeout 20 dcraw -e "$dng_file" && timeout 20 convert "${dng_file%.dng}.thumb.jpg" "$tmp_out"; then
          [ "$DEBUG" -eq 1 ] && echo "サムネイル抽出に成功しました"
        else
          rm -f "$tmp_out" 2>/dev/null
          return 4
        fi
      fi
      ;;
      
    *)
      # DNG処理ツールが見つからない場合
      [ "$DEBUG" -eq 1 ] && echo "DNG処理ツールが見つかりません、処理をスキップします"
      rm -f "$tmp_out" 2>/dev/null
      return 3
      ;;
  esac
  
  # 正常に処理された場合は、一時ファイルを出力先に移動
  if [ -f "$tmp_out" ] && [ -s "$tmp_out" ]; then
    mv "$tmp_out" "$output_jpeg" 2>/dev/null
    [ "$DEBUG" -eq 1 ] && echo "DNG処理成功（${ev_value}EV）: $(basename "$output_jpeg")"
    return 0
  else
    [ "$DEBUG" -eq 1 ] && echo "DNG処理失敗: $dng_file"
    rm -f "$tmp_out" 2>/dev/null
    return 4
  fi
}

# メイン処理の実行

# コマンドライン引数を解析
parse_arguments "$@"

# メイン処理を実行
main
