import AppKit
import Carbon
import Foundation
import os

/// 键位映射结构
struct KeyMapping: Sendable {
    let normal: String
    let shifted: String
}

/// 键盘布局映射器
/// 动态获取 ASCII 键盘布局的标点符号映射
@MainActor
enum KeyboardLayoutMapper {
    private static let logger = Logger(subsystem: "com.autokeyswitch", category: "KeyboardLayoutMapper")

    /// Fallback mappings for US keyboard layout (exposed for testing)
    static let fallbackMappings: [UInt16: KeyMapping] = [
        43: KeyMapping(normal: ",", shifted: "<"),
        47: KeyMapping(normal: ".", shifted: ">"),
        41: KeyMapping(normal: ";", shifted: ":"),
        39: KeyMapping(normal: "'", shifted: "\""),
        42: KeyMapping(normal: "\\", shifted: "|"),
        33: KeyMapping(normal: "[", shifted: "{"),
        30: KeyMapping(normal: "]", shifted: "}"),
        50: KeyMapping(normal: "`", shifted: "~"),
        20: KeyMapping(normal: "1", shifted: "!"),
        21: KeyMapping(normal: "2", shifted: "@"),
        22: KeyMapping(normal: "3", shifted: "#"),
        23: KeyMapping(normal: "4", shifted: "$"),
        24: KeyMapping(normal: "5", shifted: "%"),
        25: KeyMapping(normal: "6", shifted: "^"),
        26: KeyMapping(normal: "7", shifted: "&"),
        27: KeyMapping(normal: "8", shifted: "*"),
        28: KeyMapping(normal: "9", shifted: "("),
        29: KeyMapping(normal: "0", shifted: ")"),
    ]

    /// 缓存的键位映射
    private static var cachedMappings: [UInt16: KeyMapping] = [:]

    /// 需要映射的标点键位
    static let punctuationKeyCodes: [UInt16] = [
        43, 47, 41, 39, 42, 33, 30,  // 原有标点: , . ; ' \ [ ]
        50,                          // 反引号 `
        20, 21, 22, 23, 24, 25, 26, 27, 28, 29,  // 数字键 1-0
    ]

    // MARK: - Public API

    /// 获取所有标点键位的映射
    static func getMappings() -> [UInt16: KeyMapping] {
        if cachedMappings.isEmpty {
            buildMappings()
        }
        return cachedMappings
    }

    /// 获取指定键位的映射
    static func getMapping(forKeyCode keyCode: UInt16) -> KeyMapping? {
        return getMappings()[keyCode]
    }

    /// 强制重建映射缓存
    static func rebuildMappings() {
    cachedMappings.removeAll()
    buildMappings()
    }

	/// 键盘布局变更回调
	@MainActor static func onKeyboardLayoutChanged() {
		logger.info("Keyboard layout changed, rebuilding mappings")
		rebuildMappings()
	}

    // MARK: - Private Helpers

    /// 构建键位映射
    private static func buildMappings() {
        guard let layoutData = getASCIIKeyboardLayoutData() else {
            logger.error("Failed to get ASCII keyboard layout data")
            // 使用硬编码回退
            buildFallbackMappings()
            return
        }

        let dataPtr = CFDataGetBytePtr(layoutData)
        let keyboardType = LMGetKbdType()
        var newMappings: [UInt16: KeyMapping] = [:]

        guard let bytes = dataPtr else {
            buildFallbackMappings()
            return
        }

        for keyCode in punctuationKeyCodes {
            let normal = getKeyOutput(
                layoutData: bytes,
                layoutLength: CFDataGetLength(layoutData),
                keyCode: keyCode,
                shift: false,
                keyboardType: keyboardType
            )
            let shifted = getKeyOutput(
                layoutData: bytes,
                layoutLength: CFDataGetLength(layoutData),
                keyCode: keyCode,
                shift: true,
                keyboardType: keyboardType
            )

            if !normal.isEmpty {
                newMappings[keyCode] = KeyMapping(normal: normal, shifted: shifted)
                logger.debug("Key \(keyCode): normal='\(normal)', shifted='\(shifted)'")
            }
        }

        cachedMappings = newMappings
        logger.info("Built \(newMappings.count) key mappings from keyboard layout")
    }

    /// 硬编码回退映射（当无法获取键盘布局时使用）
    private static func buildFallbackMappings() {
        cachedMappings = fallbackMappings
        logger.info("Using fallback mappings")
    }

    /// 获取 ASCII 键盘布局数据
    private static func getASCIIKeyboardLayoutData() -> CFData? {
        // 获取所有输入源
        guard let inputSources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return nil
        }

        // 查找 ASCII 键盘布局（优先 U.S.）
        for source in inputSources {
            guard let typePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType),
                  let sourceType = Unmanaged<CFString>.fromOpaque(typePtr).takeUnretainedValue() as String? else {
                continue
            }

            // 检查是否为键盘布局类型
            guard sourceType == kTISTypeKeyboardLayout as String else {
                continue
            }

            // 检查语言是否为英语
            if let langPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages),
               let languages = Unmanaged<CFArray>.fromOpaque(langPtr).takeUnretainedValue() as? [String],
               languages.contains("en") || languages.contains("en-US") {
                // 获取布局数据
                if let dataPtr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) {
                    return Unmanaged<CFData>.fromOpaque(dataPtr).takeUnretainedValue()
                }
            }
        }

        // 如果没找到英语布局，尝试获取当前布局
        if let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
           let dataPtr = TISGetInputSourceProperty(currentSource, kTISPropertyUnicodeKeyLayoutData) {
            return Unmanaged<CFData>.fromOpaque(dataPtr).takeUnretainedValue()
        }

        return nil
    }

    /// 查询键位输出
    private static func getKeyOutput(
        layoutData: UnsafePointer<UInt8>,
        layoutLength: CFIndex,
        keyCode: UInt16,
        shift: Bool,
        keyboardType: UInt8
    ) -> String {
        var deadKeyState: UInt32 = 0
        var chars: [UniChar] = [0, 0, 0, 0]
        var length: CFIndex = 0

        // Shift modifier: NX_SHIFTKEYMASK = 2, or use shiftKeyBit (0x02)
        let modifierFlags: UInt32 = shift ? 0x02 : 0

        // UCKeyTranslate expects UnsafePointer<UCKeyboardLayout>
        let keyboardLayout = layoutData.withMemoryRebound(to: UCKeyboardLayout.self, capacity: 1) { $0 }

        let status = UCKeyTranslate(
            keyboardLayout,
            keyCode,
            UInt16(kUCKeyActionDisplay),
            modifierFlags,
            UInt32(keyboardType),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            4,
            &length,
            &chars
        )

        guard status == noErr, length > 0 else {
            return ""
        }

        return String(utf16CodeUnits: chars, count: Int(length))
    }
}
