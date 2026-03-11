#!/bin/bash
# Unity 编辑器路径配置脚本
# 用于配置Unity编辑器环境变量和符号链接

UNITY_INSTALL_DIR="/opt/unity/Editor"
SYMLINK_PATH="/usr/local/bin/unity"

# 检查Unity可执行文件是否存在
if [ ! -f "$UNITY_INSTALL_DIR/Unity" ]; then
    echo "错误: Unity可执行文件不存在于 $UNITY_INSTALL_DIR"
    echo "请确保Unity编辑器已正确安装到该目录"
    exit 1
fi

# 创建符号链接
echo "创建Unity符号链接到 $SYMLINK_PATH..."
ln -sf "$UNITY_INSTALL_DIR/Unity" "$SYMLINK_PATH"

if [ $? -eq 0 ]; then
    echo "✅ 符号链接创建成功"
else
    echo "❌ 符号链接创建失败 (可能需要sudo权限)"
fi

# 验证安装
echo "验证Unity版本..."
"$UNITY_INSTALL_DIR/Unity" -version 2>&1 | grep -E "^(Can't get home directory!)?.*[0-9]+\.[0-9]+\.[0-9]+"

# 添加环境变量建议
echo ""
echo "=== 环境变量配置建议 ==="
echo "如需在shell会话中直接使用unity命令，请将以下行添加到 ~/.bashrc 或 ~/.bash_profile:"
echo ""
echo "export PATH=\"$UNITY_INSTALL_DIR:\$PATH\""
echo ""
echo "或者直接使用已创建的符号链接:"
echo "unity -version"
echo ""
echo "=== 使用示例 ==="
echo "# 编译项目:"
echo "unity -batchmode -quit -projectPath ./漂浮大陆 -logFile unity_build.log"
echo ""
echo "# 执行构建方法:"
echo "unity -batchmode -quit -projectPath ./漂浮大陆 -executeMethod BuildScript.PerformBuild"