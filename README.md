# Android 固件分区提取与 KernelSU 自动补丁工具

这是一个基于 GitHub Actions 的自动化工具，旨在帮助用户从 Android 固件（payload.bin）中提取指定分区，并可选地使用 KernelSU 进行 LKM 模式的 Root 补丁。

## 🛠️ 使用方法

1. 获取`GitHub Token` 点击右上角的个人头像---`Settings`-----`Developer Settings`---`Personal access tokens`创建密钥
2. **Fork 本仓库** 到你的 GitHub 账号下。
3. 进入仓库的`Settings`---`Secrets and variables`---`Repository secrets`---`NewRepository secrets`--变量名为`TOKEN`---并粘贴已获取的密钥
4. 进入仓库的 **Actions** 页面。
6. 在左侧选择 **"固件分区提取与 KernelSU 补丁"** 工作流。
7. 点击右侧的 **"Run workflow"**，填写以下参数：
   - **固件 ZIP 下载地址**：固件的直接下载链接。
   - **需要提取的分区**：默认为 `boot,init_boot`，可根据需要修改。
   - **是否使用 KernelSU 进行补丁**：勾选即开启补丁功能。
   - **Magisk 版本**：用于提取 `magiskboot` 工具（如 `30.6`），需与 [Magisk](https://github.com/topjohnwu/Magisk/releases) 官方 Release 的 版本一致。
   - **KernelSU 版本**：指定 KSU 版本（如 `3.0.0`）。
   - **KMI 版本**：指定内核版本（如 `android15-6.6`），需与 KSU 官方 Release 的 `.ko` 文件名匹配。
   - **需要补丁的目标分区**：通常为 `init_boot` 或 `boot`。
   - **上传选项**：选择上传到 Releases 或 Artifacts。

## 📂 文件说明

- `.github/workflows/extract-partitions-Kernelsu.yml`: 核心工作流配置文件。
- `README.md`: 本说明文档。

## ⚠️ 注意事项

- **KMI 版本匹配**：KernelSU 补丁非常依赖 KMI 版本的准确性，请务必确认你的内核版本。
- **存储空间**：GitHub Actions 有存储限制，建议定期手动检查或依赖内置的自动清理功能。
- **免责声明**：本工具仅供技术交流使用，刷机有风险，操作需谨慎。

## 🤝 插件支持

- [payload-dumper-go](https://github.com/ssut/payload-dumper-go)
- [KernelSU](https://github.com/tiann/KernelSU)
- [Magisk](https://github.com/topjohnwu/Magisk)
- [delete-workflow-runs](https://github.com/Mattraks/delete-workflow-runs)
- [delete-older-releases](https://github.com/dev-drprasad/delete-older-releases)
