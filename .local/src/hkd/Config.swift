import Carbon

enum Config {
  static let hyperkeyShortcuts: [HyperkeyShortcut] = [
    .rewrite(kVK_ANSI_B, flags: .maskControl),
    .open(kVK_ANSI_T, app: "Terminal"),
    .open(kVK_ANSI_K, app: "Slack"),
    .open(kVK_ANSI_S, app: "Safari"),
    .open(kVK_ANSI_L, app: "Signal"),
    .open(kVK_ANSI_M, app: "Messages"),
    .open(kVK_ANSI_C, app: "Google Chrome"),
    .open(kVK_ANSI_F, app: "Finder"),
    .open(kVK_ANSI_G, app: "Firefox"),
    .open(kVK_ANSI_I, app: "IntelliJ IDEA"),
    .open(kVK_ANSI_V, app: "Visual Studio Code"),
    .open(kVK_ANSI_X, app: "Xcode"),
  ]
}
