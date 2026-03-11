# GitHub Codespaces 迁移检查清单

## 概述

本清单提供将「漂浮大陆生存肉鸽游戏」项目从当前容器环境迁移到 GitHub Codespaces 云端开发环境的完整操作步骤。通过此迁移，您将获得完整的 Linux 桌面环境（XFCE/KDE）和 Godot 4.5.1 编辑器图形界面支持，彻底解决 headless 环境下无法创建 `.tscn` 场景文件、无法进行运行时验证的技术障碍。

## 当前项目状态确认

在开始迁移前，请确认您的项目具备以下核心资产（基于 `docs/project_inventory.md` 盘点结果）：

- **✅ 脚本文件**：37 个 GDScript 组件，完整覆盖 8 个核心系统
- **✅ 预制体场景**：36 个 `.tscn` 文件，包括建筑、武器、怪物、角色、资源等
- **✅ 纹理资源**：205 个 PNG 文件，已全部正确导入（`.import` 文件完整）
- **✅ 设计文档**：21 个 Markdown 文档，完整覆盖 GDD、技术架构、迁移路线图
- **⚠️ 占位符组件**：作物预制体使用 ColorRect 占位符，集成测试场景使用占位符 UID

## 步骤 1：准备工作

### 1.1 检查本地项目结构
确保您的本地项目目录包含以下核心目录和文件：

```
floating-island-survival/
├── godot_project/          # Godot 项目主目录
│   ├── project.godot       # 项目配置文件
│   ├── assets/             # 纹理资源
│   ├── scripts/           # 37 个 GDScript 脚本
│   └── scenes/            # 36 个预制体场景
├── docs/                  # 21 个设计文档
├── outputs/               # 交付物目录
├── src/                   # 工具脚本
├── data/                  # 数据文件
└── temp/                  # 临时文件
```

### 1.2 确认 Git 已安装
在终端中运行以下命令检查 Git 版本：

```bash
git --version
```

预期输出：`git version 2.x.x` 或更高版本。

## 步骤 2：创建 GitHub 仓库

### 2.1 仓库配置参数
请使用以下配置创建新仓库，与您截图中的设置完全一致：

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| **仓库名称** | `floating-island-survival` | 保持项目名称一致性 |
| **所有者** | `TDdemo`（您的 GitHub 账号） | 确保您拥有推送权限 |
| **可见性** | **公开**（Public） | 便于协作与展示 |
| **初始化选项** | **不初始化**（不勾选任何选项） | 保持空白仓库，避免文件冲突 |

