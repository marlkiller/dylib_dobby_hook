import Foundation
/*
 编译为 Universal 2 Binary：

 swiftc -target arm64-apple-macos12 -o auto_hack_arm64 auto_hack.swift
 swiftc -target x86_64-apple-macos10.12 -o auto_hack_x86_64 auto_hack.swift
 lipo -create -output auto_hack auto_hack_arm64 auto_hack_x86_64
 rm auto_hack_arm64 auto_hack_x86_64
 lipo -info auto_hack
*/

// MARK: - ANSI Color
let RESET = "\u{001B}[0m"
let GREEN = "\u{001B}[32m"
let YELLOW = "\u{001B}[33m"
let RED = "\u{001B}[31m"
let CYAN = "\u{001B}[36m"
let MAGENTA = "\u{001B}[35m"
let GRAY = "\u{001B}[90m"

// MARK: - Default Params
let DEFAULT_INJECT_PARAM = "--inplace --weak --all-yes --no-strip-codesig"
let DEFAULT_RE_SIGN_PARAM = "-f -s - --all-architectures --deep"
let DEFAULT_INJECT_TYPE = "static"
let DEFAULT_DYLIB_NAME = "libdylib_dobby_hook.dylib"

// MARK: - Path Setup
let currentDir = FileManager.default.currentDirectoryPath
let appsSchemaPath = "\(currentDir)/apps.schema.json"
let insertDylib = "\(currentDir)/../tools/insert_dylib"
let macPatchHelper = "\(currentDir)/../tools/mac_patch_helper"
let releaseDylib = "\(currentDir)/../release/mac/libdylib_dobby_hook.dylib"

// MARK: - Logging
func timestamp() -> String {
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return df.string(from: Date())
}
func logInfo(_ msg: String) { print("\(GREEN)🟢 [\(timestamp())] [INFO] \(msg)\(RESET)") }
func logWarning(_ msg: String) { print("\(YELLOW)🟡 [\(timestamp())] [WARN] \(msg)\(RESET)") }
func logError(_ msg: String) { print("\(RED)🔴 [\(timestamp())] [ERROR] \(msg)\(RESET)") }
func logPlain(_ msg: String) { print(msg) }
func logCommand(_ cmd: String) { logPlain("➜ \(cmd)") }
func logSeparator(_ appName: String? = nil) {
    let width = Int(
        Double(ProcessInfo.processInfo.environment["COLUMNS"].flatMap { Int($0) } ?? 80) * 0.96)
    if let appName = appName {
        let title = " 📦 Processing App: \(appName) "
        let sep = String(repeating: "=", count: max(0, (width - title.count) / 2))
        print("\(MAGENTA)\(sep)\(title)\(sep)\(RESET)")
    } else {
        print("\(GRAY)\(String(repeating: "=", count: width))\(RESET)")
    }
}

// MARK: - JSON Merge
func loadAndMergeAppsJson(from directory: String) -> [String: Any]? {
    var merged: [String: Any] = ["apps": []]
    let fm = FileManager.default
    guard
        let files = try? fm.contentsOfDirectory(atPath: directory).filter({
            $0.hasSuffix("apps.json")
        })
    else {
        logError("无法读取目录 \(directory)")
        return nil
    }
    if files.isEmpty {
        logError("No *apps.json files found in the [\(directory)]!")
        return nil
    }
    for file in files {
        let path = "\(directory)/\(file)"
        logInfo("Loading JSON file: \(path)")
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let apps = json["apps"] as? [[String: Any]]
        else {
            logWarning("File \(file) does not contain a valid 'apps' list.")
            continue
        }
        if merged["apps"] == nil { merged["apps"] = [[String: Any]]() }
        var arr = merged["apps"] as! [[String: Any]]
        arr.append(contentsOf: apps)
        merged["apps"] = arr
    }
    logInfo("Merged \(files.count) JSON files.")
    return merged
}

