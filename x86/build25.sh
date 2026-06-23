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
# 步骤2: 处理第三方插件(最佳努力,失败不阻断构建)
# ============================================
THIRD_PARTY_OK=0
if [ "$HAS_CUSTOM_PACKAGES" = "yes" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始处理第三方APK..."

    # 克隆 OpenWrt-App 仓库 (best-effort)
    echo "克隆 OpenWrt-App 仓库..."
    rm -rf /tmp/store-repo
    if git clone --depth=1 https://github.com/Arthur97172/OpenWrt-App.git /tmp/store-repo 2>/tmp/git-clone.log; then
        THIRD_PARTY_OK=1
    else
        echo "⚠️ git clone 失败(继续构建,不含第三方插件):"
        sed 's/^/    /' /tmp/git-clone.log
    fi
fi

if [ "$THIRD_PARTY_OK" = "1" ]; then
    # 创建临时目录存放第三方 APK
    mkdir -p thirdparty

    # 复制第三方 APK 到临时目录(不覆盖 base 包)
    echo "复制第三方 APK 到 thirdparty/ 目录..."
    if ! find /tmp/store-repo/apk/x86_64 -name '*.apk' -exec cp {} thirdparty/ \; 2>/dev/null; then
        echo "⚠️ 未在仓库中找到 apk/x86_64/*.apk,跳过第三方"
        THIRD_PARTY_OK=0
    fi

    APK_COUNT=$(find thirdparty -name '*.apk' 2>/dev/null | wc -l)
    echo "✅ 第三方目录现有 $APK_COUNT 个APK文件"
    if [ "$APK_COUNT" -eq 0 ]; then
        echo "⚪️ 未获取到任何第三方 apk,继续构建"
        THIRD_PARTY_OK=0
    fi
fi

if [ "$THIRD_PARTY_OK" = "1" ]; then
    # 把第三方 APK 物理放入 ImageBuilder 的 packages/ 目录。
    # 关键: IB 自带的 `apk mkndx >(>|/dev/null) 2>/dev/null || true`
    # 会默默吞掉索引构建错误,导致后面 make image 时查不到包。本
    # 处显式重建索引并把 stderr 全部暴露,便于排查问题。
    echo "复制第三方 APK 到 imagebuilder/packages/ ..."
    mkdir -p packages

    # 排除已知不可用的部分(目前为空,作为占位)
    # 要忽略某些 apk 文件,把文件名加到 SKIP_APKS,空格的 glob
    SKIP_APKS=""

    for f in thirdparty/*.apk; do
        [ -e "$f" ] || continue
        base=$(basename "$f")
        skip=0
        for s in $SKIP_APKS; do
            case "$base" in $s) skip=1 ;; esac
        done
        if [ "$skip" = "1" ]; then
            echo "  ↷ 跳过: $base"
            continue
        fi
        cp -n "$f" packages/ 2>/dev/null || cp "$f" packages/
    done

    PKG_IN_POOL=$(ls packages/ | wc -l)
    echo "✅ 第三方 APK 已合并到 packages/ (池中现共 $PKG_IN_POOL 个文件)"

    APK_BIN="staging_dir/host/bin/apk"
    APK_KEYS_DIR="keys"
    APK_SIGN_KEY="$APK_KEYS_DIR/local-private-key.pem"
    if [ ! -s "$APK_SIGN_KEY" ]; then
        APK_SIGN_KEY="$APK_KEYS_DIR/build_key.apk.sec"
    fi

    # 在 mkndx 之前预生成 EC key,与 IB Makefile 的 _check_keys 目标
    # (target/imagebuilder/files/Makefile line ~344) 用完全相同的方式。
    # 原因: IB `make image:` 先 (1) _check_profile (2) _check_keys (3) _call_image,
    # keys 是在 mkndx 之前才创建。如果我们的 mkndx 跑得比 make image 早(就是
    # 当前 build25.sh 的执行位置), key 还不存在,我们的 mkndx 实际产出的 adb
    # 是**未签名**的。后面 apk add 时用 IB 后生成的 key 去验证,签名不匹配:
    #   WARNING: opening packages.adb: UNTRUSTED signature
    #   OK: 0 B in 0 packages → "package mentioned in index not found"
    # 先动手生成 keys 解决这个时序问题。IB 的 _check_keys 见到 keys 已存在
    # 会直接跳过,不会重复生成。
    OPENSSL_BIN="staging_dir/host/bin/openssl"
    NE_KEY="$APK_KEYS_DIR/local-private-key.pem"
    NEED_KEY_GEN=0
    if [ ! -s "$NE_KEY" ] && [ ! -s "$APK_KEYS_DIR/build_key.apk.sec" ]; then
        NEED_KEY_GEN=1
    fi
    if [ "$NEED_KEY_GEN" = "1" ] && [ -x "$OPENSSL_BIN" ]; then
        echo "🔑 预生成 EC 签名 key(与 IB _check_keys 一致)..."
        mkdir -p "$APK_KEYS_DIR"
        if ! "$OPENSSL_BIN" ecparam -name prime256v1 -genkey -noout -out "$NE_KEY" 2>/dev/null; then
            echo "⚠️ ecparam 生成私钥失败,继续依赖 IB 的 _check_keys"
        else
            # IB line 347: sed -i '1s/^/untrusted comment: Local build key\n/'
            sed -i '1s/^/untrusted comment: Local build key\n/' "$NE_KEY" 2>/dev/null
            if "$OPENSSL_BIN" ec -in "$NE_KEY" -pubout > "$APK_KEYS_DIR/local-public-key.pem" 2>/dev/null; then
                sed -i '1s/^/untrusted comment: Local build key\n/' "$APK_KEYS_DIR/local-public-key.pem" 2>/dev/null
                ls -la "$APK_KEYS_DIR/"
                echo "✅ EC key 就绪:$NE_KEY"
            else
                echo "⚠️ 导出公钥失败,继续依赖 IB 的 _check_keys"
            fi
        fi
    fi

    # 在 IB 子目录内运行 ../staging_dir/host/bin/apk mkndx。
    # 因为 (cd packages && ...) 改了 cwd,--keys-dir/--sign 相对于
    # process cwd 解析,所以这里把它们展开为绝对路径。
    run_mkndx() {
        local args=("$@")
        local cmd=(../"$APK_BIN" mkndx)
        if [ -s "$APK_SIGN_KEY" ]; then
            cmd+=(--keys-dir "$(pwd)/$APK_KEYS_DIR")
            cmd+=(--sign "$(pwd)/$APK_SIGN_KEY")
        fi
        cmd+=(--allow-untrusted --output packages.adb "${args[@]}")
        "${cmd[@]}"
    }

    if [ -x "$APK_BIN" ]; then
        # 关键: IB 25.12.x 默认 CONFIG_SIGNATURE_CHECK=y(.config 第 234 行),
        # apk 调用**没有** --allow-untrusted。所有 packages.adb 必须用
        # local-private-key.pem 签名,否则 apk 读到时:
        #   "WARNING: ./packages/packages.adb: UNTRUSTED signature"
        # → 整库丢弃("OK: 0 B in 0 packages") → "package mentioned in index not found"
        # 流程:
        #   1) 显式列 apk 给 mkndx(避免 *.apk glob 在某环境不展开 → 0 字节假签 adb)
        #   2) 整体失败逐个排错,坏 apk 移到 .bad 后用剩余的重建
        #   3) touch packages.adb 把 mtime 设到所有 *.apk 之后,IB 检测认为 adb
        #      是最新的,不会执行默认的 mkndx(默认调用无声覆盖,entails 0 字节)
        APK_FILES=()
        for f in packages/*.apk; do
            [ -e "$f" ] || continue
            APK_FILES+=("$(basename "$f")")
        done
        PKG_COUNT="${#APK_FILES[@]}"
        echo "🔧 显式重建 SIGNED packages.adb 索引(待索引 apk 数量: $PKG_COUNT)..."
        if [ "$PKG_COUNT" -eq 0 ]; then
            echo "⚠️ packages/ 是空的,没有 apk 可索引,跳过"
        elif (cd packages && run_mkndx "${APK_FILES[@]}"); then
            echo "✅ SIGNED packages.adb 已就绪 ($PKG_COUNT 个 apk)"
        else
            echo "⚠️ mkndx 整体失败,逐个诊断损坏的 apk ..."
            BAD=()
            for entry in "${APK_FILES[@]}"; do
                if ! (cd packages && run_mkndx "$entry"); then
                    echo "  ✗ 损坏: packages/$entry"
                    BAD+=("$entry")
                fi
            done
            if [ "${#BAD[@]}" -gt 0 ]; then
                echo "🚮 暂时移出损坏的 apk ..."
                mkdir -p packages/.bad
                for entry in "${BAD[@]}"; do
                    mv "packages/$entry" "packages/.bad/$entry"
                done
                APK_FILES=()
                for f in packages/*.apk; do
                    [ -e "$f" ] || continue
                    APK_FILES+=("$(basename "$f")")
                done
                if [ "${#APK_FILES[@]}" -eq 0 ]; then
                    echo "⚠️ 没有健康的 apk 留下来,跳过重建"
                elif (cd packages && run_mkndx "${APK_FILES[@]}"); then
                    echo "✅ 已用剩余的健康 apk 重建 SIGNED 索引(损坏 apk 的功能将不可用)"
                else
                    echo "⚠️ 即便移出损坏 apk 后仍无法生成索引,继续依赖 IB 自动重建"
                fi
            fi
        fi

        # 把 packages.adb 的 mtime 设到所有 *.apk 之后,避免 IB 内部因 mkndx 旧
        # 而重建。IB 逻辑:"[ find $(PACKAGE_DIR) -cnewer packages.adb ]" → 重建;
        # 我们的 adb mtime 更新后,find 不会返回新的文件,IB 跳过重建。
        if [ -f packages/packages.adb ]; then
            touch -d "@$(($(date +%s) + 60))" packages/packages.adb 2>/dev/null || \
                touch packages/packages.adb
            echo "🔒 packages.adb mtime 已更新,IB 不会重建"
        fi
    else
        echo "⚠️ 找不到 $APK_BIN,继续依赖 IB 自动重建(不推荐)"
    fi
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
# (传 CONFIG_SIGNATURE_CHECK= 关闭 apk 签名校验。IB 25.12 默认开,
# 用 --keys-dir 信任 local key, 但我们的 key 不在 official keyset
# 里,apk 仍会判 UNTRUSTED 并整库丢弃 → 0 B/0 packages → "no such package"。
# 把签名校验关掉, apk 接受我们 mkndx 的任意 adb(包括未签的)。
# 我们的 apk 都来自受信任作者,安全风险可接受。)
# ============================================
make image CONFIG_SIGNATURE_CHECK= PROFILE=generic PACKAGES="$PACKAGES" FILES="files" ROOTFS_PARTSIZE="$ROOTFS_PARTSIZE"

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
