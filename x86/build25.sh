#!/bin/bash
# OpenWrt 25.12.x x86-64 构建脚本
# 在 imagebuilder 目录下运行
ROOTFS_PARTSIZE=${ROOTFS_PARTSIZE:-"2048"}
INCLUDE_DOCKER=${INCLUDE_DOCKER:-"no"}

echo "Rootfs Size: $ROOTFS_PARTSIZE MB"
echo "Include Docker: $INCLUDE_DOCKER"

# ============================================
# 步骤1: 加载第三方插件配置
# ============================================
CUSTOM_PACKAGES=""
source apk-custom-packages.sh

# 检查是否有未注释的第三方包
HAS_CUSTOM_PACKAGES="no"
if [ -n "$CUSTOM_PACKAGES" ]; then
    HAS_CUSTOM_PACKAGES="yes"
    echo "✅ 检测到第三方插件: $CUSTOM_PACKAGES"
fi

# 定义所需安装的包列表
PACKAGES=""

# [基础系统]
PACKAGES="$PACKAGES base-files block-mount ca-bundle ca-certificates dnsmasq-full dropbear fdisk firewall4 fstools grub2-bios-setup i915-firmware-dmc logd luci luci-compat luci-lib-base mkf2fs mtd netifd nftables odhcp6c odhcpd-ipv6only partx-utils ppp ppp-mod-pppoe procd-ujail ubus uci uclient-fetch urandom-seed urngd"

# [Intel 网卡驱动]
PACKAGES="$PACKAGES kmod-8139cp kmod-8139too kmod-e1000e kmod-i40e kmod-igb kmod-igbvf kmod-igc kmod-ixgbe kmod-ixgbevf kmod-amazon-ena kmod-amd-xgbe kmod-bnx2 kmod-e1000 kmod-dwmac-intel kmod-forcedeth kmod-tg3 kmod-vmxnet3 kmod-drm-i915"

# [Realtek 网卡驱动]
PACKAGES="$PACKAGES kmod-r8101 kmod-r8125 kmod-r8126 kmod-r8168 kmod-r8169 kmod-tulip"

# [USB / HID / 其他硬件]
PACKAGES="$PACKAGES kmod-usb-hid kmod-usb-net kmod-usb-net-asix kmod-usb-net-asix-ax88179 kmod-usb-core kmod-usb3 kmod-usb2 kmod-brcmfmac kmod-brcmsmac brcmfmac-firmware-usb"

# [无线驱动 - 联发科 mt792x]
PACKAGES="$PACKAGES kmod-usb-ohci kmod-usb-ohci-pci kmod-usb2-pci usbutils kmod-mac80211 kmod-mt7921-common kmod-mt7921-firmware kmod-mt7921e kmod-mt7921u kmod-mt7922-firmware kmod-mt7925-common kmod-mt7925-firmware kmod-mt7925e kmod-mt7925u kmod-mt792x-common kmod-mt792x-usb kmod-mt7992-23-firmware kmod-mt7992-firmware kmod-mt7996-233-firmware kmod-mt7996-firmware kmod-mt7996-firmware-common kmod-mt7996e kmod-mtk-t7xx"

# [文件系统]
PACKAGES="$PACKAGES kmod-fs-f2fs kmod-fs-vfat kmod-nf-nathelper kmod-nf-nathelper-extra kmod-nft-offload kmod-nft-tproxy"

# [LuCI 界面和主题]
PACKAGES="$PACKAGES luci-base luci-i18n-base-zh-cn luci-mod-admin-full luci-theme-material"

# [常用插件]
PACKAGES="$PACKAGES luci-app-samba4 luci-i18n-samba4-zh-cn luci-app-upnp luci-i18n-upnp-zh-cn luci-app-wol luci-i18n-wol-zh-cn luci-app-ddns luci-i18n-ddns-zh-cn luci-app-ttyd luci-i18n-ttyd-zh-cn luci-app-package-manager luci-i18n-package-manager-zh-cn"

# [Docker 插件]
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    echo "🐳 Docker enabled, adding docker packages"
    PACKAGES="$PACKAGES docker docker-compose luci-app-dockerman luci-i18n-dockerman-zh-cn"
