#!/bin/bash
# OpenWrt 25.12.x x86-64 构建脚本
# 在 imagebuilder 目录下运行
ROOTFS_PARTSIZE=${ROOTFS_PARTSIZE:-"2048"}
INCLUDE_DOCKER=${INCLUDE_DOCKER:-"no"}

echo "Rootfs Size: $ROOTFS_PARTSIZE MB"
echo "Include Docker: $INCLUDE_DOCKER"

mkdir -p extra-packages
mkdir -p packages

# 加载第三方插件配置（使用 25.12 配置）
# 必须在同步仓库之前 source，因为其内容决定是否需要 clone
CUSTOM_PACKAGES=""
source apk-custom-packages.sh

# 只有当选择了第三方插件时才同步第三方仓库
if [ -n "$CUSTOM_PACKAGES" ]; then
    echo "检测到已选择第三方插件: $CUSTOM_PACKAGES"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 同步第三方软件仓库..."
    if [ -d "/tmp/store-repo" ]; then
        echo "仓库已存在，更新中..."
        git -C /tmp/store-repo pull --ff-only || {
            echo "❌ git pull 失败，删除旧仓库重新 clone..."
            rm -rf /tmp/store-repo
            git clone --depth=1 https://github.com/Arthur97172/OpenWrt-App.git /tmp/store-repo
        }
    else
        git clone --depth=1 https://github.com/Arthur97172/OpenWrt-App.git /tmp/store-repo || {
            echo "❌ git clone 失败！"
            exit 1
        }
    fi

    # 检查 clone 结果
    if [ ! -d "/tmp/store-repo/apk/x86_64" ]; then
        echo "❌ 仓库结构异常，apk/x86_64 目录不存在"
        exit 1
    fi

    # 复制 x86 的所有内容（.run 文件和 .apk 目录）
    cp -r /tmp/store-repo/apk/x86_64/* extra-packages/
    echo "✅ Run/apk 文件已复制到 extra-packages/"

    # 解压并拷贝 apk/ipk 到 packages/
    sh prepare-packages.sh
    echo "打印 packages 目录（包含 APK 文件）："
    ls -lah packages/ | grep -E '\.(apk|ipk)$' | tail -10

    # 确认第三方 APK 文件是否存在
    APK_COUNT=$(find packages/ -name '*.apk' | wc -l)
    echo "共 $APK_COUNT 个 APK 文件在 packages/ 目录"
    if [ "$APK_COUNT" -eq 0 ]; then
        echo "⚠️ 警告：packages/ 目录中没有找到 APK 文件，make image 可能失败"
    fi
else
    echo "⚪️ 未选择第三方插件，跳过第三方仓库同步"
fi

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

# [合并第三方插件]
PACKAGES="$PACKAGES $CUSTOM_PACKAGES"

echo "$(date '+%Y-%m-%d %H:%M:%S') - 编译包列表:"
echo "$PACKAGES"

# 若构建 luci-app-openclash 则添加内核
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

# 执行 make image
make image PROFILE=generic PACKAGES="$PACKAGES" FILES="files" ROOTFS_PARTSIZE="$ROOTFS_PARTSIZE"

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
