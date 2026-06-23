#!/bin/bash
# 25.12.x 第三方插件配置 (APK 格式) - x86-64 专用
# 启用第三方插件时取消对应注释

# 代理相关 (clashoo全家桶)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES clashoo luci-app-clashoo luci-i18n-clashoo-zh-cn"
# 代理相关 (nikki全家桶)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES nikki luci-app-nikki luci-i18n-nikki-zh-cn"
# 代理相关 (openclash)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-openclash"
# 代理相关 (daede)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES dae daed luci-app-daede"
# 主题
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-aurora-config luci-theme-aurora luci-i18n-aurora-config-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-theme-argon"
# VPN
CUSTOM_PACKAGES="$CUSTOM_PACKAGES tailscale luci-app-tailscale"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-tailscale-zh-cn"
# Quickfile
CUSTOM_PACKAGES="$CUSTOM_PACKAGES quickfile luci-app-quickfile"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-quickfile-zh-cn"

# 分区扩容 by sirpdboy
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-partexp"
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-partexp-zh-cn"
# 进阶设置 by sirpdboy
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-advancedplus"
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-advancedplus-zh-cn"
# MosDNS
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-mosdns"
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-mosdns-zh-cn"
# Turbo ACC 网络加速
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-turboacc"
# 应用过滤 openappfilter.com
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-appfilter"
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-appfilter-zh-cn"
# 设置向导 by sirpdboy
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-netwizard"
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-netwizard-zh-cn"
# 网络测速 by sirpdboy
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-netspeedtest"
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-netspeedtest-zh-cn"
# istore 商店
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-store"
