# AutoKeySwitch Makefile
# macOS 应用开发快捷命令

.PHONY: all generate build run clean clean-build open help

# 默认目标
all: generate build

# 生成 Xcode 项目
generate:
	@echo "📋 生成 Xcode 项目..."
	tuist generate --no-open

# 编译项目
build:
	@echo "🔨 编译项目..."
	xcodebuild -workspace AutoKeySwitch.xcworkspace \
		-scheme AutoKeySwitch \
		-configuration Debug \
		build \
		| tail -20

# 编译并运行
run: generate build open
	@echo "✅ 应用已启动"

# 打开应用
open:
	@echo "🚀 打开应用..."
	@APP_PATH=$$(find ~/Library/Developer/Xcode/DerivedData \
		-name "AutoKeySwitch.app" \
		-path "*/Debug/*" 2>/dev/null | head -1); \
	if [ -n "$$APP_PATH" ]; then \
		open "$$APP_PATH"; \
		echo "📌 应用路径: $$APP_PATH"; \
	else \
		echo "❌ 未找到编译后的应用，请先执行 make build"; \
	fi

# 清理构建缓存
clean:
	@echo "🧹 清理构建缓存..."
	tuist clean 2>/dev/null || true
	rm -rf ~/Library/Developer/Xcode/DerivedData/AutoKeySwitch-* 2>/dev/null || true
	rm -rf AutoKeySwitch.xcodeproj AutoKeySwitch.xcworkspace Derived 2>/dev/null || true
	@echo "✅ 清理完成"

# 完全清理后重新构建
clean-build: clean generate build
	@echo "✅ 重新构建完成"

# 帮助信息
help:
	@echo "AutoKeySwitch 开发命令"
	@echo ""
	@echo "使用方法: make [命令]"
	@echo ""
	@echo "可用命令:"
	@echo "  generate     生成 Xcode 项目"
	@echo "  build        编译项目"
	@echo "  run          编译并运行应用"
	@echo "  open         打开已编译的应用"
	@echo "  clean        清理构建缓存"
	@echo "  clean-build  完全清理后重新构建"
	@echo "  help         显示此帮助信息"
