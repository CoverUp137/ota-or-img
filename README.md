# Firmware Partition Extractor GitHub Action

本项目提供了一个 GitHub Action 工作流，用于自动化从 Android 手机固件 ZIP 包中提取指定分区（如 `boot.img`, `vendor_boot.img` 等）文件，并将提取出的文件和固件信息文件 (`payload_properties.txt`) 上传到 GitHub Releases。

## 核心功能

*   **远程固件下载**: 通过 `workflow_dispatch` 手动输入固件 ZIP 包的下载链接。
*   **自动提取**: 使用高效的 `payload-dumper-go` 工具从 `payload.bin` 中提取指定的分区文件。
*   **固件信息保留**: 提取并上传固件包中的 `payload_properties.txt` 文件，用于记录固件版本和设备信息。
*   **自动发布**: 将提取出的分区文件和固件信息文件自动打包并发布到 GitHub Releases。

## 如何使用

### 1. 准备工作

1.  **Fork 本项目**：将本项目 Fork 到你自己的 GitHub 账号下。
2.  **获取固件链接**：准备好你的 Android 固件 ZIP 包的直接下载链接。
3.  **（必须）配置 Secrets**：本项目使用 `GITHUB_TOKEN` 创建 Release，在 `Settings`--- `secrets and variables` 中填入 `TOKEN` 。

### 2. 运行工作流

1.  进入你的 Fork 后的项目页面。
2.  点击上方的 **Actions** 标签页。
3.  在左侧导航栏中，点击 **Extract Partitions from Firmware** 工作流。
4.  点击 **Run workflow** 按钮。
5.  在弹出的表单中，填写以下信息：
    *   **Firmware ZIP URL**: 固件 ZIP 包的直接下载链接。
    *   **Partitions to extract (comma separated, e.g., boot,init_boot,vendor_boot)**: 
        *   输入你想要提取的分区名称，多个分区之间用逗号 `,` 分隔。
        *   例如：`boot,dtbo,vendor_boot`
        *   **注意**：分区名称必须是 `payload.bin` 中实际包含的名称。如果不确定，可以先尝试运行一次，查看日志中 `payload-dumper-go` 的输出。

6.  点击 **Run workflow** 按钮启动工作流。

### 3. 查看结果

1.  工作流运行完成后，进入项目的 **Releases** 标签页。
2.  你将看到一个新的 Release，其标题将包含提取的固件版本（如果 `payload_properties.txt` 中包含该信息）。
3.  Release 附件中将包含你指定提取的所有分区文件（`.img` 文件）以及 `payload_properties.txt` 文件。

## 工作流文件 (`.github/workflows/extract_partitions.yml`)

以下是工作流的详细步骤：

| 步骤名称 | 描述 |
| :--- | :--- |
| `Checkout code` | 检出仓库代码。 |
| `Install dependencies` | 安装 `wget`, `xz-utils`, `unzip` 等依赖。 |
| `Download payload-dumper-go` | 下载并解压 `payload-dumper-go` 工具。 |
| `Download Firmware` | 使用 `wget` 下载用户提供的固件 ZIP 包。 |
| `Extract payload_properties.txt and payload.bin` | 从 ZIP 包中解压出 `payload.bin` 和 `payload_properties.txt`。如果存在 `payload_properties.txt`，则尝试提取设备型号。 |
| `Extract Partitions` | 使用 `./payload-dumper-go -p <partitions> -o output payload.bin` 命令提取指定分区到 `output` 目录。 |
| `Prepare Release Assets` | 准备待上传的文件列表。 |
| `Create Release and Upload Assets` | 使用 `softprops/action-gh-release` Action 创建新的 Release，并将 `output` 目录下的所有文件和 `payload_properties.txt` 作为附件上传。 |

## 许可证

本项目基于 MIT 许可证发布。
