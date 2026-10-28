#!/bin/bash
# 24.10.x 第三方插件配置 (IPK 格式) - x86-64 专用
# 启用第三方插件时取消对应注释

# adguardhome广告拦截 (adguardhome)
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES adguardhome luci-app-adguardhome luci-i18n-adguardhome-zh-cn"

# argon主题 (argon)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-theme-argon luci-app-argon-config luci-i18n-argon-config-zh-cn"

# aurora主题 (aurora)
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-aurora-config luci-theme-aurora luci-i18n-aurora-config-zh-cn"

# bandix-plus网络流量监控 (bandix-plus)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES bandix-plus luci-app-bandix-plus luci-i18n-bandix-plus-zh-cn"

# bandix网络流量监控 (bandix)
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES bandix luci-app-bandix luci-i18n-bandix-zh-cn"

# clashoo代理面板 (clashoo)
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES clashoo luci-app-clashoo luci-i18n-clashoo-zh-cn"

#CPU状态 (cpustatus)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-cpu-status"

# daede代理面板 (daede)
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES dae daed luci-app-daede"

#动态DNS
CUSTOM_PACKAGES="$CUSTOM_PACKAGES ddns-scripts-cloudflare luci-app-ddns luci-i18n-ddns-zh-cn"

# easymesh无线组网(Easymesh)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-easymesh luci-i18n-easymesh-zh-cn"

# FCC智能体 (FCC)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-fcc luci-i18n-fcc-zh-cn"

#LED指示灯控制 (ledcontrol)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-ledcontrol luci-i18n-ledcontrol-zh-cn"

# lucky内网穿透 (lucky)
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES lucky luci-app-lucky luci-i18n-lucky-zh-cn"

# MosDNS转发器 (MosDNS)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES mosdns luci-app-mosdns luci-i18n-mosdns-zh-cn"

# nikki代理面板 (nikki)
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES nikki luci-app-nikki luci-i18n-nikki-zh-cn"

# Online-upgrade在线升级 (online-upgrade)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-online-upgrade luci-i18n-online-upgrade-zh-cn"

# openclash代理面板 (openclash)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-openclash"

# partexp分区扩容 (partexp)
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-partexp luci-i18n-partexp-zh-cn"

# passwall代理面板 (passwall)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-passwall luci-i18n-passwall-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES sing-box chinadns-ng geoview shadowsocksr-libev-ssr-local shadowsocksr-libev-ssr-redir"

# poweroff关机 (poweroff)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-poweroff luci-i18n-poweroff-zh-cn"

# rtp2httpd流媒体转发 (rtp2httpd)
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES rtp2httpd luci-app-rtp2httpd luci-i18n-rtp2httpd-zh-cn"

# run插件安装工具 (run)
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-run"

#samb文件共享
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-samba4 luci-i18n-samba4-zh-cn"

#smartnetpilot智能网络向导 (smartnetpilot)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-smartnetpilot luci-i18n-smartnetpilot-zh-cn"

# Substore 订阅管理 (substore)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-substore luci-i18n-substore-zh-cn"

#watchdog看门狗
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES watchdog luci-app-watchdog luci-i18n-watchdog-zh-cn"

# tailscaleVPN代理 (tailscale)
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES tailscale luci-app-tailscale luci-i18n-tailscale-zh-cn"

# turboacc网络加速(turboacc)
#CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-turboacc luci-i18n-turboacc-zh-cn"

# tasks任务管理 (tasks)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-tasks luci-i18n-tasks-zh-cn"

# WiFi管理 (Wifimanager)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-wifimanager luci-i18n-wifimanager-zh-cn"

# Wireguard VPN控制面板 (wireguard)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-proto-wireguard qrencode"
