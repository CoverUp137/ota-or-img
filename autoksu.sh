#!/bin/bash
# 全自动KSU本地打补丁脚本，仅适配linux系统
set -e


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' 


CHECK="✅"
INFO="ℹ️"
DOWNLOAD="📥"
ROCKET="🚀"
GEAR="⚙️"
WARN="⚠️"
ERROR="❌"
FOLDER="📂"


print_header() {
    clear
    echo -e "${CYAN}${BOLD}===============================================================${NC}"
    echo -e "${CYAN}${BOLD}           KernelSU LKM 补丁工具 (本地专业版)          ${NC}"
    echo -e "${CYAN}${BOLD}===============================================================${NC}"
    echo -e "${YELLOW}${BOLD} 💡 提示: 请先将 boot.img 或 init_boot.img 放置在当前目录下${NC}"
    echo -e "${BLUE}${INFO} 系统架构: $(uname -m) | 当前时间: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${CYAN}${BOLD}---------------------------------------------------------------${NC}"
}

print_step() {
    echo -e "\n${PURPLE}${BOLD}Step $1: $2${NC}"
    echo -e "${PURPLE}---------------------------------------------------------------${NC}"
}

get_latest_release() {
    curl -s "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}


print_header

print_step "1" "准备 Magiskboot 环境"
echo -ne "${YELLOW}${GEAR} 正在检测最新版本的 Magisk... ${NC}"
MAGISK_TAG=$(get_latest_release "topjohnwu/Magisk")
echo -e "${GREEN}${MAGISK_TAG}${NC}"

if [ ! -f "magiskboot" ]; then
    echo -e "${BLUE}${DOWNLOAD} 正在下载并提取 magiskboot...${NC}"
    
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  LIB_ARCH="x86_64" ;;
        aarch64) LIB_ARCH="arm64-v8a" ;;
        *)       echo -e "${RED}${ERROR} 不支持的架构: $ARCH${NC}"; exit 1 ;;
    esac
    
    curl -L -# -o Magisk.apk "https://gh.0507.dpdns.org/https://github.com/topjohnwu/Magisk/releases/download/${MAGISK_TAG}/Magisk-${MAGISK_TAG}.apk"
    unzip -q Magisk.apk "lib/${LIB_ARCH}/libmagiskboot.so" -d .
    mv "lib/${LIB_ARCH}/libmagiskboot.so" magiskboot
    chmod +x magiskboot
    rm -rf lib Magisk.apk
    echo -e "${GREEN}${CHECK} Magiskboot 准备就绪！${NC}"
else
    echo -e "${GREEN}${CHECK} 检测到已存在的 magiskboot，跳过下载。${NC}"
fi


print_step "2" "准备 KernelSU CLI (ksud)"
echo -ne "${YELLOW}${GEAR} 正在检测最新版本的 KernelSU... ${NC}"
KSU_TAG=$(get_latest_release "tiann/KernelSU")
echo -e "${GREEN}${KSU_TAG}${NC}"

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    KSUD_ASSET="ksud-x86_64-unknown-linux-musl"
elif [ "$ARCH" = "aarch64" ]; then
    KSUD_ASSET="ksud-aarch64-unknown-linux-musl"
else
    echo -e "${RED}${ERROR} 不支持的架构: $ARCH${NC}"
    exit 1
fi

if [ ! -f "ksud" ]; then
    echo -e "${BLUE}${DOWNLOAD} 正在下载 ${KSUD_ASSET}...${NC}"
    curl -L -# -o ksud "https://gh.0507.dpdns.org/https://github.com/tiann/KernelSU/releases/download/${KSU_TAG}/${KSUD_ASSET}"
    chmod +x ksud
    echo -e "${GREEN}${CHECK} ksud 准备就绪！${NC}"
else
    echo -e "${GREEN}${CHECK} 检测到已存在的 ksud，跳过下载。${NC}"
fi

print_step "3" "选择内核模块 (.ko)"
KMI_OPTIONS=(
    "android16-6.12"
    "android15-6.6"
    "android14-6.1"
    "android14-5.15"
    "android13-5.10"
    "android12-5.10"
)

