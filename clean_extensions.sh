#!/bin/bash

# 定义原始扩展文件位置
VIEW_EXTENSIONS_DIR1="Views/Utils/Extensions"
VIEW_EXTENSIONS_DIR2="Views/Extensions"

# 定义目标目录
TARGET_DIR="Extensions"

# 确保以下目录存在
echo "确保目标目录存在..."
mkdir -p $TARGET_DIR/View
mkdir -p $TARGET_DIR/Foundation
mkdir -p $TARGET_DIR/Color
mkdir -p $TARGET_DIR/System

# 1. 检查旧的扩展文件目录是否存在
echo "检查旧扩展文件目录是否存在..."
if [ -d "$VIEW_EXTENSIONS_DIR1" ] || [ -d "$VIEW_EXTENSIONS_DIR2" ]; then
    echo "发现旧的扩展文件目录"
    
    # 创建备份目录
    BACKUP_DIR="Extensions_Backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p $BACKUP_DIR
    echo "创建备份目录: $BACKUP_DIR"
    
    # 2. 备份旧的扩展文件
    if [ -d "$VIEW_EXTENSIONS_DIR1" ]; then
        echo "备份 $VIEW_EXTENSIONS_DIR1 目录..."
        cp -r $VIEW_EXTENSIONS_DIR1 $BACKUP_DIR/
    fi
    
    if [ -d "$VIEW_EXTENSIONS_DIR2" ]; then
        echo "备份 $VIEW_EXTENSIONS_DIR2 目录..."
        cp -r $VIEW_EXTENSIONS_DIR2 $BACKUP_DIR/
    fi
    
    # 3. 检查是否需要从旧的扩展文件复制内容到新的扩展文件
    # 针对已迁移的扩展内容，此步骤不再需要

    # 4. 移除旧的扩展文件目录
    echo "移除旧的扩展文件目录..."
    if [ -d "$VIEW_EXTENSIONS_DIR1" ]; then
        rm -rf $VIEW_EXTENSIONS_DIR1
        echo "$VIEW_EXTENSIONS_DIR1 已移除"
    fi
    
    if [ -d "$VIEW_EXTENSIONS_DIR2" ]; then
        rm -rf $VIEW_EXTENSIONS_DIR2
        echo "$VIEW_EXTENSIONS_DIR2 已移除"
    fi
    
    echo "旧扩展目录已清理完成"
else
    echo "未发现旧的扩展文件目录，无需清理"
fi

# 5. 确保修改后的项目结构更新在Xcode中
echo "请在Xcode中重新导入Extensions目录下的所有文件，确保项目结构更新"
echo "1. 在Xcode中，右键点击项目导航器中的项目名称"
echo "2. 选择「Add Files to [项目名]...」"
echo "3. 选择并添加新创建的Extensions目录"
echo "4. 确保「Copy items if needed」选项未勾选，以避免重复文件"
echo "5. 点击「Add」完成导入"

echo "清理工作完成！"