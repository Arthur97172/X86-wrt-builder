<div align="center">
<p align="center">
  <img src="files/screenshot/001.png" style="max-width: 100%; height: auto;" />
  <img src="./files/screenshot/banner.svg" style="max-width: 100%; height: auto;" />
</p>

  <h1>基于ImmortalWrt and OpenWrt X86-64</h1>

  <img src="https://img.shields.io/github/downloads/Arthur97172/X86-wrt-builder/total.svg?style=for-the-badge&color=32C955"/>
  <img src="https://img.shields.io/github/stars/Arthur97172/X86-wrt-builder.svg?style=for-the-badge&color=orange"/>
  <img src="https://img.shields.io/github/forks/Arthur97172/X86-wrt-builder.svg?style=for-the-badge&color=ff69b4"/>
  <img src="https://img.shields.io/github/license/Arthur97172/X86-wrt-builder.svg?style=for-the-badge&color=blueviolet"/>

  [![](https://img.shields.io/badge/-目录:-696969.svg)](#readme)
  [![](https://img.shields.io/badge/-项目介绍-FFFFFF.svg)](#-项目介绍-)
  [![](https://img.shields.io/badge/-第三方插件-FFFFFF.svg)](#-第三方插件-)
  [![](https://img.shields.io/badge/-支持设备-FFFFFF.svg)](#-支持设备-)
  [![](https://img.shields.io/badge/-项目截图-FFFFFF.svg)](#-项目截图-)
  [![](https://img.shields.io/badge/-Thanks-FFFFFF.svg)](#-Thanks-)
  [![](https://img.shields.io/badge/-免责声明-FFFFFF.svg)](#-免责声明-)
  </div>

------

## 🤔 项目介绍 [![](https://img.shields.io/badge/-项目介绍-FFFFFF.svg)](#-项目介绍-)
**目标是提供一个纯净的ImmortalWrt and OpenlWrt系统，支持24.10.x和25.12.x版本编译，并可选择是否包含Docker。**

***编译快速，基本上15分钟就可以完成编译工作。***

## 🚀 快速上手步骤

### 1. 开启 Fork 仓库的 Actions 权限
默认情况下，Fork 后的仓库 GitHub Actions 会处于禁用状态：
1. 打开你 Fork 后的 GitHub 仓库页面。
2. 点击顶部导航栏的 **Actions** 标签页。
3. 点击绿色按钮 **"I understand my workflows, go ahead and enable them"** 启用工作流。

### 2. 运行编译工作流
1. 进入 **Actions** 页面，在左侧工作流列表中选择 （例如：**`Build x86-64 Wrt-24.10.x`**）。
2. 点击右上角的 **Run workflow** 下拉菜单。
3. 在参数配置中，**选中/勾选编译 Docker 或非 Docker 固件**。
4. 点击 **Run workflow** 按钮启动编译。
5. 等待任务运行完成（图标变为绿色的 `✔`），即可在 Actions 页面底部的 **Artifacts** 区域或 **Releases** 页面下载编译好的最终固件。

## 😅 第三方插件 [![](https://img.shields.io/badge/-第三方插件-FFFFFF.svg)](#-第三方插件-)
<div align="left">

| 插件                     | 状态 | 插件                     | 状态  | 插件                    | 状态   |
|:------------------------:|:----:|:------------------------:|:-----:|:------------------------:|:------:|
| Amlogic          | ✅   | Argon        | ✅    | Bandix-plus    |  ✅     |
| Clashoo              |  ✅   | Daede                    |  ✅     | Lucky                | ✅      |
| MosDNS              |  ✅   | Netwizard                   |  ✅     | Nikki            | ✅       |
| Openclash              |  ✅   | Partexp                    |  ✅     | Poweroffdevice           | ✅       |
| Rtp2httpd              |  ✅   | Tailscale                    |  ✅      | Taskplan           | ✅        |
| Passwall              |  ✅   | Run                   |  ✅      | Adguardhome           | ✅       |
| Online-upgrade             |  ✅   |

✅ 支持 - ⏳ 计划中 - ⭕ 不支持

#### 用户可根据自己的实际需要对第三方插件的安装配置文件进行调节 ####
24.10.x版本 /shell/immortalwrt-custom-packages.sh 或 /shell/openwrt-custom-packages.sh
25.12.x版本 /shell/apk-immortalwrt-custom-packages.sh 或 /shell/apk-openwrt-custom-packages.sh

</div>

## 🤗 项目截图 [![](https://img.shields.io/badge/-项目截图-FFFFFF.svg)](#-项目截图-)
![screenshots](./files/screenshot/01.jpg)

## 🌟 Star戳一戳，好运加满！😆
> **"点过 `Star` 的朋友，颜值与智慧双双在线！✨"**
> 
> **"您的每一个⭐️，都是开源土壤里的一缕阳光，让灵感发芽，让创造生长~"**

## 🎉 Thanks [![](https://img.shields.io/badge/-Thanks-FFFFFF.svg)](#-Thanks-)
- [OpenWrt](https://github.com/Openwrt)
- [ImmortalWrt](https://github.com/immortalwrt)

## 🙏 免责声明 [![](https://img.shields.io/badge/-免责声明-FFFFFF.svg)](#-免责声明-)
- 📚 本固件仅供学习研究，严禁用于任何商业用途
- 🤝 使用本固件产生的所有后果均由使用者自行承担
- ⚠️ 固件仍可能存在缺陷，开发者不提供任何形式的技术支持
- 📜 请严格遵守国家网络安全法律法规，合法使用
- 此固件基于 **官方镜像文件构建，但不保证完全无BUG** 

<a href="#readme">
<img src="https://img.shields.io/badge/-返回顶部-FFFFFF.svg" title="返回顶部" align="right"/>
</a>
