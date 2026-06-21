#!/bin/bash
# OpenWrt 25.12.x x86-64 构建脚本
# 在 imagebuilder 目录下运行
ROOTFS_PARTSIZE=${ROOTFS_PARTSIZE:-"2048"}
INCLUDE_DOCKER=${INCLUDE_DOCKER:-"no"}

echo "Rootfs Size: $ROOTFS_PARTSIZE MB"
echo "Include Docker: $INCLUDE_DOCKER"

# [重要] 2026.6.21 修复: ImageBuilder 的 repositories 文件只支持 https:// URL
# 但 make image 支持通过 --extra_packages 参数安装 packages/ 目录下的本地包
# 所以 APK 文件应该复制到 packages/ 目录，而不是添加到 repositories

# ============================================
# 步骤1: 加载第三方插件配置
# ============================================
CUSTOM_PACKAGES=""
source apk-custom-packages.sh

# 定义所需安装的包列表
# [注意] libc / libgcc 由 base 系统提供，不单独列出
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

# [LuCI 界面和主题 - OpenWrt 25.12.x 需从自定义源安装，此处注释]
PACKAGES="$PACKAGES luci-base luci-i18n-base-zh-cn luci-mod-admin-full luci-theme-material"

# [常用插件]
PACKAGES="$PACKAGES luci-app-samba4 luci-i18n-samba4-zh-cn luci-app-upnp luci-i18n-upnp-zh-cn luci-app-wol luci-i18n-wol-zh-cn luci-app-ddns luci-i18n-ddns-zh-cn luci-app-ttyd luci-i18n-ttyd-zh-cn luci-app-package-manager luci-i18n-package-manager-zh-cn"

# [Docker 插件]
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    echo "🐳 Docker enabled, adding docker packages"
    PACKAGES="$PACKAGES docker docker-compose luci-app-dockerman luci-i18n-dockerman-zh-cn"
fi

# ============================================
# 步骤2: 处理第三方插件
# ============================================
if [ -n "$CUSTOM_PACKAGES" ]; then
    echo "检测到已选择第三方插件: $CUSTOM_PACKAGES"

    # 检查仓库是否已克隆
    if [ ! -d "/tmp/store-repo/apk/x86_64" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 克隆 OpenWrt-App 仓库..."
        rm -rf /tmp/store-repo
        git clone --depth=1 https://github.com/Arthur97172/OpenWrt-App.git /tmp/store-repo || {
            echo "❌ git clone 失败！"
            exit 1
        }
    fi

    # 将 APK 文件复制到 packages/ 目录 (ImageBuilder 会自动扫描此目录)
    mkdir -p packages

    # 复制 x86_64 下的所有 apk 文件
    find /tmp/store-repo/apk/x86_64 -name '*.apk' -exec cp {} packages/ \;

    APK_COUNT=$(find packages -name '*.apk' | wc -l)
    echo "✅ 复制 $APK_COUNT 个APK文件到 packages/ 目录"

    if [ "$APK_COUNT" -eq 0 ]; then
        echo "❌ 没有找到APK文件，无法继续"
        exit 1
    fi

    # 生成APK本地索引 (让 ImageBuilder 能识别本地包)
    echo "正在生成本地APK索引..."

    # 查找apk工具
    APK_TOOL=""
    for path in "./staging_dir/host/bin/apk" "./usr/bin/apk" "$(find /tmp -name 'apk' -type f 2>/dev/null | head -1)"; do
        if [ -x "$path" ]; then
            APK_TOOL="$path"
            break
        fi
    done

    if [ -n "$APK_TOOL" ]; then
        echo "使用apk工具: $APK_TOOL"
        # 在 packages 目录内生成索引
        cd packages

        # 生成APK索引
        $APK_TOOL index -o APKINDEX.tar.gz *.apk 2>/dev/null

        # 签名索引
        ABUILD_SIGN="${APK_TOOL%/*}/abuild-sign"
        if [ -x "$ABUILD_SIGN" ]; then
            $ABUILD_SIGN APKINDEX.tar.gz 2>/dev/null
            echo "✅ APK索引签名完成"
        fi

        # 回到 imagebuilder 根目录
        cd ..
    else
        echo "⚠️ 未找到apk工具，跳过索引生成"
    fi

    # 添加本地包源 (用于安装时)
    # 注意: 必须添加换行符确保文件格式正确
    # 2026.6.21 修复: ImageBuilder 支持 file: 协议指向 packages/ 目录
    if ! grep -q "file:packages" repositories 2>/dev/null; then
        # 确保文件末尾有换行符
        [ -n "$(tail -c 1 repositories)" ] && echo "" >> repositories
        echo "file:packages" >> repositories
        echo "✅ 已添加本地源 file:packages 到 repositories"
        cat repositories
    else
        echo "⚪️ 本地源已存在，跳过"
    fi

else
    echo "⚪️ 未选择第三方插件，跳过第三方仓库同步"
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