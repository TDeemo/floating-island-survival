# Unity许可证激活指引

## 概述
本文档提供在容器化环境中解决Unity许可证激活问题的详细指引。由于Unity Personal许可证需要图形界面接受许可协议，而容器环境为headless模式，因此需要采用替代方案。

## 问题分析

### 核心障碍
1. **许可证类型**：Unity Personal许可证（免费版）
2. **激活要求**：首次使用必须通过图形界面接受许可协议
3. **环境限制**：容器环境无图形界面支持
4. **命令行限制**：命令行激活仅支持Plus/Pro许可证

### 已尝试的失败方案
1. 容器内命令行激活（不支持Personal许可证）
2. Docker Unity镜像（容器权限不足）
3. xvfb虚拟显示环境（Unity仍需图形交互接受协议）

## 解决方案

### 方案一：提供已激活的许可证文件（推荐）

#### 步骤1：在图形界面环境中激活Unity
1. **环境要求**：任何支持图形界面的操作系统（Windows/macOS/Linux桌面版）
2. **安装Unity Hub**：
   - 访问 https://unity.com/download 下载Unity Hub
   - 安装并启动Unity Hub
3. **安装Unity编辑器**：
   - 在Unity Hub中选择"Installs"标签
   - 点击"Add"按钮
   - 选择版本 **2022.3.40f1**（确保与容器内版本一致）
   - 完成安装
4. **激活许可证**：
   - 启动刚安装的Unity编辑器
   - 首次启动会显示许可协议窗口
   - 阅读并接受许可协议
   - 选择"Unity Personal"许可证类型
   - 回答相关问题并完成激活

#### 步骤2：提取许可证文件
1. **找到许可证文件位置**：
   - **Linux/macOS**: `~/.local/share/unity3d/Unity/`
   - **Windows**: `C:\Users\<用户名>\AppData\Local\Unity\`
2. **识别正确的文件**：
   - 查找扩展名为 `.ulf` 的文件
   - 文件名格式通常为 `Unity_v2022.3.40f1c1.ulf`
   - 文件大小通常在1-10KB之间
3. **复制许可证文件**：
   - 将`.ulf`文件复制到安全位置

#### 步骤3：在容器环境中使用许可证文件
1. **文件传输**：
   - 将`.ulf`文件上传到容器环境
   - 建议位置：`/tmp/unity_home/.local/share/unity3d/Unity/`
2. **目录结构**：
   ```bash
   mkdir -p /tmp/unity_home/.local/share/unity3d/Unity/
   cp Unity_v2022.3.40f1c1.ulf /tmp/unity_home/.local/share/unity3d/Unity/
   ```
3. **环境变量设置**：
   ```bash
   export HOME=/tmp/unity_home
   ```

#### 步骤4：验证许可证激活
1. **验证命令**：
   ```bash
   HOME=/tmp/unity_home unity -batchmode -quit -version
   ```
2. **预期结果**：
   - 输出Unity版本信息（`2022.3.40f1c1`）
   - **无**"Can't get home directory!"错误
   - **无**"No valid Unity Editor license found"错误

### 方案二：容器外构建

#### 步骤1：准备构建环境
1. **系统选择**：
   - Windows 10/11（推荐）
   - macOS 10.14+
   - Linux桌面版（Ubuntu 20.04+）
2. **安装要求**：
   - Unity Hub
   - Unity Editor 2022.3.40f1
   - Git（用于获取项目代码）

#### 步骤2：获取项目代码
1. **克隆或复制项目**：
   ```bash
   git clone <项目仓库>  # 如果有版本控制
   # 或直接复制`漂浮大陆`文件夹
   ```
2. **验证项目结构**：
   - 确保`Assets/`文件夹完整
   - 验证`Assets/Scenes/`中的场景文件
   - 检查`Assets/Editor/BuildScript.cs`存在

#### 步骤3：执行构建
1. **使用Unity命令行构建**：
   ```bash
   # Linux/macOS示例
   /Applications/Unity/Hub/Editor/2022.3.40f1/Unity.app/Contents/MacOS/Unity \
     -quit -batchmode \
     -projectPath /path/to/漂浮大陆 \
     -executeMethod BuildScript.PerformBuild \
     -logFile build.log
   ```
2. **构建产物位置**：
   - 默认生成在`outputs/builds/PC/`目录
   - 主要文件：`漂浮大陆.x86_64`（可执行文件）

#### 步骤4：产物交付
1. **压缩构建产物**：
   ```bash
   tar -czf 漂浮大陆_pc_build.tar.gz outputs/builds/PC/
   ```
2. **传输到目标位置**：
   - 上传到服务器
   - 或直接提供给用户

### 方案三：升级到Unity Plus/Pro许可证

#### 步骤1：购买许可证
1. **访问Unity商店**：https://store.unity.com
2. **选择许可证类型**：
   - **Unity Plus**：适合小型工作室
   - **Unity Pro**：适合专业开发团队
3. **完成购买流程**：
   - 创建Unity账号（如尚未拥有）
   - 选择订阅计划
   - 完成支付

#### 步骤2：获取序列号
1. **查看许可证信息**：
   - 登录 https://id.unity.com
   - 进入"Licenses"页面
2. **找到序列号**：
   - 格式：`SB-XXXX-XXXX-XXXX-XXXX-XXXX`（macOS）
   - 格式：`E3-XXXX-XXXX-XXXX-XXXX-XXXX`（Windows）
3. **记录序列号**：用于命令行激活

#### 步骤3：命令行激活
1. **激活命令**：
   ```bash
   unity -batchmode -quit -serial <序列号> -username <邮箱> -password <密码>
   ```
2. **注意事项**：
   - 需要网络连接访问Unity许可证服务器
   - 序列号与Unity账号绑定
   - 激活后生成`.ulf`文件在用户目录

## 容器环境配置参考

### 方案一实施脚本
```bash
#!/bin/bash
# 假设已获得Unity_v2022.3.40f1c1.ulf文件

