#!/usr/bin/env bash

##################################################
# 1) 前準備・共通関数
##################################################

# デバッグモード（1=有効、0=無効）
DEBUG=0

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

# ImageMagick関連
USE_IMAGEMAGICK=1     # ImageMagickを使用するか（1=有効、0=無効）
IMAGEMAGICK_CHECKED=0 # ImageMagickのチェック済みフラグ

# 露出調整済み画像保存用ディレクトリ
exposure_dir=""

# P3色域対応設定
USE_P3_COLORSPACE=1   # P3色域対応（1=有効、0=無効）
P3_PROFILE="/System/Library/ColorSync/Profiles/Display P3.icc"  # P3プロファイルのパス

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
temp_dir="${script_dir}/temp_images"
mkdir -p "$temp_dir"

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
    echo "ImageMagick を検出しました。露出調整に使用します。"
    USE_IMAGEMAGICK=1
    return 0
  else
    echo "ImageMagick が見つかりません。sips を使用します。"
    echo "より良い露出調整のために ImageMagick のインストールをお勧めします。"
    echo "インストール方法: brew install imagemagick"
    USE_IMAGEMAGICK=0
    return 1
  fi
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
  
  # 露出調整済み画像がなければ作成
  if [ ! -f "$exposed_jpeg" ]; then
    adjust_exposure "$resized_jpeg" "$exposed_jpeg" "$current_exposure"
  fi
  
  # 次の露出値も事前に計算してバックグラウンドで準備
  local next_exposure_plus=$((current_exposure + EXPOSURE_STEP))
  local next_exposure_minus=$((current_exposure - EXPOSURE_STEP))
  
  if [ $next_exposure_plus -le $MAX_EXPOSURE ]; then
    local next_plus="${exposure_dir}/${next_exposure_plus}_${base_name}"
    [ ! -f "$next_plus" ] && adjust_exposure "$resized_jpeg" "$next_plus" "$next_exposure_plus" "bg"
  fi
  
  if [ $next_exposure_minus -ge $MIN_EXPOSURE ]; then
    local next_minus="${exposure_dir}/${next_exposure_minus}_${base_name}"
    [ ! -f "$next_minus" ] && adjust_exposure "$resized_jpeg" "$next_minus" "$next_exposure_minus" "bg"
  fi
  
  # 露出調整済み画像のパスを返す
  echo "$exposed_jpeg"
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

  # LIKE済みの場合は💕マークを表示、そうでない場合は通常表示
  if [[ $is_liked -eq 1 ]]; then
    echo -e "${YELLOW}📷 ファイル: ${PINK}💕 ${base_name}${RESET}"       # 1行目
  else
    echo -e "${YELLOW}📷 ファイル: ${base_name}${RESET}"       # 1行目
  fi
  echo "インデックス: $((current_index + 1)) / $total_files"  # 2行目
  
  # P3色域対応情報を表示
  if [ "$USE_P3_COLORSPACE" -eq 1 ] && [ -f "$P3_PROFILE" ]; then
    echo -e "${GREEN}P3色域対応: 有効${RESET}"  # 3行目
  else
    echo -e "P3色域対応: 無効"  # 3行目
  fi
  
  echo "日付: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$jpeg")" # 4行目
  
  # 露出値を表示 (5行目)
  if [ $current_exposure -gt 0 ]; then
    echo -e "露出調整: ${GREEN}+${current_exposure}${RESET}"
  elif [ $current_exposure -lt 0 ]; then
    echo -e "露出調整: ${PINK}${current_exposure}${RESET}"
  else
    echo -e "露出調整: 0"
  fi
  
  echo ""                                                   # 6行目
  local header_lines=6

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
    
    [ "$DEBUG" -eq 1 ] && echo "imgcatコマンド実行: imgcat -p -W ${display_width}px -H ${display_height}px -r ${display_temp}"
    
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
  echo -en "${YELLOW}進捗:${RESET} [${progress_bar}] $((current_index + 1)) / $total_files"
  
  # 改行を明示的に制御
  tput cup "$((goto_line+1))" 0

  # 操作ガイド (2行目)
  echo -en "${GREEN}Enter${RESET}: Like  ${GREEN}←/→${RESET}: 露出調整  ${GREEN}↑/↓${RESET}: 前/次  ${YELLOW}q${RESET}: 終了"

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
  echo "エラー: iTerm2 か imgcat コマンドが使えません。"
  exit 1