// MARK: - Variable Resolve
func resolveVariables(data: Any, context: [String: Any] = [:]) -> Any {
    // 跟踪是否在当前传递中进行了任何解析
    var changedInPass = false
    // 最大循环次数以防止无限循环
    let maxPasses = 10
    var currentData = data  // 可变副本用于在循环中修改

    for _ in 0..<maxPasses {
        changedInPass = false
        let oldData = try? JSONSerialization.data(withJSONObject: currentData, options: [])

        // 执行一次解析传递
        let resolved = performSinglePassResolution(
            data: currentData, context: context, changedInPass: &changedInPass)
        currentData = resolved

        // 检查当前传递是否改变了数据
        let newData = try? JSONSerialization.data(withJSONObject: currentData, options: [])
        if oldData == newData && !changedInPass {  // 如果没有数据变化，并且也没有变量被替换，则表示没有更多可解析的了
            break
        }
    }
    return currentData
}

// 单次解析传递的辅助函数
private func performSinglePassResolution(
    data: Any, context: [String: Any], changedInPass: inout Bool
) -> Any {
    if let dict = data as? [String: Any] {
        var result = [String: Any]()
        var localContext = context  // 对于当前字典，从传入的上下文开始

        // 在进行本轮解析时，将已解析的值添加到 localContext 中
        for (key, value) in dict {
            // 递归解析当前值，传入当前的 localContext
            let resolvedValue = performSinglePassResolution(
                data: value, context: localContext, changedInPass: &changedInPass)

            // 检查值是否真正改变，以更新 changedInPass 标志
            if let strValue = value as? String, let resolvedStrValue = resolvedValue as? String,
                strValue != resolvedStrValue
            {
                changedInPass = true
            } else if let dictValue = value as? [String: Any],
                let resolvedDictValue = resolvedValue as? [String: Any],
                NSDictionary(dictionary: dictValue) != NSDictionary(dictionary: resolvedDictValue)
            {
                changedInPass = true
            } else if let arrValue = value as? [Any],
                let resolvedArrValue = resolvedValue as? [Any],
                NSArray(array: arrValue) != NSArray(array: resolvedArrValue)
            {
                changedInPass = true
            }

            result[key] = resolvedValue  // 存储解析后的值

            // 如果解析后的值是基本类型（字符串、数字、布尔值），则将其添加到 localContext
            // 这样，同一个字典中后面的键就可以引用前面定义的变量
            if let strVal = resolvedValue as? String {
                localContext[key] = strVal
            } else if let intVal = resolvedValue as? Int {
                localContext[key] = intVal
            } else if let doubleVal = resolvedValue as? Double {
                localContext[key] = doubleVal
            } else if let boolVal = resolvedValue as? Bool {
                localContext[key] = boolVal
            }
        }
        return result
    } else if let arr = data as? [Any] {
        // 对于数组，每个元素都使用传入给数组的相同上下文进行解析
        return arr.map {
            performSinglePassResolution(data: $0, context: context, changedInPass: &changedInPass)
        }
    } else if let str = data as? String {
        var result = str
        // 使用 try! 是因为模式是硬编码的，确保它始终有效
        let regex = try! NSRegularExpression(pattern: "\\$(\\w+)")
        let nsstr = str as NSString

        // 反向遍历匹配项，以避免在替换过程中因字符串长度变化导致的范围问题
        let matches = regex.matches(in: str, range: NSRange(location: 0, length: nsstr.length))
            .reversed()

        for m in matches {
            let varName = nsstr.substring(with: m.range(at: 1))
            // 从传入的上下文中查找变量的值
            if let val = context[varName] {
                let originalResult = result  // 保存原始结果以便比较
                result = (result as NSString).replacingCharacters(in: m.range, with: "\(val)")
                if originalResult != result {  // 如果发生了替换，则标记为已改变
                    changedInPass = true
                }
            }
        }
        return result
    }
    return data
}

// MARK: - Command Execution
@discardableResult
func runCmdOrRaise(_ cmd: String, cwd: String? = nil, printOutput: Bool = true) -> String {
    logCommand(cmd)
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", cmd]
    if let cwd = cwd { task.currentDirectoryPath = cwd }
    let outPipe = Pipe(), errPipe = Pipe()
    task.standardOutput = outPipe
    task.standardError = errPipe
    task.launch()
    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    let outStr = String(data: outData, encoding: .utf8) ?? ""
    let errStr = String(data: errData, encoding: .utf8) ?? ""
    if printOutput {
        if !outStr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            logPlain("🗒️ Standard Output:\n\(outStr)")
        }
        if !errStr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            logPlain("⚠️ Standard Error:\n\(errStr)")
        }
    }
    if task.terminationStatus != 0 {
        logError("Command failed: \(cmd)")
        logError("Exit code: \(task.terminationStatus)")
        logError("Error output: \(errStr)")
        exit(1)
    }
    return outStr
}