# 创建目录结构
export HOME=/tmp/unity_home
mkdir -p $HOME/.local/share/unity3d/Unity/

# 复制许可证文件（假设.ulf文件在当前目录）
cp Unity_v2022.3.40f1c1.ulf $HOME/.local/share/unity3d/Unity/

# 验证许可证
echo "验证Unity许可证..."
HOME=/tmp/unity_home unity -batchmode -quit -version

# 执行构建
echo "开始构建..."
HOME=/tmp/unity_home unity -batchmode -quit \
  -projectPath /app/data/files/漂浮大陆 \
  -executeMethod BuildScript.PerformBuild \
  -logFile temp/final_build.log
```

### 方案二实施脚本（宿主环境）
```bash
#!/bin/bash
# 宿主环境构建脚本

UNITY_PATH="/Applications/Unity/Hub/Editor/2022.3.40f1/Unity.app/Contents/MacOS/Unity"
PROJECT_PATH="/path/to/漂浮大陆"
OUTPUT_DIR="outputs/builds/PC"

# 清理旧构建产物
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# 执行构建
$UNITY_PATH -quit -batchmode \
  -projectPath $PROJECT_PATH \
  -executeMethod BuildScript.PerformBuild \
  -logFile build.log

# 检查构建结果
if [ $? -eq 0 ]; then
    echo "构建成功！产物位置：$OUTPUT_DIR"
    ls -la $OUTPUT_DIR/
else
    echo "构建失败，查看日志：build.log"
    exit 1
fi
```

## 故障排除

### 常见问题
1. **许可证文件位置错误**
   - 症状：Unity仍然报告无许可证
   - 解决：检查`.ulf`文件路径，确保在`~/.local/share/unity3d/Unity/`目录

2. **版本不匹配**
   - 症状：Unity忽略许可证文件
   - 解决：确保`.ulf`文件版本与Unity编辑器版本一致

3. **权限问题**
   - 症状：Unity无法写入许可证目录
   - 解决：确保目录可写权限，或使用`HOME`环境变量重定向

4. **网络限制**
   - 症状：在线激活失败
   - 解决：使用手动激活方案，在可上网的机器生成`.ulf`文件

### 日志分析
- **激活日志位置**：`temp/activate_license.log`
- **构建日志位置**：`temp/build_final.log`
- **关键错误信息**：
  - `No ULF license found.`：需要提供`.ulf`文件
  - `Token not found in cache`：许可证未激活
  - `Can't get home directory!`：需要设置`HOME`环境变量

## 联系支持

### Unity官方支持
- **文档中心**：https://docs.unity3d.com
- **社区论坛**：https://forum.unity.com
- **技术支持**：https://support.unity.com

### 项目相关支持
- **构建问题**：参考本文档方案
- **环境配置**：检查容器权限和网络设置
- **许可证问题**：考虑升级到Plus/Pro许可证

## 附录

### Unity许可证类型对比
| 特性 | Personal | Plus | Pro |
|------|----------|------|-----|
| 价格 | 免费 | $40/月 | $150/月 |
| 年收入上限 | $10万 | $20万 | 无限制 |
| 命令行激活 | 不支持 | 支持 | 支持 |
| 自定义启动画面 | 不支持 | 支持 | 支持 |
| 性能报告 | 基础 | 高级 | 高级 |

### 许可证文件格式
- **ALF文件**：激活许可证文件（Activation License File）
  - 用途：上传到Unity服务器生成ULF文件
  - 生成命令：`unity -batchmode -createManualActivationFile`
- **ULF文件**：Unity许可证文件（Unity License File）
  - 用途：本地激活Unity编辑器
  - 位置：`~/.local/share/unity3d/Unity/`

### 相关文件路径
- **容器内Unity安装**：`/opt/unity/Editor/`
- **构建脚本**：`漂浮大陆/Assets/Editor/BuildScript.cs`
- **场景文件**：`漂浮大陆/Assets/Scenes/`
- **输出目录**：`outputs/builds/PC/`

---
**最后更新**：2026年3月8日  
**适用版本**：Unity 2022.3.40f1c1  
**环境**：Linux容器（headless模式）