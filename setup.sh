#!/bin/bash
# PortfolioX - iOS Project Setup Script
# This script helps you set up the Xcode project using XcodeGen

echo "PortfolioX - 项目初始化脚本"
echo "================================"
echo ""

# Check if XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "❌ 未找到 XcodeGen，正在安装..."
    brew install xcodegen || {
        echo "请手动安装 XcodeGen: brew install xcodegen"
        echo "或从 https://github.com/YonasKolb/XcodeGen 下载"
        exit 1
    }
fi

echo "✅ XcodeGen 已安装"

# Generate Xcode project
echo "正在生成 Xcode 项目..."
xcodegen generate --project .

if [ $? -eq 0 ]; then
    echo "✅ Xcode 项目生成成功!"
    echo ""
    echo "下一步:"
    echo "1. 打开 PortfolioX.xcodeproj"
    echo "2. 复制 Secrets.plist.template 为 Secrets.plist 并填入你的 Claude API Key"
    echo "3. 选择 iOS 16.0+ 模拟器运行"
    echo ""
    echo "注意: App Transport Security 已配置为允许 HTTP 请求（供新浪财经 API 使用）"
else
    echo "❌ 项目生成失败"
    exit 1
fi
