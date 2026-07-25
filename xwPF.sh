#!/bin/bash

# xwPF - Realm 端口转发管理工具
# Bootstrap 引导器 + 入口

# 安装路径
INSTALL_DIR="/usr/local/bin"
LIB_DIR="$INSTALL_DIR/lib"
SHORTCUT_PATH="/usr/local/bin/pf"

# 加速源前缀：留空为直连；网络受限时可设为 https://v6.gh-proxy.org/ 等代理
# 用法示例（一键安装时一并让内部下载走加速）：
#   wget -qO- https://v6.gh-proxy.org/https://raw.githubusercontent.com/zywe03/realm-xwPF/main/xwPF.sh | GH_PROXY="https://v6.gh-proxy.org/" sudo bash -s install
# 已安装后临时启用：
#   GH_PROXY="https://v6.gh-proxy.org/" pf
GH_PROXY="${GH_PROXY:-}"

# 仓库地址（脚本/模块原始文件，可经加速源前缀）
REPO_RAW_URL="${GH_PROXY}https://raw.githubusercontent.com/zywe03/realm-xwPF/main"
# realm 官方发布地址（版本检测与二进制下载，可经加速源前缀）
REALM_RELEASE_BASE="${GH_PROXY}https://github.com/zhboner/realm/releases"

# 模块列表（加载顺序）
LIB_FILES=("core.sh" "rules.sh" "server.sh" "realm.sh" "ui.sh")

# 颜色
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_YELLOW='\033[1;33m'
_BLUE='\033[0;34m'
_NC='\033[0m'

# 下载函数
_download() {
    local url="$1" target="$2"
    curl -fsSL --connect-timeout 10 --max-time 60 "$url" -o "$target" 2>/dev/null ||
    wget -qO "$target" "$url" 2>/dev/null
}

# 安装/更新脚本文件到系统（幂等）
_bootstrap() {
    echo -e "${_YELLOW}正在安装/更新脚本文件...${_NC}"

    mkdir -p "$LIB_DIR"

    # 下载入口脚本
    if _download "$REPO_RAW_URL/xwPF.sh" "$INSTALL_DIR/xwPF.sh"; then
        chmod +x "$INSTALL_DIR/xwPF.sh"
        echo -e "  ${_GREEN}✓${_NC} xwPF.sh"
    else
        echo -e "  ${_RED}✗${_NC} xwPF.sh 下载失败"
        return 1
    fi

    # 下载所有模块
    local failed=0
    for f in "${LIB_FILES[@]}"; do
        if _download "$REPO_RAW_URL/lib/$f" "$LIB_DIR/$f"; then
            echo -e "  ${_GREEN}✓${_NC} lib/$f"
        else
            echo -e "  ${_RED}✗${_NC} lib/$f 下载失败"
            failed=1
        fi
    done

    [ "$failed" -eq 1 ] && return 1

    # 创建快捷命令
    ln -sf "$INSTALL_DIR/xwPF.sh" "$SHORTCUT_PATH"
    echo -e "${_GREEN}✓ 快捷命令已创建: pf${_NC}"

    echo -e "${_GREEN}=== 脚本安装完成${_NC}"
    echo ""
}

# 加载模块
_load_libs() {
    if [ ! -d "$LIB_DIR" ] || [ ! -f "$LIB_DIR/core.sh" ]; then
        echo -e "${_RED}错误: 未找到模块目录，请先安装${_NC}"
        echo -e "${_BLUE}wget -qO- ${REPO_RAW_URL}/xwPF.sh | sudo bash -s install${_NC}"
        return 1
    fi

    for f in "${LIB_FILES[@]}"; do
        if [ -f "$LIB_DIR/$f" ]; then
            source "$LIB_DIR/$f"
        else
            echo -e "${_RED}错误: 缺少模块 $f${_NC}"
            return 1
        fi
    done
}

# 主入口
case "${1:-}" in
    install)
        [ "$(id -u)" -ne 0 ] && { echo -e "${_RED}错误: 需要 root 权限${_NC}"; exit 1; }
        _bootstrap || exit 1
        _load_libs || exit 1
        _SKIP_SCRIPT_UPDATE=1 smart_install
        ;;
    *)
        _load_libs || exit 1
        main "$@"
        ;;
esac
