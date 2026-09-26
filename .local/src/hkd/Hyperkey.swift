import AppKit

@main
final class App: NSObject, NSApplicationDelegate {
  static func main() {
    let app = NSApplication.shared
    let delegate = App()
    app.delegate = delegate
    app.run()
  }

  private var signalSources: [DispatchSourceSignal] = []
  private let capsLockRemapper = CapsLockRemapper()
  private let hyperkeyTap = HyperkeyTap(shortcuts: Config.hyperkeyShortcuts)

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.prohibited)

    signalSources = [SIGINT, SIGTERM].map { sig in
      signal(sig, SIG_IGN)

      let source = DispatchSource.makeSignalSource(
        signal: sig,
        queue: .main
      )
      source.setEventHandler { NSApp.terminate(nil) }
      source.resume()

      return source
    }

    let axKey: CFString = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
    let axOptions = [axKey: true] as CFDictionary

    guard AXIsProcessTrustedWithOptions(axOptions) else {
      Timer.scheduledTimer(
        withTimeInterval: 1,
        repeats: true
      ) { timer in
        guard AXIsProcessTrusted() else { return }

        timer.invalidate()

        self.start()
      }

      return
    }

    start()
  }

  func applicationWillTerminate(_ notification: Notification) {
    try? capsLockRemapper.reset()
  }

  private func start() {
    do {
      try capsLockRemapper.apply()
      try hyperkeyTap.start()
    } catch {
      fputs("Failed to start: \(error)\n", stderr)
      NSApp.terminate(nil)
    }
  }
}

struct HyperkeyShortcut {
  let keycode: Int
  let handle: (CGEventType, CGEvent) -> Unmanaged<CGEvent>?

  static func open(_ keycode: Int, app: String) -> HyperkeyShortcut {
    HyperkeyShortcut(keycode: keycode) { type, _ in
      if type == .keyDown {
        _ = try? Process.run(
          URL(filePath: "/usr/bin/open"),
          arguments: ["-a", app]
        )
      }

      return nil
    }
  }

  static func rewrite(_ keycode: Int, flags: CGEventFlags) -> HyperkeyShortcut {
    HyperkeyShortcut(keycode: keycode) { _, event in
      event.flags.insert(flags)

      return Unmanaged.passUnretained(event)
    }
  }
}

private struct CapsLockRemapper {
  private struct HIDUtilError: Error { let exitCode: Int32 }

  func apply() throws {
    try hidutil(
      encode([
        "UserKeyMapping": [
          [
            "HIDKeyboardModifierMappingSrc": 0x7_0000_0039,  // Caps Lock
            "HIDKeyboardModifierMappingDst": 0x7_0000_006D,  // F18
          ]
        ]
      ])
    )
  }

  func reset() throws {
    try hidutil(encode(["UserKeyMapping": []]))
  }

  private func encode(_ object: [String: [[String: Int]]]) throws -> String {
    return String(
      decoding: try JSONSerialization.data(withJSONObject: object),
      as: UTF8.self
    )
  }

  private func hidutil(_ json: String) throws {
    let task = try Process.run(
      URL(filePath: "/usr/bin/hidutil"),
      arguments: ["property", "--set", json]
    )
    task.waitUntilExit()
    guard task.terminationStatus == 0 else {
      throw HIDUtilError(exitCode: task.terminationStatus)
    }
  }
}

private final class HyperkeyTap {
  enum Error: Swift.Error {
    case tapCreationFailed
  }

  private let flags: CGEventFlags = [
    .maskControl,
    .maskAlternate,
    .maskShift,
    .maskCommand,
  ]

  private let f18Keycode = 0x4F
  private var isPressed = false
  private var port: CFMachPort?

  private let shortcuts: [Int64: HyperkeyShortcut]

  init(shortcuts: [HyperkeyShortcut]) {
    self.shortcuts = Dictionary(
      shortcuts.map { (Int64($0.keycode), $0) },
      uniquingKeysWith: { first, _ in first }
    )
  }

  func start() throws {
    let userInfo = Unmanaged.passUnretained(self).toOpaque()

    guard
      let tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: (1 << CGEventType.keyDown.rawValue)
          | (1 << CGEventType.keyUp.rawValue),
        callback: HyperkeyTap.eventTapCallback,
        userInfo: userInfo
      )
    else {
      throw Error.tapCreationFailed
    }

    self.port = tap

    CFRunLoopAddSource(
      CFRunLoopGetCurrent(),
      CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0),
      .commonModes
    )
  }

  private static let eventTapCallback: CGEventTapCallBack = {
    _,
    type,
    event,
    userInfo in
    guard let userInfo else { return Unmanaged.passUnretained(event) }

    return Unmanaged<HyperkeyTap>.fromOpaque(userInfo)
      .takeUnretainedValue()
      .handle(type: type, event: event)
  }

  private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      port.map { CGEvent.tapEnable(tap: $0, enable: true) }

      return Unmanaged.passUnretained(event)
    }

    let keycode = event.getIntegerValueField(.keyboardEventKeycode)

    if keycode == f18Keycode {
      isPressed = (type == .keyDown)

      return nil
    }

    guard isPressed, type == .keyDown || type == .keyUp else {
      return Unmanaged.passUnretained(event)
    }

    if let shortcut = shortcuts[keycode] {
      return shortcut.handle(type, event)
    }

    event.flags.insert(flags)

    return Unmanaged.passUnretained(event)
  }
}