fi

# ============================================
# 步骤2: 处理第三方插件（仅当存在时）
# ============================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ "$HAS_CUSTOM_PACKAGES" = "yes" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始处理第三方APK..."

    # 克隆 OpenWrt-App 仓库
    echo "克隆 OpenWrt-App 仓库..."
    rm -rf /tmp/store-repo
    git clone --depth=1 https://github.com/Arthur97172/OpenWrt-App.git /tmp/store-repo || {
        echo "❌ git clone 失败！"
        exit 1
    }

    # 创建临时目录存放第三方 APK
    mkdir -p thirdparty
    for apk in /tmp/store-repo/apk/x86_64/*.apk; do
        [ -f "$apk" ] && cp "$apk" thirdparty/
    done

    APK_COUNT=$(find thirdparty -name '*.apk' | wc -l)
    echo "✅ thirdparty/ 目录现有 $APK_COUNT 个APK文件"

    if [ "$APK_COUNT" -eq 0 ]; then
        echo "❌ 没有找到APK文件"
        exit 1
    fi

    # 查找 apk 工具（ImageBuilder 或系统）
    APK_TOOL=""
    for path in "$SCRIPT_DIR/staging_dir/host/bin/apk" "/usr/bin/apk" "/usr/local/bin/apk"; do
        if [ -x "$path" ]; then
            APK_TOOL="$path"
            break
        fi
    done

    # 使用 apk 工具生成本地索引
    echo "生成 APK 本地索引..."
    if [ -n "$APK_TOOL" ]; then
        echo "使用 apk 工具: $APK_TOOL"
        cd thirdparty
        # 生成索引，跳过签名检查
        $APK_TOOL index --output APKINDEX.tar.gz --no-check-signature *.apk 2>&1
        cd "$SCRIPT_DIR"
    else
        echo "⚠️ 未找到 apk 工具，跳过索引生成"
        # 安装 apk-tools
        echo "尝试安装 apk-tools..."
        apt-get update -qq 2>/dev/null && apt-get install -y -qq apk-tools 2>/dev/null
        if [ -x "/usr/bin/apk" ]; then
            APK_TOOL="/usr/bin/apk"
            cd thirdparty
            $APK_TOOL index --output APKINDEX.tar.gz --no-check-signature *.apk 2>&1
            cd "$SCRIPT_DIR"
        fi
    fi

    # 复制第三方 APK 和索引到 packages/ 目录
    cp thirdparty/*.apk packages/ 2>/dev/null || true
    if [ -f thirdparty/APKINDEX.tar.gz ]; then
        cp thirdparty/APKINDEX.tar.gz packages/
        echo "✅ 已复制 APKINDEX.tar.gz 到 packages/"
    fi

    echo "✅ packages/ 目录现有 $(find packages -name '*.apk' | wc -l) 个APK文件"
else
    echo "⚪️ 无第三方插件，跳过下载"
fi

# ============================================
# 步骤3: 合并第三方插件到包列表
# ============================================
PACKAGES="$PACKAGES $CUSTOM_PACKAGES"

echo "$(date '+%Y-%m-%d %H:%M:%S') - 编译包列表:"
echo "$PACKAGES"

# ============================================
# 步骤4: 特殊处理(openclash等需要额外文件)
# ============================================
if echo "$PACKAGES" | grep -q "luci-app-openclash"; then
    echo "✅ 已选择 luci-app-openclash，添加 openclash core"
    mkdir -p files/etc/openclash/core
    META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64.tar.gz"
    wget -qO- $META_URL | tar xOvz > files/etc/openclash/core/clash_meta
    chmod +x files/etc/openclash/core/clash_meta
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O files/etc/openclash/GeoIP.dat
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O files/etc/openclash/GeoSite.dat
else
    echo "⚪️ 未选择 luci-app-openclash"
fi

# ============================================
# 步骤5: 执行 make image
# ============================================
make image PROFILE=generic PACKAGES="$PACKAGES" FILES="files" ROOTFS_PARTSIZE="$ROOTFS_PARTSIZE"

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
