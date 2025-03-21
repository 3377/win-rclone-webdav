# 🚀 Rclone WebDAV 挂载工具

[![license](https://img.shields.io/badge/许可证-MIT-blue.svg)](LICENSE)

## 📝 项目介绍

这是一个使用批处理脚本开发的 Windows 系统 WebDAV 自动挂载工具，基于强大的[rclone](https://rclone.org/)实现。通过简单的菜单操作，你可以轻松地将 WebDAV 服务挂载为本地磁盘驱动器，实现快速、稳定的文件访问。

## ✨ 功能特点

- 🔌 一键挂载 WebDAV 到本地磁盘（默认 H 盘）
- 🔍 支持高性能缓存，加快文件访问速度
- 🔄 断线自动重连，保证稳定性
- 🚦 实时状态监控，方便排查问题
- 🔒 密码加密功能，增强安全性
- 🔔 开机自启动功能，无需手动操作
- 🧹 简单卸载，释放系统资源

## 🛠️ 使用前准备

1. 下载并解压本工具
2. 确保目录中包含以下文件：
   - `fywebdav.bat` (主脚本)
   - `rclone.exe` (核心程序)
   - `rclone.conf` (配置文件)

## ⚙️ 配置说明

使用前需要修改`rclone.conf`文件，配置你的 WebDAV 服务信息：

```conf
[drfycloud]
type = webdav
url = https://你的WebDAV服务地址
vendor = 供应商类型（如nextcloud、owncloud等，可选）
user = 你的用户名
pass = 加密后的密码（可通过工具选项6生成）
```

### 关键参数配置表

| 参数           | 说明              | 示例值                       | 配置位置                      |
| -------------- | ----------------- | ---------------------------- | ----------------------------- |
| `[drfycloud]`  | 配置名称          | `[drfycloud]`                | rclone.conf 文件第 1 行       |
| `type`         | 服务类型          | `webdav`                     | rclone.conf 文件第 2 行       |
| `url`          | WebDAV 服务器地址 | `https://example.com/webdav` | rclone.conf 文件第 3 行       |
| `vendor`       | 供应商类型        | `nextcloud`                  | rclone.conf 文件第 4 行       |
| `user`         | 登录账号          | `yourname`                   | rclone.conf 文件第 5 行       |
| `pass`         | 加密后的密码      | `xxxx加密字符串xxxx`         | rclone.conf 文件第 6 行       |
| `CACHE_DIR`    | 缓存目录路径      | `D:\drfycloudtmp`            | fywebdav.bat 文件开头常量部分 |
| `DRIVE_LETTER` | 挂载的盘符        | `H:`                         | fywebdav.bat 文件开头常量部分 |

### 批处理脚本中可调整的高级参数

| 参数                          | 说明         | 当前值  | 配置位置                   |
| ----------------------------- | ------------ | ------- | -------------------------- |
| `--buffer-size`               | 缓冲区大小   | `4096M` | fywebdav.bat 中 mount 部分 |
| `--vfs-read-chunk-size`       | 读取块大小   | `128M`  | fywebdav.bat 中 mount 部分 |
| `--vfs-read-chunk-size-limit` | 最大块大小   | `2G`    | fywebdav.bat 中 mount 部分 |
| `--vfs-cache-max-size`        | 最大缓存大小 | `10G`   | fywebdav.bat 中 mount 部分 |
| `--vfs-cache-max-age`         | 缓存过期时间 | `12h`   | fywebdav.bat 中 mount 部分 |
| `--transfers`                 | 并行传输数   | `16`    | fywebdav.bat 中 mount 部分 |
| `--checkers`                  | 并行检查数   | `16`    | fywebdav.bat 中 mount 部分 |

## 🚀 使用说明

1. **双击运行** `fywebdav.bat`
2. 在菜单中选择相应功能：

| 选项 | 功能                   |
| ---- | ---------------------- |
| 1    | 挂载 WebDAV 到 H 盘    |
| 2    | 卸载 H 盘              |
| 3    | 检查挂载状态           |
| 4    | 设置开机自启动         |
| 5    | 取消开机自启动         |
| 6    | 获取 rclone 的加密密码 |
| 7    | 退出程序               |

## 📈 性能优化

脚本使用了以下 rclone 参数优化性能：

- `--vfs-cache-mode full`: 启用完整缓存模式
- `--use-mmap`: 使用内存映射提高性能
- `--buffer-size 4096M`: 大缓冲区提升传输速度
- `--vfs-read-chunk-size 128M`: 优化读取块大小
- `--transfers 16`: 并行传输数量
- `--checkers 16`: 并行检查数量

## 🔧 故障排除

如果挂载失败，请检查：

1. 配置文件是否正确
2. 查看日志文件`rclone_mount.log`和`rclone.log`
3. 确认 WebDAV 服务是否可访问
4. 检查防火墙是否阻止了连接

常见问题解决方案：

| 问题           | 可能原因        | 解决方法                            |
| -------------- | --------------- | ----------------------------------- |
| 脚本闪退       | 配置文件缺失    | 确保 rclone.exe 和 rclone.conf 存在 |
| 无法挂载       | WebDAV 地址错误 | 检查 rclone.conf 中的 url 参数      |
| 挂载后无法访问 | 网络连接问题    | 检查 WebDAV 服务是否可访问          |
| 文件访问缓慢   | 缓存设置不当    | 调整缓存和缓冲区参数                |
| 无法自动启动   | 权限不足        | 尝试以管理员身份运行                |

## 📃 日志文件

- `rclone_mount.log`: 记录挂载状态和操作日志
- `rclone.log`: rclone 详细运行日志，用于调试问题

## 🔐 安全说明

- 密码加密：使用工具中的"获取 rclone 的加密密码"功能加密 WebDAV 密码
- 所有凭据只保存在本地配置文件中
- 建议定期更改密码，保护账户安全

## 💻 系统要求

- Windows 7/8/10/11
- 不需要管理员权限（除非挂载目录需要特殊权限）
- 建议保留至少 10GB 的空闲磁盘空间用于缓存

## 📜 许可证

本项目基于 MIT 许可证开源。

## 🙏 致谢

- 感谢[rclone](https://rclone.org/)项目提供的核心功能
- 感谢所有为这个项目提供反馈和建议的用户

---

⭐ 如果你喜欢这个工具，请给它点个星！