echo -e "${CYAN}请选择与您设备内核匹配的版本:${NC}"
for i in "${!KMI_OPTIONS[@]}"; do
    echo -e "  ${BOLD}$((i+1)))${NC} ${KMI_OPTIONS[$i]}"
done

while true; do
    read -p "请输入数字选择 (1-${#KMI_OPTIONS[@]}): " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#KMI_OPTIONS[@]}" ]; then
        KMI_VER="${KMI_OPTIONS[$((choice-1))]}"
        echo -e "${GREEN}${CHECK} 已选择: ${BOLD}${KMI_VER}${NC}"
        break
    else
        echo -e "${RED}${ERROR} 无效输入，请重新选择。${NC}"
    fi
done

KO_FILE="${KMI_VER}_kernelsu.ko"
echo -e "${BLUE}${DOWNLOAD} 正在下载 ${KO_FILE}...${NC}"
curl -L -# -o kernelsu.ko "https://gh.0507.dpdns.org/https://github.com/tiann/KernelSU/releases/download/${KSU_TAG}/${KO_FILE}"
echo -e "${GREEN}${CHECK} 内核模块下载完成。${NC}"


print_step "4" "执行镜像补丁"

IMG_FILES=()
if [ -f "boot.img" ]; then IMG_FILES+=("boot.img"); fi
if [ -f "init_boot.img" ]; then IMG_FILES+=("init_boot.img"); fi

TARGET_IMG=""
if [ ${#IMG_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}${WARN} 当前目录下未找到 boot.img 或 init_boot.img${NC}"
    read -p "👉 请手动输入镜像文件路径: " TARGET_IMG
elif [ ${#IMG_FILES[@]} -eq 1 ]; then
    TARGET_IMG="${IMG_FILES[0]}"
    echo -e "${GREEN}${FOLDER} 自动检测到镜像: ${BOLD}${YELLOW}$TARGET_IMG${NC}"
else
    echo -e "${CYAN}检测到多个镜像文件，请选择一个:${NC}"
    for i in "${!IMG_FILES[@]}"; do
        echo -e "  ${BOLD}$((i+1)))${NC} ${IMG_FILES[$i]}"
    done
    while true; do
        read -p "请输入数字选择: " img_choice
        if [[ "$img_choice" =~ ^[0-9]+$ ]] && [ "$img_choice" -ge 1 ] && [ "$img_choice" -le "${#IMG_FILES[@]}" ]; then
            TARGET_IMG="${IMG_FILES[$((img_choice-1))]}"
            break
        else
            echo -e "${RED}${ERROR} 无效输入。${NC}"
        fi
    done
fi

if [ ! -f "$TARGET_IMG" ]; then
    echo -e "${RED}${ERROR} 错误: 找不到文件 $TARGET_IMG${NC}"
    exit 1
fi

echo -e "\n${BLUE}${ROCKET} 正在启动补丁引擎...${NC}"
./ksud boot-patch \
    --magiskboot ./magiskboot \
    --kmi "${KMI_VER}" \
    -b "$TARGET_IMG"

PATCHED_FILE=$(ls kernelsu_*.img 2>/dev/null | head -n 1)
if [ -n "$PATCHED_FILE" ]; then
    FINAL_NAME="${TARGET_IMG%.*}_ksu_patched.img"
    mv "$PATCHED_FILE" "$FINAL_NAME"
    echo -e "\n${GREEN}${BOLD}===============================================================${NC}"
    echo -e "${GREEN}${BOLD}             ${CHECK} 恭喜！补丁执行成功！ ${CHECK}             ${NC}"
    echo -e "${GREEN}${BOLD}===============================================================${NC}"
    echo -e "${YELLOW} 生成文件: ${BOLD}${FINAL_NAME}${NC}"
    echo -e "${CYAN} 存放路径: $(pwd)/${FINAL_NAME}${NC}"
else
    echo -e "\n${RED}${ERROR} 补丁失败，请检查上方输出的错误信息。${NC}"
    exit 1
fi

echo -e "\n${BLUE}${INFO} 感谢使用，祝您玩机愉快！${NC}\n"