fi

# ターミナルサイズチェック
if [ "$(tput lines)" -lt 24 ] || [ "$(tput cols)" -lt 80 ]; then
  echo "エラー: ターミナルサイズが小さすぎます(24x80以上推奨)"
  exit 1
fi

clear
echo "利用可能なSDカードを探しています..."
if [ ! -d "/Volumes" ]; then
  echo "/Volumes ディレクトリがありません"
  exit 1
fi

volumes=(/Volumes/*)
[ ${#volumes[@]} -eq 0 ] && { echo "利用可能なボリュームがありません"; exit 1; }

volume_options=()
for vol in "${volumes[@]}"; do
  [ -d "$vol" ] && volume_options+=("$vol")
done

[ ${#volume_options[@]} -eq 0 ] && { echo "SDカードが見つかりません"; exit 1; }

echo "SDカードを選択 (↑/↓, Enter)"
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
        clear; echo "SDカードを選択 (↑/↓, Enter)"
        display_volume_options
        ;;
      "[B")
        [ $selected -lt $((${#volume_options[@]} - 1)) ] && ((selected++))
        clear; echo "SDカードを選択 (↑/↓, Enter)"
        display_volume_options
        ;;
    esac
  fi
done

clear
echo "選択されたSDカード: $sdcard"
echo ""
echo "JPEGファイルを検索中..."

temp_files=$(mktemp)
echo -n "検索中"
find "$sdcard" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -not -name "._*" -not -path "*/\.*" > "$temp_files" 2>/dev/null &
pid=$!
while kill -0 $pid 2>/dev/null; do
  echo -n "."
  sleep 0.3
done
echo ""

file_count=$(wc -l < "$temp_files")
echo "検索ファイル数: $file_count"

all_jpeg_files=()
while IFS= read -r f; do
  all_jpeg_files+=("$f")
done < "$temp_files"
rm "$temp_files"

[ ${#all_jpeg_files[@]} -eq 0 ] && { echo "JPEGファイルがありません"; exit 1; }

echo "合計 ${#all_jpeg_files[@]} 個のJPEGファイル"

# 日付で絞り込み
echo ""
echo -n "日付を集計中"
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
date_options+=("すべて")

clear
echo "以下の日付が見つかりました (↑/↓, Enter):"
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
        clear; echo "以下の日付が見つかりました (↑/↓, Enter):"
        display_date_options
        ;;
      "[B")
        [ $selected -lt $((${#date_options[@]} - 1)) ] && ((selected++))
        clear; echo "以下の日付が見つかりました (↑/↓, Enter):"
        display_date_options
        ;;
    esac
  fi
done

clear
echo "選択された日付: $chosen_date"
echo ""

# 絞り込み
selected_files=()
if [ "$chosen_date" = "すべて" ]; then
  selected_files=("${all_jpeg_files[@]}")
else
  for idx in "${!file_paths[@]}"; do
    if [ "${file_dates[$idx]}" = "$chosen_date" ]; then
      selected_files+=("${file_paths[$idx]}")
    fi
  done
fi

echo "ファイル名でソート中..."
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

total_files=${#sorted_files[@]}
echo "絞り込まれたファイル数: $total_files"
echo ""
read -n1 -rsp $'続行するにはキーを押してください...\n'

tput civis  # カーソル非表示

current_index=0
LIKED_FILES=()
TAGGED_DNGS=()

# メイン処理
main() {
  # トラップ設定
  trap cleanup EXIT
  trap cleanup SIGINT
  trap cleanup SIGTERM
  
  # 初期設定
  prepare
  
  # ImageMagickのチェック
  check_imagemagick
  
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
      dng=""
      echo "DEBUG: JPEG=$jpeg"
      echo "DEBUG: base=$base"
      
      if [ -f "${base}.DNG" ]; then
        dng="${base}.DNG"
        echo "DEBUG: ${base}.DNG が見つかりました"
      elif [ -f "${base}.dng" ]; then
        dng="${base}.dng"
        echo "DEBUG: ${base}.dng が見つかりました" 
      else
        echo "DEBUG: DNG検索: ${base}.DNG または ${base}.dng が見つかりません"
        # 大文字小文字を区別せずに検索
        possible_dng=$(find "$(dirname "$base")" -maxdepth 1 -type f -iname "$(basename "$base").dng" 2>/dev/null | head -1)
        if [ -n "$possible_dng" ]; then
          dng="$possible_dng"
          echo "DEBUG: 代替検索で見つかったDNG: $dng"
        fi
      fi
      if [ -n "$dng" ]; then
        if command -v tag >/dev/null 2>&1; then
          tag --add Yellow "$dng"
        else
          xattr -w com.apple.metadata:_kMDItemUserTags '(Yellow)' "$dng"
        fi
        TAGGED_DNGS+=("$dng")
        echo -e "${PINK}DNGにタグ付与: $(basename "$dng")${RESET}"
        # メッセージ表示後に行をクリア
        tput el
      else
        echo -e "${PINK}対応DNGなしですが Like しました${RESET}"
        # メッセージ表示後に行をクリア
        tput el
      fi
      sleep 0.1
      if [ $current_index -lt $((total_files - 1)) ]; then
        ((current_index++))
        # 露出値をリセット
        current_exposure=0
        # 画面位置を最上部に初期化
        tput cup 0 0
        display_image
      fi

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
  echo "選別結果:"
  echo "LikeされたJPEG: ${#LIKED_FILES[@]} 個"
  echo "タグ付与済みDNG: ${#TAGGED_DNGS[@]} 個"

  if [ ${#TAGGED_DNGS[@]} -gt 0 ]; then
    clear
    echo "タグ付けされたDNGファイル: ${#TAGGED_DNGS[@]} 個"
    echo ""
    echo "選択してください (↑/↓, Enter):"
    
    # 選択肢を配列に格納
    move_options=("DNGファイルを移動する" "移動しない")
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
            echo "タグ付けされたDNGファイル: ${#TAGGED_DNGS[@]} 個"
            echo ""
            echo "選択してください (↑/↓, Enter):"
            display_move_options
            ;;
          "[B")  # 下キー
            [ $selected -lt $((${#move_options[@]} - 1)) ] && ((selected++))
            clear
            echo "タグ付けされたDNGファイル: ${#TAGGED_DNGS[@]} 個" 
            echo ""
            echo "選択してください (↑/↓, Enter):"
            display_move_options
            ;;
        esac
      fi
    done
    
    # 選択に基づいて処理
    if [ "$chosen_option" = "DNGファイルを移動する" ]; then
      clear
      echo "移動先フォルダを選択してください (↑/↓, Enter):"
      
      # 移動先オプションを配列に格納
      dest_options=("$sdcard/チェック済みフォルダ" "$sdcard/選択写真" "新しいフォルダ名を入力")
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
              echo "移動先フォルダを選択してください (↑/↓, Enter):"
              display_dest_options
              ;;
            "[B")  # 下キー
              [ $selected -lt $((${#dest_options[@]} - 1)) ] && ((selected++))
              clear
              echo "移動先フォルダを選択してください (↑/↓, Enter):"
              display_dest_options
              ;;
          esac
        fi
      done
      
      # 移動先フォルダの処理
      dest_folder=""
      if [ "$chosen_dest" = "新しいフォルダ名を入力" ]; then
        clear
        echo "新しいフォルダ名を入力してください："
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
      echo "DNGファイルを移動しています..."
      for d in "${TAGGED_DNGS[@]}"; do
        if [ -f "$d" ]; then
          mv "$d" "$dest_folder/" && ((moved++))
          echo -n "."
        fi
      done
      echo ""
      echo "$moved 個のDNGファイルを「$(basename "$dest_folder")」に移動しました。"
      sleep 1
    fi
  fi

  exit 0
}

main