### 2.2 创建仓库操作步骤
1. 访问 [GitHub.com](https://github.com)，登录您的账号
2. 点击右上角「+」按钮，选择「New repository」
3. 填写仓库名称：`floating-island-survival`
4. **重要**：确保以下选项全部未勾选：
   - [ ] Add a README file
   - [ ] Add .gitignore
   - [ ] Choose a license
5. 选择「Public」（公开）可见性
6. 点击「Create repository」按钮

**⚠️ 注意**：暂时不要点击「Create repository」，等待本清单全部阅读完毕后再执行。

## 步骤 3：推送项目到 GitHub 仓库

### 3.1 初始化本地 Git 仓库
在项目根目录（包含 `godot_project/` 的目录）执行以下命令序列：

```bash
# 1. 初始化 Git 仓库
git init

# 2. 添加所有文件到暂存区
git add .

# 3. 提交初始版本
git commit -m "初始提交：漂浮大陆生存肉鸽游戏 Godot 版本 - 8个核心系统完整实现"

# 4. 添加远程仓库地址（替换 YOUR_USERNAME 为您的 GitHub 用户名）
git remote add origin https://github.com/TDdemo/floating-island-survival.git

# 5. 推送代码到 main 分支
git push -u origin main
```

### 3.2 推送验证
推送成功后，刷新 GitHub 仓库页面，您应该看到：
- 文件总数：约 300+ 个文件
- 最新提交记录：显示您刚才的提交信息
- 目录结构：与本地项目完全一致

## 步骤 4：启用 GitHub Codespaces

### 4.1 启动 Codespace
1. 在仓库页面点击绿色的「Code」按钮
2. 选择「Codespaces」选项卡
3. 点击「Create codespace on main」按钮
4. 系统将自动启动一个基于浏览器的完整 Linux 桌面环境

### 4.2 环境特性
GitHub Codespaces 将提供：
- **完整 Linux 桌面**：XFCE 或 KDE 桌面环境，支持图形界面应用
- **预配置开发工具**：VSCode、终端、文件管理器
- **持久化存储**：工作区状态自动保存
- **高性能资源**：4 核 CPU、8 GB RAM、32 GB 存储空间

### 4.3 首次启动注意事项
- 首次启动可能需要 2-3 分钟完成环境初始化
- 系统会自动安装 .NET 运行时等依赖
- 建议使用 Chrome/Edge 浏览器以获得最佳性能

## 步骤 5：安装 Godot 4.5.1 编辑器

### 5.1 下载 Godot 4.5.1 稳定版
在 Codespaces 终端中执行以下命令：

```bash
# 创建安装目录
sudo mkdir -p /opt/godot

# 下载 Godot 4.5.1 稳定版（Mono 版本）
wget -O /opt/godot/Godot_v4.5.1-stable_mono_linux.x86_64 https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_mono_linux.x86_64

# 添加执行权限
sudo chmod +x /opt/godot/Godot_v4.5.1-stable_mono_linux.x86_64

# 创建全局符号链接
sudo ln -sf /opt/godot/Godot_v4.5.1-stable_mono_linux.x86_64 /usr/local/bin/godot
```

### 5.2 验证安装
运行以下命令检查 Godot 版本：

```bash
godot --version
```

预期输出：`4.5.1.stable.mono.official`

### 5.3 图形界面启动测试
在终端中运行以下命令启动 Godot 编辑器：

```bash
godot
```

预期结果：Godot 编辑器窗口正常打开，显示项目选择界面。

## 步骤 6：项目配置验证

### 6.1 打开 Godot 项目
1. 在 Godot 编辑器启动后，点击「Import」按钮
2. 浏览到项目目录：`/workspaces/floating-island-survival/godot_project/`
3. 选择 `project.godot` 文件，点击「Open」

### 6.2 验证核心资产
在 Godot 编辑器中执行以下检查：

| 检查项目 | 操作方法 | 预期结果 |
|----------|----------|----------|
| **纹理导入** | 打开 FileSystem 面板，查看 `assets/sprites/` | 所有 PNG 文件显示正常，无黄色警告图标 |
| **脚本编译** | 打开任意 GDScript 文件（如 `PlayerController.gd`） | 无语法错误提示，脚本可正常编辑 |
| **预制体加载** | 双击任意 `.tscn` 文件（如 `player.tscn`） | 场景在 2D/3D 视图中正常打开，节点结构完整 |
| **项目配置** | 点击 Project → Project Settings | 所有配置项与 `project.godot` 一致 |

### 6.3 修复占位符组件
以下组件在当前环境中使用占位符，需要在图形界面环境中重新创建：

#### 6.3.1 作物预制体（小麦、胡萝卜）
操作步骤：
1. 在 Godot 编辑器中，右键点击 `scenes/farming/` 目录（如不存在则创建）
2. 选择「New Scene」创建新场景
3. 添加 `Node2D` 作为根节点
4. 添加 `Sprite2D` 子节点，加载对应纹理（`wheat.png` / `carrot.png`）
5. 添加 `Area2D` 子节点用于交互检测
6. 附加 `CropBase.gd` 脚本
7. 保存为 `wheat.tscn` 和 `carrot.tscn`

#### 6.3.2 集成测试场景 UID
操作步骤：
1. 打开 `scenes/integration/integration_test.tscn`
2. 系统将自动检测并修复占位符 UID
3. 保存场景，Godot 会自动生成真实唯一 UID

### 6.4 运行集成测试
1. 将 `integration_test.tscn` 设为启动场景：
   - Project → Project Settings → Application → Run → Main Scene
   - 设置为 `res://scenes/integration/integration_test.tscn`
2. 点击编辑器右上角的「Play」按钮（或按 F5）
3. 预期结果：游戏窗口正常打开，显示所有 8 个系统的代表节点

## 步骤 7：重启开发计划

### 7.1 迁移后首要任务
在 Codespaces 环境就绪后，立即执行以下开发任务：

1. **创建完整作物预制体**（预计：1-2 小时）
   - 创建 `wheat.tscn` 和 `carrot.tscn` 完整预制体
   - 配置纹理引用和碰撞区域
   - 更新 `FarmManager.gd` 中的引用

2. **运行完整集成测试**（预计：2-3 小时）
   - 验证所有 8 个核心系统的集成功能
   - 测试资源采集、战斗、建造、种植等核心循环
   - 修复发现的 UID 引用或脚本错误

3. **产出可玩原型**（预计：3-5 天）
   - 集成所有系统到主游戏场景
   - 实现基础 UI 和游戏控制
   - 进行功能完整性和稳定性测试

### 7.2 预期时间线
| 阶段 | 时间点 | 交付物 |
|------|--------|--------|
| **环境迁移** | 今天（3月10日） | GitHub 仓库创建、项目推送、Codespaces 启用 |
| **Godot 配置** | 今天（3月10日） | Godot 编辑器安装、项目验证、占位符修复 |
| **作物预制体** | 明天（3月11日） | `wheat.tscn` 和 `carrot.tscn` 完整预制体 |
| **集成测试运行** | 明天（3月11日） | 所有 8 个系统集成验证报告 |
| **可玩原型** | 3月15日前 | PC 可执行文件，包含核心玩法循环 |

## 故障排除

### 常见问题与解决方案

#### 问题 1：git push 失败，提示权限错误
**解决方案**：
```bash
# 检查远程地址是否正确
git remote -v

# 如使用 HTTPS 方式，确保已登录 GitHub
# 或切换到 SSH 方式：
git remote set-url origin git@github.com:TDdemo/floating-island-survival.git
```

#### 问题 2：Codespaces 启动缓慢或卡顿
**解决方案**：
- 检查网络连接稳定性
- 关闭不必要的浏览器标签页
- 如持续问题，尝试重启 Codespace

#### 问题 3：Godot 编辑器无法启动
**解决方案**：
```bash
# 检查依赖库
ldd /opt/godot/Godot_v4.5.1-stable_mono_linux.x86_64

# 如缺少依赖，安装基础图形库
sudo apt update
sudo apt install libx11-dev libxrandr-dev libxcursor-dev libxi-dev libxinerama-dev libgl1-mesa-dev
```

#### 问题 4：纹理显示为黄色警告图标
**解决方案**：
1. 选中问题纹理文件
2. 点击「Reimport」按钮
3. 在 Import 面板中，确认压缩模式为「s3tc」
4. 点击「Reimport」

## 迁移完成确认清单

在执行完所有步骤后，请确认以下项目全部完成：

- [ ] GitHub 仓库 `TDdemo/floating-island-survival` 已创建（公开，未初始化文件）
- [ ] 本地项目已成功推送到仓库，包含所有 300+ 文件
- [ ] GitHub Codespaces 已启用，Linux 桌面环境正常启动
- [ ] Godot 4.5.1 编辑器已安装，可通过 `godot --version` 验证
- [ ] Godot 项目可正常打开，无编译错误或纹理警告
- [ ] 集成测试场景 `integration_test.tscn` 已修复 UID 引用
- [ ] 游戏可通过「Play」按钮正常运行测试

## 后续支持

如迁移过程中遇到任何问题，请参考：
- **项目文档**：`docs/` 目录下的 21 个详细设计文档
- **GitHub 帮助**：[Codespaces 文档](https://docs.github.com/en/codespaces)
- **Godot 官方**：[Godot 4.5 文档](https://docs.godotengine.org/en/4.5/)

迁移完成后，Agent 将立即规划在 Codespaces 环境中的具体开发事项，包括作物预制体完整创建、集成测试运行验证和可玩原型产出。

---
**最后更新**：2026年3月10日  
**对应项目版本**：Godot 4.5.1，8个核心系统完整实现  
**适用环境**：GitHub Codespaces（Linux 桌面）