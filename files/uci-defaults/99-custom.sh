#!/bin/sh
# 仅首次运行Wrt时，会执行以下脚本。重启后消失

LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >>$LOGFILE
# 设置默认防火墙规则，方便虚拟机首次访问 WebUI
uci set firewall.@zone[1].input='ACCEPT'

# 设置主机名
uci set system.@system[0].hostname='WRTVERSIONINFO'
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'

# 设置默认语言为简体中文
uci set luci.main.lang='zh_cn'
# 保存设置
uci commit system
uci commit luci

# 计算网卡数量
count=0
ifnames=""
for iface in /sys/class/net/*; do
    iface_name=$(basename "$iface")
    # 检查是否为物理网卡（排除回环设备和无线设备）
    if [ -e "$iface/device" ] && echo "$iface_name" | grep -Eq '^eth|^en'; then
        count=$((count + 1))
        ifnames="$ifnames $iface_name"
    fi
done
# 删除多余空格
ifnames=$(echo "$ifnames" | awk '{$1=$1};1')

# 网络设置
if [ "$count" -eq 1 ]; then
    # 单网口设备：采用 DHCP 模式
    # IP 地址由上级路由器自动分配
    # 单网口设备不支持在此处修改 IP
    uci set network.lan.proto='dhcp'
    uci delete network.lan.ipaddr
    uci delete network.lan.netmask
    uci delete network.lan.gateway
    uci delete network.lan.dns

elif [ "$count" -gt 1 ]; then
    # 提取第一个接口作为 WAN
    wan_ifname=$(echo "$ifnames" | awk '{print $1}')

    # 剩余接口作为 LAN
    lan_ifnames=$(echo "$ifnames" | cut -d ' ' -f2-)

    # =========================
    # WAN 配置
    # =========================
    uci set network.wan=interface
    uci set network.wan.device="$wan_ifname"
    uci set network.wan.proto='dhcp'

    # =========================
    # WAN6 配置
    # =========================
    uci set network.wan6=interface
    uci set network.wan6.device="$wan_ifname"

    # =========================
    # br-lan 端口配置
    # =========================
    # 查找名称为 br-lan 的 device section
    section=$(uci show network | awk -F '[.=]' \
        '/\.@?device\[\d+\]\.name=.br-lan.$/ {print $2; exit}')

    if [ -z "$section" ]; then
        echo "error: cannot find device 'br-lan'." >> "$LOGFILE"
    else
        # 删除原来的 ports 列表
        uci -q delete "network.$section.ports"

        # 将剩余网口加入 br-lan
        for port in $lan_ifnames; do
            uci add_list "network.$section.ports"="$port"
        done

        echo "ports of device 'br-lan' updated." >> "$LOGFILE"
    fi

    # =========================
    # LAN 配置
    # =========================
    # 多网口设备使用静态 IP
    # __IPADDR__ 会由 Workflow 中的 sed 自动替换
    uci set network.lan.proto='static'
    uci set network.lan.ipaddr='__IPADDR__'
    uci set network.lan.netmask='255.255.255.0'
fi

# =========================
# SSH / Web 管理
# =========================
# 设置所有网口可连接 SSH
uci delete ttyd.@ttyd[0].interface
uci set dropbear.@dropbear[0].Interface=''

# =========================
# 保存配置
# =========================
uci commit network
uci commit

# 清理并还原 Banner
cp /etc/banner1/banner /etc/
rm -r /etc/banner1

# 设置作者描述信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="WRTVERSIONINFO VERXXXX"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

exit 0
