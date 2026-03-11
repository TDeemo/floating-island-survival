#!/bin/bash
# Unity 原型构建脚本
# 如果Unity不在PATH中，请设置UNITY_PATH环境变量

set -e

PROJECT_PATH="/app/data/files/漂浮大陆"
OUTPUT_PATH="/app/data/files/outputs/builds/prototype_v1"
SCENE_PATH="Assets/Scenes/PrototypeTest.unity"

echo "=== 开始构建漂浮大陆原型 ==="
echo "项目路径: $PROJECT_PATH"
echo "输出路径: $OUTPUT_PATH"
echo "场景: $SCENE_PATH"

# 检查场景文件是否存在
if [ ! -f "$PROJECT_PATH/$SCENE_PATH" ]; then
    echo "错误: 场景文件不存在: $SCENE_PATH"
    echo "请确保 PrototypeTest.unity 已创建"
    exit 1
fi

# 确定Unity可执行文件路径
if [ -n "$UNITY_PATH" ]; then
    UNITY_EXE="$UNITY_PATH"
    echo "使用自定义Unity路径: $UNITY_EXE"
elif command -v unity &> /dev/null; then
    UNITY_EXE="unity"
    echo "使用PATH中的Unity"
elif [ -f "/Applications/Unity/Hub/Editor/2022.3.34f1/Unity.app/Contents/MacOS/Unity" ]; then
    UNITY_EXE="/Applications/Unity/Hub/Editor/2022.3.34f1/Unity.app/Contents/MacOS/Unity"
    echo "使用默认macOS Unity路径"
elif [ -f "/opt/unity/Editor/Unity" ]; then
    UNITY_EXE="/opt/unity/Editor/Unity"
    echo "使用默认Linux Unity路径"
else
    echo "错误: 未找到Unity可执行文件"
    echo "请执行以下操作之一:"
    echo "1. 将Unity添加到PATH"
    echo "2. 设置UNITY_PATH环境变量"
    echo "3. 在标准位置安装Unity"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_PATH"

echo "=== 开始构建过程 ==="
# Unity批处理模式构建命令
# -batchmode: 批处理模式
# -quit: 构建完成后退出
# -logFile: 日志文件路径
# -projectPath: 项目路径
# -buildTarget: 构建目标 (StandaloneWindows64)
# -executeMethod: 自定义构建方法（如果可用）
# -scenePath: 要构建的场景

# 简单构建命令
echo "执行Unity构建..."
"$UNITY_EXE" -batchmode -quit -logFile "$OUTPUT_PATH/build.log" \
  -projectPath "$PROJECT_PATH" \
  -buildTarget StandaloneWindows64 \
  -scenePath "$SCENE_PATH" \
  -buildWindows64Player "$OUTPUT_PATH/Prototype.exe"

if [ $? -eq 0 ]; then
    echo "✅ 构建成功!"
    echo "构建输出: $OUTPUT_PATH"
    ls -la "$OUTPUT_PATH"
else
    echo "❌ 构建失败!"
    echo "查看日志: $OUTPUT_PATH/build.log"
    exit 1
fi