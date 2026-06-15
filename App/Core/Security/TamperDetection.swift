import Foundation
import Darwin
import MachO

enum TamperDetection {

    /// Returns true if the runtime environment looks compromised.
    /// Checks are additive — no single heuristic is bypassed in isolation.
    ///
    /// Disabled entirely in DEBUG and simulator builds: the debugger check
    /// would otherwise trip on every Xcode run, and the heuristics are
    /// meaningless outside a real device running a release build.
    ///
    /// Does synchronous file-system probes — call from a background task,
    /// never from the main thread.
    static func isCompromised() -> Bool {
        #if DEBUG || targetEnvironment(simulator)
        return false
        #else
        return isJailbroken() || isDebugged() || hasSuspiciousDylibs()
        #endif
    }

    // MARK: - Jailbreak heuristics

    private static func isJailbroken() -> Bool {
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/usr/sbin/sshd",
            "/bin/bash",
            "/usr/bin/ssh",
            "/etc/apt",
            "/private/var/lib/apt",
            "/private/var/lib/cydia",
            "/var/checkra1n.dmg"
        ]
        if suspiciousPaths.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
            return true
        }

        // Try writing outside the app sandbox — jailbroken devices allow this
        let testPath = "/private/jb_probe_\(UUID().uuidString)"
        do {
            try "x".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {}

        return false
    }

    // MARK: - Debugger detection

    private static func isDebugged() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        sysctl(&mib, 4, &info, &size, nil, 0)
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    // MARK: - Suspicious dylib injection detection

    private static func hasSuspiciousDylibs() -> Bool {
        let blocklist = ["FridaGadget", "frida", "libcycript", "SSLKillSwitch",
                         "substitute", "libhooker", "TweakInject"]
        for i in 0..<_dyld_image_count() {
            guard let namePtr = _dyld_get_image_name(i) else { continue }
            let name = String(cString: namePtr).lowercased()
            if blocklist.contains(where: { name.contains($0.lowercased()) }) {
                return true
            }
        }
        return false
    }
}