@discardableResult
func runCmdIgnoreError(_ cmd: String, cwd: String? = nil) -> String? {
    logCommand(cmd)
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", cmd]
    if let cwd = cwd { task.currentDirectoryPath = cwd }
    let outPipe = Pipe(), errPipe = Pipe()
    task.standardOutput = outPipe
    task.standardError = errPipe
    task.launch()
    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    let outStr = String(data: outData, encoding: .utf8) ?? ""
    let errStr = String(data: errData, encoding: .utf8) ?? ""
    if !outStr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        logPlain("🗒️ Standard Output:\n\(outStr)")
    }
    if !errStr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        logPlain("⚠️ Standard Error:\n\(errStr)")
    }
    return task.terminationStatus == 0 ? outStr : nil
}

@discardableResult
func runCmdIgnoreOutput(_ cmd: String, cwd: String? = nil) -> String? {
    logCommand(cmd)

    let process = Process()
    process.launchPath = "/bin/bash"
    process.arguments = ["-c", cmd]

    if let cwd = cwd { process.currentDirectoryPath = cwd }


    let outPipe = Pipe()
    let errPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errPipe

    do {
        if #available(macOS 10.13, *) {
            try process.run()
        } else {
            process.launch()  // Fallback for macOS 10.12 and earlier
        }

        process.waitUntilExit()

        let outputData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errPipe.fileHandleForReading.readDataToEndOfFile()

        let output =
            String(data: outputData, encoding: .utf8)?.trimmingCharacters(
                in: .whitespacesAndNewlines) ?? ""
        let errorOutput =
            String(data: errorData, encoding: .utf8)?.trimmingCharacters(
                in: .whitespacesAndNewlines) ?? ""

        if process.terminationStatus == 0 {
            return output
        } else {
            logWarning("Command failed: \(cmd)")
            logWarning("Exit code: \(process.terminationStatus)")
            if !errorOutput.isEmpty {
                logWarning("Error output: \(errorOutput)")
            }
            return nil
        }
    } catch {
        logWarning("Failed to run command: \(cmd)")
        logWarning("Error: \(error.localizedDescription)")
        return nil
    }
}

@discardableResult
func runCmdSilent(_ cmd: String, cwd: String? = nil) -> String? {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", cmd]
    if let cwd = cwd { task.currentDirectoryPath = cwd }
    let outPipe = Pipe(), errPipe = Pipe()
    task.standardOutput = outPipe
    task.standardError = errPipe
    task.launch()
    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    if task.terminationStatus != 0 {
        let errStr = String(data: errData, encoding: .utf8) ?? ""
        logWarning("Command failed: \(cmd)")
        logWarning("Exit code: \(task.terminationStatus)")
        logWarning("Error output: \(errStr)")
        return nil
    }
    return String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Entitlements
func exportEntitlements(targetBin: String, entitlementsPath: String?) -> String {
    if let path = entitlementsPath, !path.isEmpty {
        logInfo("Using provided entitlements file: \(path)")
        return path
    }
    let temp = "\(NSTemporaryDirectory())entitlements-\(UUID().uuidString).plist"
    logInfo("Exporting entitlements to temporary file: \(temp)")
    runCmdIgnoreError("sudo codesign -d --entitlements - --xml '\(targetBin)' > '\(temp)'")
    return temp
}

// MARK: - Patch Helper
func callMacPatchHelper(fixHelper: Bool, binPath: String, patches: Any?) {
    let payload: [String: Any] = [
        "fix_helper": fixHelper,
        "target_bin_path": binPath,
        "patches": patches ?? [:],
    ]
    let jsonData = try! JSONSerialization.data(withJSONObject: payload)
    let base64 = jsonData.base64EncodedString()
    let patchCmd = "\(macPatchHelper) --base64 '\(base64)'"
    runCmdOrRaise(patchCmd)
}

// MARK: - Codesign
func reCodesign(
    targetBin: String, reSignParam: String, reSignEntitlements: Bool,
    reSignEntitlementsPath: String?
) {
    let reSignCmd: String
    if let ent = reSignEntitlementsPath, !ent.isEmpty {
        reSignCmd = "sudo codesign \(reSignParam) --entitlements '\(ent)' '\(targetBin)'"
    } else {
        reSignCmd = "sudo codesign \(reSignParam) '\(targetBin)'"
    }
    logInfo("Re-signing: \(targetBin)")
    runCmdIgnoreError(reSignCmd)
    logInfo("Checking signature after re-signing for: \(targetBin)")
    runCmdIgnoreError("sudo codesign -d -vvv --entitlements - '\(targetBin)'")
    runCmdIgnoreError("sudo codesign --verify --verbose=1 '\(targetBin)'")
}

// MARK: - Remove Quarantine
func removeQuarantineAttribute(targetBin: String) {
    logInfo("Removing quarantine attribute for: \(targetBin)")
    runCmdIgnoreOutput("sudo /usr/bin/xattr -r -d com.apple.quarantine '\(targetBin)'")
}

// MARK: - Dylib Check
func checkDylibExist(targetBin: String, dylibName: String) -> Bool {
    logInfo("Checking if \(dylibName) is already injected into: \(targetBin)")
    guard let result = runCmdIgnoreOutput("otool -L '\(targetBin)'") else { return false }
    if result.contains(dylibName) {
        logWarning("\(dylibName) is already injected into: \(targetBin)")
        return true
    }
    return false
}

// MARK: - Service
func processService(service: [String: Any], appContext: [String: Any]) {
    let appPath = appContext["app_path"] as? String ?? ""
    let appFrameworkPath = appContext["app_framework_path"] as? String ?? ""
    let serviceName = service["service_name"] as? String ?? ""
    let dylibName = appContext["dylib_name"] as? String ?? DEFAULT_DYLIB_NAME
    let serviceIdentity = service["service_identity"] as? String ?? serviceName
    let fixPrivilegedExecutables = service["fix_privileged_executables"] as? Bool ?? true
    let smPrivilegedExecutables = service["sm_privileged_executables"] as? String ?? serviceIdentity
    let reSignFlag = appContext["re_sign"] as? Bool ?? true
    let serviceBinPath = service["service_bin_path"] as? String ?? ""
    let injectService = service["inject_service"] as? Bool ?? false
    let fixHelper = service["fix_helper"] as? Bool ?? true
    let patches = service["patches"]
    let reSignParam = service["re_sign_param"] as? String ?? DEFAULT_RE_SIGN_PARAM
    let reSignEntitlements = service["re_sign_entitlements"] as? Bool ?? false
    var reSignEntitlementsPath = service["re_sign_entitlements_path"] as? String
    logInfo("Processing service: \(serviceName)")

    var tempEntitlementsPath: String? = nil
    if reSignFlag && reSignEntitlements {
        tempEntitlementsPath = exportEntitlements(
            targetBin: serviceBinPath, entitlementsPath: reSignEntitlementsPath)
        reSignEntitlementsPath = tempEntitlementsPath
    }

    logInfo("🔄 Killing processes related to service: \(serviceName)")
    runCmdIgnoreOutput("sudo pkill -f '/\(serviceName)'")

    logInfo("🔄 Removing old \(serviceName) files...")
    runCmdIgnoreOutput("sudo launchctl unload '/Library/LaunchDaemons/\(serviceName).plist'")
    runCmdIgnoreOutput("sudo /usr/bin/killall -u root -9 '\(serviceName)'")
    runCmdIgnoreOutput("sudo /bin/rm '/Library/LaunchDaemons/\(serviceName).plist'")
    runCmdIgnoreOutput("sudo /bin/rm '/Library/PrivilegedHelperTools/\(serviceName)'")

    if injectService {
        logInfo("Injecting dylib into service binary (static): \(serviceBinPath)")
        logInfo("Checking signature before re-signing for: \(serviceBinPath)")
        runCmdIgnoreError("sudo codesign -d -vvv --entitlements - '\(serviceBinPath)'")

        if !checkDylibExist(targetBin: serviceBinPath, dylibName: dylibName) {
            let injectParam = service["inject_param"] as? String ?? DEFAULT_INJECT_PARAM
            runCmdOrRaise(
                "sudo \(insertDylib) \(injectParam) '\(appFrameworkPath)/\(dylibName)' '\(serviceBinPath)'"
            )
        }
    }

    if fixHelper || patches != nil {
        logInfo("Fixing helper or applying patches for service: \(serviceName)")
        callMacPatchHelper(fixHelper: fixHelper, binPath: serviceBinPath, patches: patches)
    }

    if reSignFlag {
        if fixPrivilegedExecutables {
            logInfo("🔧 Modifying Info.plist for \(serviceIdentity)...")
            let identifierName = "identifier \\\"\(serviceIdentity)\\\""
            let requirementsName = identifierName
            let plistPath = "\(appPath)/Contents/Info.plist"

            runCmdOrRaise(
                "sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' '\(plistPath)'")
            runCmdIgnoreOutput(
                "sudo /usr/libexec/PlistBuddy -c 'Set :SMPrivilegedExecutables:\(smPrivilegedExecutables) \"\(requirementsName)\"' '\(plistPath)'"
            )
            runCmdOrRaise(
                "sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' '\(plistPath)'")
        }

        logInfo("Re-signing service: \(serviceName)")
        reCodesign(
            targetBin: serviceBinPath, reSignParam: reSignParam,
            reSignEntitlements: reSignEntitlements, reSignEntitlementsPath: reSignEntitlementsPath)

        if let temp = tempEntitlementsPath {
            logInfo("Removing temporary entitlements file: \(temp)")
            try? FileManager.default.removeItem(atPath: temp)
        }
    }

    removeQuarantineAttribute(targetBin: serviceBinPath)
}

// MARK: - Static Injection
func handleStaticInjection(appName: String, appBinPath: String, app: [String: Any]) {
    let injectParam = app["inject_param"] as? String ?? DEFAULT_INJECT_PARAM
    let injectPath = app["inject_path"] as? String ?? appBinPath
    let dylibName = app["dylib_name"] as? String ?? DEFAULT_DYLIB_NAME
    let dylibPath = app["dylib_path"] as? String ?? "@rpath/\(dylibName)"

    logInfo("Injecting dylib into app binary (static): \(injectPath)")
    logInfo("Checking signature before re-signing for: \(app["app_path"] ?? "")")
    runCmdIgnoreError("sudo codesign -d -vvv --entitlements - '\(app["app_path"] ?? "")'")

    if !checkDylibExist(targetBin: injectPath, dylibName: dylibName) {
        runCmdOrRaise("sudo \(insertDylib) \(injectParam) '\(dylibPath)' '\(injectPath)'")
    }

    if let services = app["services"] as? [[String: Any]] {
        for service in services {
            processService(service: service, appContext: app)
        }
    }
}

// MARK: - Main App Processing
func processApp(app: [String: Any]) {
    let appName = app["app_name"] as? String ?? ""
    let appPath = app["app_path"] as? String ?? ""
    let appBinPath = app["app_bin_path"] as? String ?? ""
    let reSignFlag = app["re_sign"] as? Bool ?? true
    let injectType = app["inject_type"] as? String ?? DEFAULT_INJECT_TYPE
    var app = app
    app["app_framework_path"] = "\(appPath)/Contents/Frameworks"
    let dylibName = app["dylib_name"] as? String ?? DEFAULT_DYLIB_NAME

    logSeparator(appName)

    if !FileManager.default.fileExists(atPath: appPath) {
        logWarning("❌ [\(appName)] not found at path: \(appPath). Skipping...")
        return
    }

    let version =
        runCmdSilent("defaults read '\(appPath)/Contents/Info.plist' CFBundleShortVersionString")
        ?? "Unknown"
    let bundleId =
        runCmdSilent("defaults read '\(appPath)/Contents/Info.plist' CFBundleIdentifier")
        ?? "Unknown"

    print(
        "✅ \(GREEN)[\(appName) \(version) \(RED)(\(bundleId))\(RESET)\(GREEN)] exists. Wanna inject? (Y/N): \(RESET)",
        terminator: "")

    guard let userInput = readLine(), userInput.lowercased() == "y" else {
        logInfo("😒 [\(appName)] skipped on user demand.")
        return
    }

    logInfo("Starting processing for app: \(appName)\r\n\(app)")

    let appReSignParam = app["re_sign_param"] as? String ?? DEFAULT_RE_SIGN_PARAM
    let appReSignEntitlements = app["re_sign_entitlements"] as? Bool ?? false
    var appReSignEntitlementsPath = app["re_sign_entitlements_path"] as? String
    var appTempEntitlementsPath: String? = nil

    if reSignFlag && appReSignEntitlements {
        appTempEntitlementsPath = exportEntitlements(
            targetBin: appPath, entitlementsPath: appReSignEntitlementsPath)
        appReSignEntitlementsPath = appTempEntitlementsPath
    }

    if let preScript = app["pre_script"] as? String, !preScript.isEmpty {
        logInfo("Running pre_script for app: \(appName)")
        runCmdOrRaise(preScript)
    }

    if let otherPatches = app["other_patches"] as? [String: Any] {
        logInfo("Applying other patches for app: \(appName)")
        for (path, patch) in otherPatches {
            callMacPatchHelper(fixHelper: false, binPath: path, patches: patch)
        }
    }

    if injectType != "none" {
        let appBundleFramework = "\(appPath)/Contents/Frameworks"
        try? FileManager.default.createDirectory(
            atPath: appBundleFramework, withIntermediateDirectories: true)
        logInfo("Copying dylib to: \(appBundleFramework)")
        runCmdIgnoreOutput("sudo cp -f '\(releaseDylib)' '\(appBundleFramework)/\(dylibName)'")
    }

    if injectType == "static" {
        logWarning(
            "⚠️ Static injection is irreversible. Please back up your application at: \(appPath)")
        logWarning("Press any key to continue...")
        _ = readLine()
        handleStaticInjection(appName: appName, appBinPath: appBinPath, app: app)
    } else if injectType == "dynamic" {
        logInfo("Dynamic injection selected for app: \(appName)")
    } else if injectType == "process" {
        logInfo("Process-based injection selected for app: \(appName)")
    } else {
        logWarning("Ignore inject_type '\(injectType)' for app: \(appName)")
    }

    if reSignFlag {
        logInfo("Re-signing app: \(appName)")
        reCodesign(
            targetBin: appPath, reSignParam: appReSignParam,
            reSignEntitlements: appReSignEntitlements,
            reSignEntitlementsPath: appReSignEntitlementsPath)

        if let temp = appTempEntitlementsPath {
            logInfo("Removing temporary entitlements file: \(temp)")
            try? FileManager.default.removeItem(atPath: temp)
        }
    }

    removeQuarantineAttribute(targetBin: appPath)

    if let postScript = app["post_script"] as? String, !postScript.isEmpty {
        logInfo("Running post_script for app: \(appName)")
        runCmdOrRaise(postScript)
    }

    logInfo("Finished processing for app: \(appName)")
    logSeparator()
}

// MARK: - Main
func main() {
    guard let mergedApps = loadAndMergeAppsJson(from: currentDir) else {
        logError("Failed to load and merge apps JSON.")
        exit(1)
    }
    guard let apps = mergedApps["apps"] as? [[String: Any]] else {
        logError("No apps found in merged JSON.")
        exit(1)
    }

    for appRaw in apps {
        let resolvedApp = resolveVariables(data: appRaw) as! [String: Any]  // 每次都以空上下文开始解析 appRaw
        processApp(app: resolvedApp)
    }
}

// 初始化并运行
func initHack() {
    if !FileManager.default.fileExists(atPath: releaseDylib) {
        logError("Required file not found: \(releaseDylib)")
        logError(
            "Please navigate to the project root directory and run 'bash build.sh' to compile the required files."
        )
        exit(1)
    }

    logInfo("Setting permissions for: \(insertDylib)")
    runCmdIgnoreOutput("chmod +x '\(insertDylib)'")
    runCmdIgnoreOutput("/usr/bin/xattr -cr '\(insertDylib)'")

    logInfo("Setting permissions for: \(macPatchHelper)")
    runCmdIgnoreOutput("chmod +x '\(macPatchHelper)'")
    runCmdIgnoreOutput("/usr/bin/xattr -cr '\(macPatchHelper)'")
}

// 启动
initHack()
main()